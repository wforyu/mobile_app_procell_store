import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';

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
        _products = data
            .map((e) => Product.fromJson(e))
            .toList();
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
      appBar: AppBar(
        title: const Text('Bandingkan Produk'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.length < 2
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Pilih minimal 2 produk untuk dibandingkan',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageRow(),
                      _buildDivider(),
                      _buildLabelRow('Nama', (p) => Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )),
                      _buildDivider(),
                      _buildLabelRow('Harga', (p) {
                        if (p.hasDiscount) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.priceFormatted,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                p.effectivePriceFormatted,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          p.effectivePriceFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        );
                      }),
                      _buildDivider(),
                      _buildLabelRow('Brand',
                          (p) => Text(p.brand ?? '-', style: _valueStyle)),
                      _buildDivider(),
                      _buildLabelRow('Kategori', (p) => Text(
                          p.category?.name ?? '-', style: _valueStyle)),
                      _buildDivider(),
                      _buildLabelRow(
                          'SKU', (p) => Text(p.sku ?? '-', style: _valueStyle)),
                      _buildDivider(),
                      _buildLabelRow('Berat', (p) => p.weight != null
                          ? Text('${p.weight} gr', style: _valueStyle)
                          : Text('-', style: _valueStyle)),
                      _buildDivider(),
                      _buildLabelRow('Stok', (p) {
                        final color = p.stock > 0 ? Colors.green : Colors.red;
                        return Text(
                          p.stock > 0 ? '${p.stock} tersedia' : 'Habis',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: color),
                        );
                      }),
                      _buildDivider(),
                      _buildLabelRow('Rating', (p) {
                        return Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < p.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${p.reviewCount})',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        );
                      }),
                      if (_products.any((p) => p.description != null &&
                          p.description!.isNotEmpty)) ...[
                        _buildDivider(),
                        _buildLabelRow('Deskripsi', (p) => Text(
                          p.description ?? '-',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildImageRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 100,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Foto',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey)),
            ),
          ),
          ..._products.map((p) => SizedBox(
                width: 160,
                child: _buildProductImage(p),
              )),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product p) {
    if (p.image == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: p.image!,
        height: 120,
        width: 160,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          height: 120,
          color: Colors.grey[200],
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, _, _) => Container(
          height: 120,
          color: Colors.grey[200],
          child: const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLabelRow(
      String label, Widget Function(Product) builder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey)),
          ),
          ..._products.map((p) => SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: builder(p),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }

  TextStyle get _valueStyle => const TextStyle(fontSize: 13);
}
