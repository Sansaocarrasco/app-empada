import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

/// Sincroniza vendas aprovadas com o banco Supabase na nuvem.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Envia (ou atualiza) uma venda aprovada e seus itens para o Supabase.
  /// Usa upsert para ser idempotente (seguro reenviar).
  Future<void> syncSale(Sale sale, List<SaleItem> items) async {
    await _client.from('sales').upsert({
      'id': sale.id,
      'date': sale.date.toUtc().toIso8601String(),
      'total_amount': sale.totalAmount,
      'mercado_pago_id': sale.mercadoPagoId,
      'payer_name': sale.payerName,
      'payer_email': sale.payerEmail,
      'approved_at': sale.approvedAt?.toUtc().toIso8601String(),
    });

    if (items.isNotEmpty) {
      await _client.from('sale_items').upsert(
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
