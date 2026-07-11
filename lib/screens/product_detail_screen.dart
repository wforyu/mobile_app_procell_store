import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'compare_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import '../helpers/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  static final List<int> compareIds = <int>[];
  static bool _compareLoaded = false;

  static Future<void> loadCompareIds() async {
    if (_compareLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('compare_ids');
    compareIds.clear();
    if (ids != null) {
      compareIds.addAll(ids.map(int.parse));
    }
    _compareLoaded = true;
  }

  static Future<void> _saveCompareIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('compare_ids', compareIds.map((id) => id.toString()).toList());
  }

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
  List<Map<String, dynamic>> _frequentlyBought = [];

  @override
  void initState() {
    super.initState();
    ProductDetailScreen.loadCompareIds();
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
      _loadFrequentlyBought();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _product = widget.product;
        _loading = false;
      });
    }
  }

  Future<void> _loadFrequentlyBought() async {
    try {
      final data = await _api.getFrequentlyBoughtTogether(widget.product.slug);
      if (!mounted) return;
      setState(() => _frequentlyBought = data);
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    if (!_api.hasToken) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
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
    if (!_api.hasToken) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
    try {
      await _api.post('/cart/add',
          body: {'product_id': _product!.id, 'quantity': _qty});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Ditambahkan ke keranjang'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _quickBuy() async {
    if (!_api.hasToken) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
    final pid = (_product ?? widget.product).id;
    try {
      await _api.quickBuy(pid);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _requestRestock() async {
    final pid = (_product ?? widget.product).id;
    final emailC = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifikasi Stok'),
        content: TextField(
          controller: emailC,
          decoration: const InputDecoration(
            labelText: 'Email Anda',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, emailC.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await _api.requestRestock(pid, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi telah dikirim')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildReviewSection(Product p) {
    final reviews = p.reviews ?? [];

    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Belum ada ulasan', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 4),
            Text('Jadilah yang pertama memberi ulasan', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    double avgRating = (reviews.fold<int>(0, (sum, r) => sum + ((r['rating'] as int?) ?? 0))) / reviews.length;
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviews) {
      int rating = (r['rating'] as int?) ?? 0;
      if (rating >= 1 && rating <= 5) distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ulasan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => Icon(
                      i < avgRating.round() ? Icons.star : Icons.star_border,
                      size: 16, color: Colors.orange,
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text('${reviews.length} ulasan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    int star = 5 - i;
                    int count = distribution[star] ?? 0;
                    double pct = reviews.isEmpty ? 0 : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.orange.shade100,
                                valueColor: const AlwaysStoppedAnimation(Colors.orange),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    String name = r['user'] as String? ?? 'Anonymous';
    int rating = (r['rating'] as int?) ?? 0;
    String comment = r['comment'] as String? ?? '';
    String date = r['created_at'] as String? ?? '';
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 12, color: Colors.orange,
                          )),
                          const SizedBox(width: 8),
                          Text(_formatDate(date), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentlyBoughtSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Sering Dibeli Bersamaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _frequentlyBought.length,
            itemBuilder: (_, i) {
              final item = _frequentlyBought[i];
              final name = item['name'] as String? ?? '';
              final price = item['price'] as int? ?? 0;
              final image = item['image'] as String?;
              final slug = item['slug'] as String?;
              final stock = item['stock'] as int? ?? 0;
              return GestureDetector(
                onTap: slug != null ? () async {
                  try {
                    final res = await _api.get('/products/$slug');
                    if (!mounted) return;
                    final prod = Product.fromJson(res as Map<String, dynamic>);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)));
                  } catch (_) {}
                } : null,
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (image != null)
                                CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)
                              else
                                Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                              if (stock <= 0)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  child: const Center(
                                    child: Text('Habis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
              ProductDetailScreen.compareIds.contains((_product ?? widget.product).id) ? Icons.compare_arrows : Icons.compare_arrows_outlined,
            ),
            onPressed: () {
              final pid = (_product ?? widget.product).id;
              if (ProductDetailScreen.compareIds.contains(pid)) {
                ProductDetailScreen.compareIds.remove(pid);
                ProductDetailScreen._saveCompareIds();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari perbandingan')));
              } else if (ProductDetailScreen.compareIds.length >= 4) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 4 produk')));
              } else {
                ProductDetailScreen.compareIds.add(pid);
                ProductDetailScreen._saveCompareIds();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke perbandingan')));
              }
              setState(() {});
              if (ProductDetailScreen.compareIds.length >= 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(productIds: List.from(ProductDetailScreen.compareIds))));
              }
            },
          ),
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
                      itemCount: (p.images != null && p.images!.isNotEmpty) ? p.images!.length : 1,
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
                                  ? AppColors.primary
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
                                    color: AppColors.primary)),
                            if (p.isFlashSaleActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on, size: 14, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text('FLASH SALE',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
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
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _buildReviewSection(p),
                        if (_frequentlyBought.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildFrequentlyBoughtSection(),
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Tambah ke Keranjang',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _quickBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: const Text('Beli Langsung',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _requestRestock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Notify Me',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
    );
  }
}
