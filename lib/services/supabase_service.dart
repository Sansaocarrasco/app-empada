import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

/// Sincroniza vendas aprovadas com o banco Supabase na nuvem.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Envia a venda aprovada e seus itens para o Supabase.
  Future<void> syncSale(Sale sale, List<SaleItem> items) async {
    // INSERT simples — cada venda tem UUID único, não há conflito
    await _client.from('sales').insert({
      'id': sale.id,
      'date': sale.date.toUtc().toIso8601String(),
      'total_amount': sale.totalAmount,
      'mercado_pago_id': sale.mercadoPagoId,
      'payer_name': sale.payerName,
      'payer_email': sale.payerEmail,
      'approved_at': sale.approvedAt?.toUtc().toIso8601String(),
    });

    if (items.isNotEmpty) {
      await _client.from('sale_items').insert(
        items
            .map((item) => {
                  'id': item.id,
                  'sale_id': item.saleId,
                  'product_name': item.productName,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                })
            .toList(),
      );
    }
  }
}
