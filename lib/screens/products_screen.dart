import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        title: Text('Produtos',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => provider.loadProducts(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : provider.products.isEmpty
              ? _EmptyState(onAdd: () => _openForm(context, null))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = provider.products[i];
                    return _ProductCard(
                      product: p,
                      onEdit: () => _openForm(context, p),
                      onDelete: () => _confirmDelete(context, p),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Novo Produto',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _openForm(BuildContext context, Product? product) {
    Navigator.of(context)
        .pushNamed('/product-form', arguments: product)
        .then((_) => context.read<ProductProvider>().loadProducts());
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Excluir produto?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'Tem certeza que deseja excluir "${p.name}"?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(p.id);
              Navigator.pop(context);
            },
            child: Text('Excluir',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isLow = product.quantity <= 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isLow ? Colors.orangeAccent.withOpacity(0.5) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_rounded, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                if (product.description.isNotEmpty)
                  Text(product.description,
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(fmt.format(product.price),
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF43D29B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLow
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${product.quantity} un.',
                          style: GoogleFonts.outfit(
                              color: isLow ? Colors.orangeAccent : Colors.white60,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF16213E),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text('Editar',
                      style: GoogleFonts.outfit(color: Colors.white70)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('Excluir',
                      style: GoogleFonts.outfit(color: Colors.redAccent)),
                ]),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 72, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('Nenhum produto cadastrado',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Cadastrar primeiro produto',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
