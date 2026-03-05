import 'package:uuid/uuid.dart';

enum PaymentStatus { pending, approved, rejected, cancelled }

class Sale {
  final String id;
  final DateTime date;
  double totalAmount;
  PaymentStatus paymentStatus;
  final String? mercadoPagoId;
  final String? paymentMethod;
  // Dados do pagador (capturados do MP ao aprovar)
  final String? payerName;
  final String? payerEmail;
  final DateTime? approvedAt;

  Sale({
    String? id,
    DateTime? date,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.pending,
    this.mercadoPagoId,
    this.paymentMethod,
    this.payerName,
    this.payerEmail,
    this.approvedAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'payment_status': paymentStatus.name,
      'mercado_pago_id': mercadoPagoId,
      'payment_method': paymentMethod,
      'payer_name': payerName,
      'payer_email': payerEmail,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      mercadoPagoId: map['mercado_pago_id'] as String?,
      paymentMethod: map['payment_method'] as String?,
      payerName: map['payer_name'] as String?,
      payerEmail: map['payer_email'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
    );
  }

  Sale copyWith({
    PaymentStatus? paymentStatus,
    String? mercadoPagoId,
    String? payerName,
    String? payerEmail,
    DateTime? approvedAt,
  }) {
    return Sale(
      id: id,
      date: date,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      mercadoPagoId: mercadoPagoId ?? this.mercadoPagoId,
      paymentMethod: paymentMethod,
      payerName: payerName ?? this.payerName,
      payerEmail: payerEmail ?? this.payerEmail,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
