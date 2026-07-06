import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/banner.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const _HomeTab(),
          const OrdersScreen(),
          const WishlistScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  List<Product> _products = [];
  List<Category> _categories = [];
  List<BannerModel> _banners = [];
  bool _loading = true;
  String? _error;
  final _searchC = TextEditingController();
  List<Product> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prod = await _api.get('/products');
      final cat = await _api.get('/categories');
      final ban = await _api.get('/banners');
      if (!mounted) return;
      setState(() {
        _products = (prod['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _categories = (cat as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        _banners = (ban as List)
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .toList();
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

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await _api.get('/products?search=$q');
      if (!mounted) return;
      setState(() {
        _searchResults = (res['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProCell Store'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _searchC,
                            decoration: InputDecoration(
                              hintText: 'Cari produk...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onChanged: _search,
                          ),
                        ),
                      ),
                      if (_searching)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (_searchResults.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(
                                product: _searchResults[index],
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                            product:
                                                _searchResults[index]))),
                              ),
                              childCount: _searchResults.length,
                            ),
                          ),
                        )
                      else ...[
                        if (_banners.isNotEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 160,
                              child: PageView.builder(
                                itemCount: _banners.length,
                                itemBuilder: (_, i) => _buildBanner(i),
                              ),
                            ),
                          ),
                        if (_categories.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: _categories.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) => ActionChip(
                                    label: Text(_categories[i].name,
                                        style: const TextStyle(fontSize: 12)),
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(
                                product: _products[index],
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                            product: _products[index]))),
                              ),
                              childCount: _products.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildBanner(int i) {
    final b = _banners[i];
    if (b.image == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: b.image!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, _) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, _, _) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
