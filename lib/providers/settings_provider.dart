import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../services/mercado_pago_service.dart';
import '../core/dev_config.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  final MercadoPagoService mpService = MercadoPagoService();

  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isMpConfigured => _settings.isConfigured;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsService.load();

    // Se não tiver token salvo, usa os valores do DevConfig.
    if (!_settings.isConfigured &&
        DevConfig.mpAccessToken.isNotEmpty &&
        DevConfig.mpAccessToken != 'SEU_ACCESS_TOKEN_AQUI') {
      _settings = _settings.copyWith(
        mpAccessToken: DevConfig.mpAccessToken,
        mpPublicKey: DevConfig.mpPublicKey,
        companyName: DevConfig.companyName,
        cpf: DevConfig.cpf,
      );
      // Persiste para não depender do DevConfig em toda inicialização.
      await _settingsService.save(_settings);
    }

    if (_settings.isConfigured) {
      mpService.configure(_settings.mpAccessToken);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> save(AppSettings settings) async {
    await _settingsService.save(settings);
    _settings = settings;
    mpService.configure(settings.mpAccessToken);
    notifyListeners();
  }
}
