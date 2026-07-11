import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';
import 'product_detail_screen.dart';

class CompareScreen extends StatefulWidget {
  final List<int> productIds;

  const CompareScreen({super.key, required this.productIds});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final ApiService _api = ApiService();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompare();
  }

  Future<void> _loadCompare() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getCompare(widget.productIds);
      if (!mounted) return;
      setState(() {
        _products = data.map((e) => Product.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Bandingkan Produk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.length < 2
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Pilih minimal 2 produk untuk dibandingkan',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildProductStrip(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                    _buildAttributeSection('Informasi Produk', [
                      _attr('Harga', (p) {
                        if (p.hasDiscount) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.priceFormatted,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                              Text(p.effectivePriceFormatted,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                            ],
                          );
                        }
                        return Text(p.effectivePriceFormatted,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary));
                      }),
                      _attr('Brand', (p) => _val(p.brand ?? '-')),
                      _attr('Kategori', (p) => _val(p.category?.name ?? '-')),
                    ]),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    _buildAttributeSection('Spesifikasi', [
                      _attr('SKU', (p) => _val(p.sku ?? '-')),
                      _attr('Berat', (p) => p.weight != null ? _val('${p.weight} gr') : _val('-')),
                      _attr('Stok', (p) {
                        final color = p.stock > 0 ? Colors.green : Colors.red;
                        return Text(p.stock > 0 ? '${p.stock} tersedia' : 'Habis',
                            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13));
                      }),
                      _attr('Rating', (p) {
                        return Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < p.rating.round() ? Icons.star : Icons.star_border,
                              size: 14, color: Colors.orange,
                            )),
                            const SizedBox(width: 4),
                            Text('(${p.reviewCount})', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        );
                      }),
                    ]),
                    if (_products.any((p) => p.description != null && p.description!.isNotEmpty))
                      _buildAttributeSection('Deskripsi', [
                        _attr('', (p) => Text(p.description ?? '-', style: const TextStyle(fontSize: 12), maxLines: 5, overflow: TextOverflow.ellipsis)),
                      ]),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
    );
  }

  Widget _buildProductStrip() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
            ),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: p.image != null
                        ? CachedNetworkImage(imageUrl: p.image!, height: 110, width: 170, fit: BoxFit.cover,
                            placeholder: (_, _) => Container(height: 110, color: Colors.grey[200]),
                            errorWidget: (_, _, _) => Container(height: 110, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                        : Container(height: 110, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Text(p.effectivePriceFormatted,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttributeSection(String title, List<MapEntry<String, Widget Function(Product)>> attrs) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ...attrs.asMap().entries.map((entry) {
              return Column(
                children: [
                  if (entry.key > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildAttrRow(entry.value.key, entry.value.value),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttrRow(String label, Widget Function(Product) builder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
            ),
          ..._products.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(top: e.key > 0 ? 4 : 0),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: builder(e.value)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _val(String text) => Text(text, style: const TextStyle(fontSize: 13));

  MapEntry<String, Widget Function(Product)> _attr(String label, Widget Function(Product) builder) {
    return MapEntry(label, builder);
  }
}
