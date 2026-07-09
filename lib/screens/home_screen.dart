import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/banner.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';
import '../widgets/product_card.dart';
import '../widgets/animated_carousel.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'bundles_screen.dart';
import 'page_screen.dart';
import 'chat_list_screen.dart';
import 'compare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  void _onTabSelected(int i) {
    if (i == 0 || ApiService().hasToken) {
      setState(() => _tab = i);
      return;
    }
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((loggedIn) {
      if (loggedIn == true && mounted) {
        setState(() => _tab = i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const _HomeTab(),
        const OrdersScreen(),
        const WishlistScreen(),
        const ProfileScreen(),
      ][_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _onTabSelected,
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
  String? _selectedCategorySlug;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollC = ScrollController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCartCount();
    _scrollC.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchC.dispose();
    _scrollC.removeListener(_onScroll);
    _scrollC.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_showSuggestions) setState(() => _showSuggestions = false);
    if (_scrollC.position.pixels >= _scrollC.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    _currentPage = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prodFuture = _selectedCategorySlug != null
          ? _api.get('/products?category=$_selectedCategorySlug')
          : _api.get('/products');
      final results = await Future.wait([
        prodFuture,
        _api.get('/categories'),
        _api.get('/banners'),
      ]);
      if (!mounted) return;
      final prodData = results[0] as Map<String, dynamic>;
      final meta = prodData['meta'] as Map<String, dynamic>;
      setState(() {
        _products = (prodData['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _hasMore = (meta['current_page'] as int) < (meta['last_page'] as int);
        _categories = (results[1] as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        _banners = (results[2] as List)
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      var endpoint = '/products?page=$nextPage';
      if (_selectedCategorySlug != null) {
        endpoint += '&category=$_selectedCategorySlug';
      }
      final res = await _api.get(endpoint);
      if (!mounted) return;
      final resMap = res as Map<String, dynamic>;
      final meta = resMap['meta'] as Map<String, dynamic>;
      setState(() {
        _products.addAll((resMap['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>)));
        _currentPage = nextPage;
        _hasMore = (meta['current_page'] as int) < (meta['last_page'] as int);
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _selectCategory(String? slug) {
    setState(() => _selectedCategorySlug = slug);
    _loadData();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await _api.searchSuggestions(q);
        if (!mounted) return;
        setState(() {
          _suggestions = res;
          _showSuggestions = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _showSuggestions = false);
      }
    });
  }

  Widget _buildSuggestionItem(Map<String, dynamic> s) {
    final name = s['name'] as String? ?? '';
    final brand = s['brand'] as String?;
    final price = s['price'] as int? ?? 0;
    final image = AppConfig.imageUrl(s['image'] as String?);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: image != null
            ? CachedNetworkImage(imageUrl: image, width: 40, height: 40, fit: BoxFit.cover)
            : Container(width: 40, height: 40, color: Colors.grey[200], child: const Icon(Icons.image, size: 20)),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: brand != null ? Text(brand, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Text(formatPrice(price), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      onTap: () {
        setState(() => _showSuggestions = false);
        _searchC.clear();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: Product.fromJson(s))));
      },
    );
  }

  Widget _sectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Lihat Semua',
                  style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback? onTap, [Color? accent]) {
    final c = accent ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    switch (name) {
      case 'LCD & Display': return Icons.smartphone;
      case 'Battery': return Icons.battery_charging_full;
      case 'Flexible Cable': return Icons.cable;
      case 'Mainboard & IC': return Icons.memory;
      case 'Button & Switch': return Icons.touch_app;
      case 'Charger & Adapter': return Icons.power;
      case 'Data Cable': return Icons.usb;
      case 'Accessories': return Icons.headphones;
      default: return Icons.category;
    }
  }

  Widget _categoryGridItem(String name, String slug) {
    final selected = _selectedCategorySlug == slug;
    final icon = _categoryIcon(name);
    return GestureDetector(
      onTap: () => _selectCategory(selected ? null : slug),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(name,
                style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppColors.primary : AppColors.textSecondary),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
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

  Future<void> _loadCartCount() async {
    if (!_api.hasToken) return;
    try {
      final res = await _api.get('/cart');
      if (res is Map && res.containsKey('items')) {
        setState(() => _cartCount = (res['items'] as List).length);
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // ignore API errors (guest user, connection issue)
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              alignment: Alignment.center,
              child: const Text('PC',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Text('ProCell',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const Text('Store',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined,
                    color: AppColors.textPrimary),
                onPressed: () {
                  final goToCart = () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())).then((_) {
                      _loadCartCount();
                    });
                  };
                  if (!_api.hasToken) {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ).then((loggedIn) {
                      if (loggedIn == true && context.mounted) {
                        goToCart();
                      }
                    });
                  } else {
                    goToCart();
                  }
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'profile':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                case 'orders':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                case 'wishlist':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                case 'compare':
                  final ids = ProductDetailScreen.compareIds;
                  if (ids.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan produk dari halaman detail produk')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(productIds: List.from(ids))));
                case 'chat':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                case 'bundles':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BundlesScreen()));
                case 'about':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PageScreen(slug: 'about')));
                case 'logout':
                  _logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person_outlined, color: AppColors.textPrimary), title: Text('Profil Saya'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'orders', child: ListTile(leading: Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary), title: Text('Pesanan Saya'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'wishlist', child: ListTile(leading: Icon(Icons.favorite_outline, color: AppColors.textPrimary), title: Text('Wishlist'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'compare', child: ListTile(leading: Icon(Icons.compare_arrows, color: AppColors.textPrimary), title: Text('Bandingkan'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'bundles', child: ListTile(leading: Icon(Icons.inventory_2, color: AppColors.textPrimary), title: Text('Paket Bundling'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'chat', child: ListTile(leading: Icon(Icons.chat_outlined, color: AppColors.textPrimary), title: Text('Live Chat'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info_outline, color: AppColors.textPrimary), title: Text('Tentang Toko'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Keluar', style: TextStyle(color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: _loading
          ? RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      ShimmerLoading(height: 44, borderRadius: const BorderRadius.all(Radius.circular(24))),
                      const SizedBox(height: 12),
                      SizedBox(height: 36, child: ShimmerLoading(height: 36, borderRadius: const BorderRadius.all(Radius.circular(20)))),
                    ]),
                  )),
                  SliverToBoxAdapter(child: const BannerShimmer()),
                  const ProductGridShimmer(),
                ],
              ),
            )
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
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchC,
                                decoration: InputDecoration(
                                  hintText: 'Cari produk...',
                                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  suffixIcon: _suggestions.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _searchC.clear();
                                            setState(() {
                                              _suggestions = [];
                                              _showSuggestions = false;
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: _onSearchChanged,
                                onSubmitted: (v) {
                                  setState(() => _showSuggestions = false);
                                  _search(v);
                                },
                              ),
                            ),
                            if (_showSuggestions && _suggestions.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 250),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _suggestions.length,
                                  itemBuilder: (_, i) => _buildSuggestionItem(_suggestions[i]),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 44,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                itemCount: 3,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  if (i == 0) return _quickAction(Icons.inventory_2, 'Paket Bundling', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BundlesScreen())), Colors.purple);
                                  if (i == 1) return _quickAction(Icons.compare_arrows, 'Bandingkan', () {
                                    final ids = ProductDetailScreen.compareIds;
                                    if (ids.length < 2) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan produk dari halaman detail produk')));
                                      return;
                                    }
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(productIds: List.from(ids))));
                                  }, Colors.orange);
                                  return _quickAction(Icons.chat, 'Live Chat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())), AppColors.primary);
                                },
                              ),
                            ),
                          ],
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
                            child: AnimatedCarousel(
                              banners: _banners.map((b) => {
                                'image': b.image,
                                'title': b.title,
                                'link': b.link,
                              }).toList(),
                            ),
                          ),
                        if (_categories.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kategori',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () => setState(() => _selectedCategorySlug = null),
                                    child: const Text('Semua', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: _categories.length,
                                  itemBuilder: (_, i) {
                                    final c = _categories[i];
                                    return _categoryGridItem(c.name, c.slug);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: _sectionHeader('Produk Terbaru', null),
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
                        if (_loadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageScreen(slug: 'tentang-kami'))),
                                child: const Text('Tentang Kami', style: TextStyle(color: Colors.grey)),
                              ),
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
}
