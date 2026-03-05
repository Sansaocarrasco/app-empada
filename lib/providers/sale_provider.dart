import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../repositories/sale_repository.dart';
import '../repositories/product_repository.dart';
import '../services/supabase_service.dart';
import '../services/mercado_pago_service.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => quantity * product.price;
}

class SaleProvider extends ChangeNotifier {
  final SaleRepository _saleRepo = SaleRepository();
  final ProductRepository _productRepo = ProductRepository();
  final SupabaseService _supabaseService = SupabaseService();

  // mpService é injetado pelo SettingsProvider via setter
  MercadoPagoService? _mpService;
  void setMpService(MercadoPagoService service) => _mpService = service;

  final List<CartItem> _cart = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get cartIsEmpty => _cart.isEmpty;

  double get cartTotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(Product product) {
    final existing = _cart.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      if (_cart[existing].quantity < product.quantity) {
        _cart[existing].quantity++;
      }
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void decrementCart(String productId) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (_cart[idx].quantity > 1) {
        _cart[idx].quantity--;
      } else {
        _cart.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Cria a venda como 'pending' no banco e retorna a Sale.
  Future<Sale> createPendingSale() async {
    final sale = Sale(totalAmount: cartTotal);
    final items = _cart
        .map((ci) => SaleItem(
              saleId: sale.id,
              productId: ci.product.id,
              productName: ci.product.name,
              quantity: ci.quantity,
              unitPrice: ci.product.price,
            ))
        .toList();

    await _saleRepo.insert(sale);
    await _saleRepo.insertItems(items);
    return sale;
  }

  /// Confirma a venda aprovada, decrementa estoque e sincroniza com Supabase.
  Future<void> approveSale(String saleId, String mpPaymentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Busca detalhes do pagador no Mercado Pago
      final details = _mpService != null
          ? await _mpService!.getPaymentDetails(mpPaymentId)
          : <String, dynamic>{};

      // 2. Atualiza status local (SQLite)
      await _saleRepo.updateStatus(
        saleId,
        PaymentStatus.approved,
        mpId: mpPaymentId,
      );

      // 3. Decrementa estoque
      for (final item in _cart) {
        await _productRepo.decrementStock(item.product.id, item.quantity);
      }

      // 4. Sincroniza com Supabase (falha silenciosa)
      try {
        final saleData = await _saleRepo.getById(saleId);
        if (saleData != null) {
          final approvedSale = saleData.copyWith(
            payerName: details['payer_name'] as String?,
            payerEmail: details['payer_email'] as String?,
            approvedAt: details['approved_at'] as DateTime?,
          );
          final items = await _saleRepo.getItemsBySale(saleId);
          await _supabaseService.syncSale(approvedSale, items);
        }
      } catch (e, stack) {
        debugPrint('⚠️ Supabase sync FALHOU: ${e.runtimeType}: $e');
        debugPrint(stack.toString());
      }

      clearCart();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancela/rejeita a venda.
  Future<void> cancelSale(String saleId) async {
    await _saleRepo.updateStatus(saleId, PaymentStatus.cancelled);
    clearCart();
    notifyListeners();
  }
}
