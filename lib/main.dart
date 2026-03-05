import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/dev_config.dart';
import 'providers/product_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/settings_provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/new_sale_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: DevConfig.supabaseUrl,
    anonKey: DevConfig.supabaseAnonKey,
  );

  // Barra de status transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AppEmpada());
}

class AppEmpada extends StatelessWidget {
  const AppEmpada({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..loadProducts()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..load()),
        // SaleProvider recebe o MercadoPagoService do SettingsProvider automaticamente
        ChangeNotifierProxyProvider<SettingsProvider, SaleProvider>(
          create: (_) => SaleProvider(),
          update: (_, settingsProv, saleProv) {
            saleProv!.setMpService(settingsProv.mpService);
            return saleProv;
          },
        ),
      ],
      child: MaterialApp(
        title: 'App Empada',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: const Color(0xFF0F0F1E),
            titleTextStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const MainShell(),
          '/product-form': (_) => const ProductFormScreen(),
          '/qr-code': (_) => const QrCodeScreen(),
        },
      ),
    );
  }
}

/// Shell principal com BottomNavigationBar
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    NewSaleScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121F),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Início',
                  index: 0,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Produtos',
                  index: 1,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 1)),
              // Botão central destacado
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('Vender',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
              _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Relatórios',
                  index: 3,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 3)),
              _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Config',
                  index: 4,
                  current: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final color = isSelected ? const Color(0xFFFF6B35) : Colors.white38;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
