import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/sale.dart';

/// Serviço de integração com a API do Mercado Pago.
/// Suporta autônomos (CPF) e futuramente empresas (CNPJ).
class MercadoPagoService {
  late Dio _dio;
  String _accessToken = '';

  MercadoPagoService();

  void configure(String accessToken) {
    _accessToken = accessToken;
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.mpBaseUrl,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  bool get isConfigured => _accessToken.isNotEmpty;

  /// Cria um pagamento PIX e retorna os dados do QR code.
  /// [amount] - Valor em reais
  /// [description] - Descrição da venda
  /// [payerCpf] - CPF do pagador (cliente)
  Future<Map<String, dynamic>> createPixPayment({
    required double amount,
    required String description,
    String? payerEmail,
  }) async {
    if (!isConfigured) throw Exception('Token do Mercado Pago não configurado.');

    final body = {
      'transaction_amount': amount,
      'description': description,
      'payment_method_id': 'pix',
      'payer': {
        'email': payerEmail ?? 'cliente@empada.com',
      },
    };

    final idempotencyKey = const Uuid().v4();

    try {
      final response = await _dio.post(
        '/v1/payments',
        data: body,
        options: Options(headers: {'X-Idempotency-Key': idempotencyKey}),
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'id': data['id'],
        'status': data['status'],
        'qr_code': data['point_of_interaction']?['transaction_data']?['qr_code'],
        'qr_code_base64': data['point_of_interaction']?['transaction_data']?['qr_code_base64'],
        'ticket_url': data['point_of_interaction']?['transaction_data']?['ticket_url'],
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Consulta o status de um pagamento pelo ID.
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    if (!isConfigured) throw Exception('Token do Mercado Pago não configurado.');

    try {
      final response = await _dio.get('/v1/payments/$paymentId');
      final status = response.data['status'] as String;
      return _mapStatus(status);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Busca detalhes completos de um pagamento aprovado.
  /// Retorna nome/email do pagador e data/hora da aprovação.
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    if (!isConfigured) return {};
    try {
      final response = await _dio.get('/v1/payments/$paymentId');
      final data = response.data as Map<String, dynamic>;
      final payer = data['payer'] as Map<String, dynamic>? ?? {};
      final firstName = payer['first_name'] as String? ?? '';
      final lastName = payer['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final approvedAtRaw = data['date_approved'] as String?;
      return {
        'payer_name': fullName.isNotEmpty ? fullName : null,
        'payer_email': payer['email'] as String?,
        'approved_at': approvedAtRaw != null ? DateTime.parse(approvedAtRaw) : DateTime.now(),
      };
    } catch (_) {
      // Falha silenciosa — dados do pagador são complementares
      return {'approved_at': DateTime.now()};
    }
  }

  PaymentStatus _mapStatus(String status) {
    switch (status) {
      case 'approved':
        return PaymentStatus.approved;
      case 'rejected':
        return PaymentStatus.rejected;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Timeout ao conectar ao Mercado Pago. Verifique sua internet.');
    }
    if (e.response != null) {
      final msg = e.response?.data?['message'] as String? ?? 'Erro desconhecido do Mercado Pago';
      // Erro de chave PIX não habilitada na conta
      if (msg.toLowerCase().contains('without key enabled') ||
          msg.toLowerCase().contains('qr render')) {
        return Exception(
          'PIX não habilitado na conta do Mercado Pago.\n\n'
          'Abra o app do Mercado Pago → Área PIX → Cadastre uma chave PIX e tente novamente.',
        );
      }
      return Exception('Erro MP: $msg');
    }
    return Exception('Erro de conexão: ${e.message}');
  }
}
