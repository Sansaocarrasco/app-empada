import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/app_settings.dart';

/// Gerencia as configurações do app.
/// Token do MP é armazenado de forma segura (flutter_secure_storage).
/// Nome e CPF ficam no SharedPreferences.
class SettingsService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken) ?? '';
    final publicKey = await _secureStorage.read(key: AppConstants.keyPublicKey) ?? '';

    return AppSettings(
      companyName: prefs.getString(AppConstants.keyCompanyName) ?? 'Minha Empada',
      cpf: prefs.getString(AppConstants.keyCpf),
      cnpj: prefs.getString(AppConstants.keyCnpj),
      mpAccessToken: token,
      mpPublicKey: publicKey,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    // Dados não sensíveis no SharedPreferences
    await prefs.setString(AppConstants.keyCompanyName, settings.companyName);
    if (settings.cpf != null) {
      await prefs.setString(AppConstants.keyCpf, settings.cpf!);
    }
    if (settings.cnpj != null && settings.cnpj!.isNotEmpty) {
      await prefs.setString(AppConstants.keyCnpj, settings.cnpj!);
    }

    // Credenciais do MP de forma segura
    await _secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: settings.mpAccessToken,
    );
    await _secureStorage.write(
      key: AppConstants.keyPublicKey,
      value: settings.mpPublicKey,
    );
  }
}
