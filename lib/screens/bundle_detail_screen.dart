import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';
import 'login_screen.dart';

class BundleDetailScreen extends StatefulWidget {
  final int bundleId;

  const BundleDetailScreen({super.key, required this.bundleId});

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _bundle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.getBundleDetail(widget.bundleId);
      if (!mounted) return;
      setState(() {
        _bundle = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat detail: $e';
        _loading = false;
      });
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
      await _api.addBundleToCart(widget.bundleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_bundle?['name'] ?? 'Paket'} ditambahkan ke keranjang')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _bundle?['name'] as String? ?? 'Detail Paket';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final bundle = _bundle!;
    final price = _toInt(bundle['price']);
    final discount = _toInt(bundle['discount_percent']);
    final items = bundle['items'] as List? ?? [];
    final image = AppConfig.imageUrl(bundle['image'] as String?);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image != null && image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(bundle['name'] as String? ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('-$discount%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(formatPrice(price),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                if (bundle['description'] != null && (bundle['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(bundle['description'] as String,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Text('${items.length} Item${items.length != 1 ? '' : ''} dalam Paket',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...items.map((item) => _buildItemCard(item as Map<String, dynamic>)),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tambah ke Keranjang', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _toInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final productName = item['name'] as String? ?? 'Produk';
    final productImage = AppConfig.imageUrl(item['image'] as String?);
    final quantity = _toInt(item['quantity'], 1);
    final price = _toInt(item['price'], 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: productImage != null && productImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: productImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$quantity x ${formatPrice(price)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(formatPrice(price * quantity),
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

}
