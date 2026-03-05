import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _pubKeyCtrl = TextEditingController();
  bool _obscureToken = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields();
      // Também escuta mudanças caso o load() async ainda não tivesse terminado.
      context.read<SettingsProvider>().addListener(_populateFields);
    });
  }

  void _populateFields() {
    if (!mounted) return;
    final prov = context.read<SettingsProvider>();
    if (prov.isLoading) return; // Aguarda o load() terminar
    final s = prov.settings;
    // Só sobrescreve se o campo estiver vazio (evita apagar o que o usuário já digitou)
    if (_tokenCtrl.text.isEmpty) _tokenCtrl.text = s.mpAccessToken;
    if (_pubKeyCtrl.text.isEmpty) _pubKeyCtrl.text = s.mpPublicKey;
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = s.companyName;
    if (_cpfCtrl.text.isEmpty) _cpfCtrl.text = s.cpf ?? '';
    if (_cnpjCtrl.text.isEmpty) _cnpjCtrl.text = s.cnpj ?? '';
  }

  @override
  void dispose() {
    // Remove o listener para evitar memory leak
    context.read<SettingsProvider>().removeListener(_populateFields);
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _cnpjCtrl.dispose();
    _tokenCtrl.dispose();
    _pubKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final settings = AppSettings(
      companyName: _nameCtrl.text.trim(),
      cpf: _cpfCtrl.text.trim().isEmpty ? null : _cpfCtrl.text.trim(),
      cnpj: _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
      mpAccessToken: _tokenCtrl.text.trim(),
      mpPublicKey: _pubKeyCtrl.text.trim(),
    );

    await context.read<SettingsProvider>().save(settings);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configurações salvas!',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFF43D29B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        title: Text('Configurações',
            style:
                GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(label: 'Dados do Empreendedor'),
            const SizedBox(height: 12),
            _buildField(
              controller: _nameCtrl,
              label: 'Nome do negócio',
              icon: Icons.storefront_rounded,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _cpfCtrl,
              label: 'CPF (autônomo)',
              icon: Icons.badge_rounded,
              hint: 'Ex: 000.000.000-00',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // CNPJ opcional – exibição com indicação de futuro
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_rounded,
                          color: Color(0xFF6C63FF), size: 16),
                      const SizedBox(width: 6),
                      Text('CNPJ (opcional — para o futuro)',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _cnpjCtrl,
                    label: 'CNPJ',
                    icon: Icons.domain_rounded,
                    hint: 'Preencha quando formalizar',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _SectionHeader(label: 'Mercado Pago'),
            const SizedBox(height: 4),
            Text(
              'Acesse sua conta MP → Credenciais → Produção para obter as chaves.',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _tokenCtrl,
              label: 'Access Token',
              icon: Icons.vpn_key_rounded,
              obscureText: _obscureToken,
              hint: 'APP_USR-...',
              suffix: IconButton(
                icon: Icon(
                  _obscureToken ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Informe o Access Token' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _pubKeyCtrl,
              label: 'Public Key',
              icon: Icons.lock_open_rounded,
              hint: 'APP_USR-...',
            ),

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Salvar',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 12),
        labelStyle: GoogleFonts.outfit(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B35)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
      ],
    );
  }
}
