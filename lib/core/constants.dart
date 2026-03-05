// Constantes globais do app
class AppConstants {
  // Mercado Pago
  static const String mpBaseUrl = 'https://api.mercadopago.com';
  static const String mpPaymentsUrl = '$mpBaseUrl/v1/payments';
  static const String mpOrdersUrl = '$mpBaseUrl/merchant_orders';

  // Database
  static const String dbName = 'app_empada.db';
  static const int dbVersion = 2;

  // Tabelas
  static const String tableProducts = 'products';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';

  // Chaves de configurações
  static const String keyAccessToken = 'mp_access_token';
  static const String keyCompanyName = 'company_name';
  static const String keyCpf = 'owner_cpf';
  static const String keyCnpj = 'owner_cnpj'; // opcional / futuro
  static const String keyPublicKey = 'mp_public_key';
}
