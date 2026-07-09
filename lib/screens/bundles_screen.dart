import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';
import 'bundle_detail_screen.dart';
import 'login_screen.dart';

class BundlesScreen extends StatefulWidget {
  const BundlesScreen({super.key});

  @override
  State<BundlesScreen> createState() => _BundlesScreenState();
}

class _BundlesScreenState extends State<BundlesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _bundles = [];
  bool _loading = true;
  String? _error;

  int _toInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _loadBundles();
  }

  Future<void> _loadBundles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundles = await _api.getBundles();
      if (!mounted) return;
      setState(() {
        _bundles = bundles;
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
        _error = 'Gagal memuat data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addToCart(Map<String, dynamic> bundle) async {
    if (!_api.hasToken) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
    final id = _toInt(bundle['id']);
    try {
      await _api.addBundleToCart(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bundle['name']} ditambahkan ke keranjang')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Bundling'),
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
                onPressed: _loadBundles,
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

    if (_bundles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada paket bundling',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBundles,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bundles.length,
        itemBuilder: (_, i) => _buildBundleCard(_bundles[i]),
      ),
    );
  }

  Widget _buildBundleCard(Map<String, dynamic> bundle) {
    final name = bundle['name'] as String? ?? '';
    final price = _toInt(bundle['price']);
    final discount = _toInt(bundle['discount_percent']);
    final image = AppConfig.imageUrl(bundle['image'] as String?);
    final items = (bundle['items'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: image != null && image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 160,
                        color: Colors.grey[200],
                        child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                      ),
              ),
              if (discount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('-$discount%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(formatPrice(price),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                if (items > 0) ...[
                  const SizedBox(height: 8),
                  Text('$items item',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BundleDetailScreen(bundleId: _toInt(bundle['id'])),
                            ),
                          );
                        },
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addToCart(bundle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tambah ke Keranjang'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
