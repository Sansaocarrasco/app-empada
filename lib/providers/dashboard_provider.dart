import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final SaleRepository _repo = SaleRepository();

  List<Sale> _todaySales = [];
  List<Map<String, dynamic>> _salesByProduct = [];
  List<Map<String, dynamic>> _dailySales = [];
  bool _isLoading = false;

  List<Sale> get todaySales => _todaySales;
  List<Map<String, dynamic>> get salesByProduct => _salesByProduct;
  List<Map<String, dynamic>> get dailySales => _dailySales;
  bool get isLoading => _isLoading;

  double get todayRevenue =>
      _todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);

  int get todaySaleCount => _todaySales.length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _todaySales = await _repo.getByDay(DateTime.now());
      _salesByProduct = await _repo.getSalesByProduct();
      _dailySales = await _repo.getDailySales();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
