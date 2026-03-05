import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../providers/settings_provider.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  Sale? _sale;
  Map<String, dynamic>? _paymentData;
  PaymentStatus _status = PaymentStatus.pending;
  bool _isLoading = true;
  bool _isPolling = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Sale && _sale == null) {
      _sale = arg;
      _initPayment();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPayment() async {
    final settingsProv = context.read<SettingsProvider>();
    final mpService = settingsProv.mpService;

    if (!mpService.isConfigured) {
      setState(() {
        _error = 'Token do Mercado Pago não configurado.\nVá em Configurações.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await mpService.createPixPayment(
        amount: _sale!.totalAmount,
        description: 'Venda empada - ${DateFormat('dd/MM HH:mm').format(_sale!.date)}',
      );
      setState(() {
        _paymentData = data;
        _isLoading = false;
      });
      _startPolling(data['id'].toString());
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling(String paymentId) {
    _isPolling = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isPolling || !mounted) return;
      try {
        final mpService = context.read<SettingsProvider>().mpService;
        final status = await mpService.checkPaymentStatus(paymentId);
        if (!mounted) return;
        if (status != PaymentStatus.pending) {
          setState(() {
            _status = status;
            _isPolling = false;
          });
          _pollTimer?.cancel();
          _handleFinalStatus(status, paymentId);
        }
      } catch (_) {
        // Continua tentando em erros temporários
      }
    });
  }

  Future<void> _handleFinalStatus(PaymentStatus status, String mpId) async {
    final saleProv = context.read<SaleProvider>();
    if (status == PaymentStatus.approved) {
      await saleProv.approveSale(_sale!.id, mpId);
    } else {
      await saleProv.cancelSale(_sale!.id);
    }
  }

  String _copyText = 'Copiar código';

  void _copyPixCode() {
    final code = _paymentData?['qr_code'] ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copyText = 'Copiado!');
    Future.delayed(const Duration(seconds: 2),
        () => setState(() => _copyText = 'Copiar código'));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        leading: _status == PaymentStatus.pending
            ? IconButton(
                icon:
                    const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () async {
                  if (_sale != null) {
                    _pollTimer?.cancel();
                    await context
                        .read<SaleProvider>()
                        .cancelSale(_sale!.id);
                  }
                  if (mounted) Navigator.of(context).pop();
                },
              )
            : const SizedBox.shrink(),
        title: Text('Pagamento PIX',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
            : _error != null
                ? _ErrorState(message: _error!, onBack: () => Navigator.pop(context))
                : _status != PaymentStatus.pending
                    ? _ResultState(status: _status, onDone: () => Navigator.popUntil(context, ModalRoute.withName('/')))
                    : _PaymentState(
                        sale: _sale!,
                        paymentData: _paymentData!,
                        fmt: fmt,
                        copyText: _copyText,
                        onCopy: _copyPixCode,
                        isPolling: _isPolling,
                      ),
      ),
    );
  }
}

class _PaymentState extends StatelessWidget {
  final Sale sale;
  final Map<String, dynamic> paymentData;
  final NumberFormat fmt;
  final String copyText;
  final VoidCallback onCopy;
  final bool isPolling;

  const _PaymentState({
    required this.sale,
    required this.paymentData,
    required this.fmt,
    required this.copyText,
    required this.onCopy,
    required this.isPolling,
  });

  @override
  Widget build(BuildContext context) {
    final qrCode = paymentData['qr_code'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Escaneie o QR code para pagar',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(fmt.format(sale.totalAmount),
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (qrCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrCode,
                version: QrVersions.auto,
                size: 220,
              ),
            )
          else
            Container(
              height: 252,
              alignment: Alignment.center,
              child: Text('QR Code indisponível, use o código abaixo.',
                  style: GoogleFonts.outfit(color: Colors.white54),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 20),
          if (isPolling) ...[
            const CircularProgressIndicator(
                color: Color(0xFFFF6B35), strokeWidth: 2),
            const SizedBox(height: 8),
            Text('Aguardando confirmação...',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onCopy,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.copy_rounded,
                color: Color(0xFFFF6B35), size: 18),
            label: Text(copyText,
                style:
                    GoogleFonts.outfit(color: const Color(0xFFFF6B35))),
          ),
          const SizedBox(height: 12),
          Text('Copia e Cola PIX',
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  final PaymentStatus status;
  final VoidCallback onDone;
  const _ResultState({required this.status, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final approved = status == PaymentStatus.approved;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (approved ? const Color(0xFF43D29B) : Colors.redAccent)
                .withOpacity(0.15),
          ),
          child: Icon(
            approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color:
                approved ? const Color(0xFF43D29B) : Colors.redAccent,
            size: 80,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          approved ? 'Pagamento Aprovado!' : 'Pagamento Recusado',
          style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          approved
              ? 'Estoque atualizado automaticamente.'
              : 'A venda foi cancelada.',
          style: GoogleFonts.outfit(color: Colors.white54),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                approved ? const Color(0xFF43D29B) : const Color(0xFFFF6B35),
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Voltar ao Início',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorState({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.outfit(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Voltar',
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
