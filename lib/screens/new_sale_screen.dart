import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../models/product.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final saleProv = context.watch<SaleProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final filtered = prodProv.availableProducts
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        title: Text('Nova Venda',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (!saleProv.cartIsEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, saleProv),
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent, size: 18),
              label: Text('Limpar',
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Product grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Nenhum produto disponível',
                        style:
                            GoogleFonts.outfit(color: Colors.white38, fontSize: 15)))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ProductTile(
                      product: filtered[i],
                      cartQty: saleProv.cart
                          .firstWhere(
                              (ci) => ci.product.id == filtered[i].id,
                              orElse: () =>
                                  CartItem(product: filtered[i], quantity: 0))
                          .quantity,
                      onAdd: () => saleProv.addToCart(filtered[i]),
                      onRemove: () => saleProv.decrementCart(filtered[i].id),
                    ),
                  ),
          ),

          // Cart summary bar
          if (!saleProv.cartIsEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                border: Border(
                    top: BorderSide(
                        color: const Color(0xFFFF6B35).withOpacity(0.3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${saleProv.cartItemCount} item(s)',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 12)),
                        Text(fmt.format(saleProv.cartTotal),
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _checkout(context, saleProv),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.qr_code_rounded,
                          color: Colors.white),
                      label: Text('Pagar',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context, SaleProvider saleProv) async {
    final sale = await saleProv.createPendingSale();
    if (mounted) {
      await Navigator.of(context)
          .pushNamed('/qr-code', arguments: sale);
    }
  }

  void _confirmClear(BuildContext context, SaleProvider saleProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Limpar carrinho?',
            style: GoogleFonts.outfit(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              saleProv.clearCart();
              Navigator.pop(context);
            },
            child: Text('Limpar',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductTile({
    required this.product,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final inCart = cartQty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart
              ? const Color(0xFFFF6B35)
              : Colors.white12,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fastfood_rounded,
                      color: Color(0xFFFF6B35), size: 22),
                ),
                const Spacer(),
                Text(product.name,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(fmt.format(product.price),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF43D29B),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: inCart
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFFFF6B35).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: inCart
                              ? Text(
                                  '$cartQty',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                )
                              : const Icon(Icons.add,
                                  color: Color(0xFFFF6B35), size: 18),
                        ),
                      ),
                    ),
                    if (inCart) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove,
                              color: Colors.white54, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
