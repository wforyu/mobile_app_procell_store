import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  Product? _product;
  bool _loading = true;
  int _qty = 1;
  int _currentImage = 0;
  bool _wishlisted = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final res = await _api.get('/products/${widget.product.slug}');
      if (!mounted) return;
      setState(() {
        _product = Product.fromJson(res);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _product = widget.product;
        _loading = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    try {
      final res = await _api.post('/wishlist/toggle', body: {
        'product_id': (_product ?? widget.product).id,
      });
      if (!mounted) return;
      setState(() => _wishlisted = res['wishlisted'] as bool);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addToCart() async {
    try {
      await _api.post('/cart/add',
          body: {'product_id': _product!.id, 'quantity': _qty});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditambahkan ke keranjang')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product ?? widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _wishlisted ? Icons.favorite : Icons.favorite_border,
              color: _wishlisted ? Colors.red : null,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: p.images?.length ?? 1,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) {
                        final url = p.images != null && p.images!.isNotEmpty
                            ? p.images![i]['url'] as String
                            : p.image;
                        if (url == null) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.image, size: 80)),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 80),
                          ),
                        );
                      },
                    ),
                  ),
                  if ((p.images?.length ?? 0) > 1)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          p.images!.length,
                          (i) => Container(
                            margin: const EdgeInsets.all(4),
                            width: _currentImage == i ? 10 : 6,
                            height: _currentImage == i ? 10 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImage == i
                                  ? const Color(0xFF1A73E8)
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.brand != null)
                          Text(p.brand!,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < p.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('(${p.reviewCount})',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (p.hasDiscount) ...[
                              Text(p.priceFormatted,
                                  style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[400],
                                      fontSize: 14)),
                              const SizedBox(width: 8),
                            ],
                            Text(p.effectivePriceFormatted,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A73E8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.inventory, size: 14, color: p.stock > 0 ? Colors.green : Colors.red),
                            const SizedBox(width: 4),
                            Text(p.stock > 0 ? 'Stok: ${p.stock}' : 'Stok Habis',
                                style: TextStyle(
                                    color: p.stock > 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (p.sku != null)
                          Text('SKU: ${p.sku}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        if (p.weight != null)
                          Text('Berat: ${p.weight}g',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Jumlah: ',
                                style: TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _qty > 1
                                  ? () => setState(() => _qty--)
                                  : null,
                            ),
                            Text('$_qty',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: _qty < p.stock
                                  ? () => setState(() => _qty++)
                                  : null,
                            ),
                          ],
                        ),
                        if (p.description != null && p.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Deskripsi',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(p.description!,
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                        if (p.reviews != null && p.reviews!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Ulasan',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...p.reviews!.map((r) => Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text((r['user'] as String)[0]),
                                  ),
                                  title: Text(r['user'] as String),
                                  subtitle: Text(r['comment'] as String? ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < ((r['rating'] as int?) ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: p.stock > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _loading ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Tambah ke Keranjang',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }
}
