class AppSettings {
  final String companyName;
  final String? cpf;          // Pessoa física (autônomo)
  final String? cnpj;         // Opcional — futuro crescimento
  final String mpAccessToken; // Token do Mercado Pago
  final String mpPublicKey;   // Chave pública do Mercado Pago

  const AppSettings({
    this.companyName = 'Minha Empada',
    this.cpf,
    this.cnpj,    // CNPJ é opcional; preenchido no futuro quando formalizar
    this.mpAccessToken = '',
    this.mpPublicKey = '',
  });

  AppSettings copyWith({
    String? companyName,
    String? cpf,
    String? cnpj,
    String? mpAccessToken,
    String? mpPublicKey,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      cpf: cpf ?? this.cpf,
      cnpj: cnpj ?? this.cnpj,
      mpAccessToken: mpAccessToken ?? this.mpAccessToken,
      mpPublicKey: mpPublicKey ?? this.mpPublicKey,
    );
  }

  bool get isConfigured => mpAccessToken.isNotEmpty;

  /// Identificador fiscal do empreendedor (CPF por padrão; CNPJ se disponível)
  String get fiscalId => cnpj?.isNotEmpty == true ? cnpj! : (cpf ?? '');
}
