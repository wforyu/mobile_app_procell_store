import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cart.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import '../helpers/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _api = ApiService();
  Cart? _cart;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (!_api.hasToken) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/cart');
      if (!mounted) return;
      setState(() {
        _cart = Cart.fromJson(res as Map<String, dynamic>);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQty(int productId, int qty) async {
    if (qty < 1) return;
    await _api.post('/cart/update', body: {
      'product_id': productId,
      'quantity': qty,
    });
    _loadCart();
  }

  Future<void> _removeItem(int productId) async {
    await _api.post('/cart/remove', body: {'product_id': productId});
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Keranjang kosong',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCart,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart!.items.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _cart!.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(_cart!.totalFormatted,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Lanjut Checkout',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final item = _cart!.items[i];
                      final prod = item.product;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: prod?.image != null
                                    ? CachedNetworkImage(
                                        imageUrl: prod!.image!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover)
                                    : Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod?.name ?? 'Produk',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                          onPressed: item.quantity > 1
                                              ? () => _updateQty(item.productId, item.quantity - 1)
                                              : null,
                                        ),
                                        Text('${item.quantity}',
                                            style: const TextStyle(fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                          onPressed: () => _updateQty(item.productId, item.quantity + 1),
                                        ),
                                        const Spacer(),
                                        Text(item.subtotalFormatted,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Produk'),
                                      content: Text('Hapus ${prod?.name ?? "produk"} dari keranjang?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) _removeItem(item.productId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
