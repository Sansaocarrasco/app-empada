import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Produtos disponíveis (quantidade > 0)
  List<Product> get availableProducts =>
      _products.where((p) => p.quantity > 0).toList();

  /// Estimativa máxima do dia: soma de (preço × estoque) de todos os produtos
  double get maxDayEstimate =>
      _products.fold(0.0, (sum, p) => sum + (p.price * p.quantity));

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    await _repo.insert(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _repo.update(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.delete(id);
    await loadProducts();
  }
}
