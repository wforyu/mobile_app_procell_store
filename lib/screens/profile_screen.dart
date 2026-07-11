import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../helpers/theme.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'chat_list_screen.dart';
import 'page_screen.dart';
import 'bundles_screen.dart';
import 'loyalty_points_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  User? _user;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();

  String? _addressType;
  int? _cityId;
  String? _cityName;
  List<dynamic> _allCities = [];
  bool _loadingCities = false;

  int _orderCount = 0;
  int _wishlistCount = 0;
  int _pointsBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!_api.hasToken) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.get('/profile');
      if (!mounted) return;
      final user = User.fromJson(res);
      final ordersRes = await _api.get('/orders');
      final wishlistRes = await _api.get('/wishlist');
      if (!mounted) return;
      final orderList = (ordersRes is Map && ordersRes.containsKey('data'))
          ? (ordersRes['data'] as List)
          : (ordersRes as List);
      final wishlistList = (wishlistRes is List)
          ? wishlistRes
          : (wishlistRes['data'] as List? ?? []);
      int pts = 0;
      try {
        final ptsRes = await _api.get('/loyalty/balance');
        pts = ptsRes['balance'] as int? ?? 0;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _user = user;
        _nameC.text = user.name;
        _phoneC.text = user.phone ?? '';
        _addressC.text = user.address ?? '';
        _addressType = user.addressType;
        _cityId = user.cityId;
        _cityName = user.cityName;
        _orderCount = orderList.length;
        _wishlistCount = wishlistList.length;
        _pointsBalance = pts;
        _loading = false;
      });
      _loadCities();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCities() async {
    try {
      final res = await _api.get('/cities');
      if (!mounted) return;
      setState(() {
        _allCities = (res['cities'] as List?) ?? [];
        _loadingCities = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _showCityPicker() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CityPickerDialog(
        cities: _allCities,
        selectedCityId: _cityId,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _cityId = selected['id'] as int;
        _cityName = selected['name'] as String;
      });
    }
  }

  Future<void> _showChangePassword() async {
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentC,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newC,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmC,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (currentC.text.isEmpty || newC.text.length < 8 || newC.text != confirmC.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password baru minimal 8 karakter dan harus cocok')),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await _auth.updatePassword(currentC.text, newC.text, confirmC.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
                  }
                  Navigator.pop(ctx, true);
                } on ApiException catch (e) {
                  setDialogState(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } catch (e) {
                  setDialogState(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
              child: saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    currentC.dispose();
    newC.dispose();
    confirmC.dispose();
  }

  Future<void> _showDeleteAccount() async {
    final passC = TextEditingController();
    bool saving = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: const Text('Hapus Akun?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tindakan ini tidak dapat dibatalkan. Semua data Anda akan dihapus permanen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Masukkan Password',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (passC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password wajib diisi')),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await _auth.deleteAccount(passC.text);
                  Navigator.pop(ctx, true);
                } on ApiException catch (e) {
                  setDialogState(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } catch (e) {
                  setDialogState(() => saving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hapus Akun'),
            ),
          ],
        ),
      ),
    );
    passC.dispose();

    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final user = await _auth.updateProfile({
        'name': _nameC.text.trim(),
        'phone': _phoneC.text.trim().isEmpty ? null : _phoneC.text.trim(),
        'address': _addressC.text.trim().isEmpty ? null : _addressC.text.trim(),
        'address_type': _addressType,
        'city_id': _cityId,
        'city_name': _cityName,
      });
      if (!mounted) return;
      setState(() {
        _editing = false;
        _user = user;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil tersimpan')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _auth.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showServerSettings() async {
    final serverC = TextEditingController(text: AppConfig.currentUrl);
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pengaturan Server'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan URL API server. Kosongkan untuk pakai default.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverC,
                  decoration: const InputDecoration(
                    labelText: 'API URL',
                    hintText: 'https://xxxx.ngrok-free.app/api',
                    prefixIcon: Icon(Icons.dns_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contoh:\n• Lokal: http://192.168.100.7:8000/api\n• Ngrok: https://abc.ngrok-free.app/api\n• VPS: https://tokoku.com/api',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setDialogState(() => saving = true);
                await AppConfig.setBaseUrl(serverC.text.trim());
                setDialogState(() => saving = false);
                if (context.mounted) Navigator.pop(ctx, true);
              },
              child: saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    serverC.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server URL: ${AppConfig.baseUrl}')),
      );
    }
  }

  Color _parseBadgeColor(String? color) {
    switch (color) {
      case 'gold':
      case 'yellow':
      case 'amber':
        return Colors.amber;
      case 'silver':
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'bronze':
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final u = _user!;
    final badgeColor = _parseBadgeColor(u.badgeColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: u.avatar != null
                              ? CachedNetworkImageProvider(u.avatar!)
                              : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          child: u.avatar == null
                              ? Text(
                                  u.name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        if (u.membershipTier != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              u.membershipTier!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      u.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u.email,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bergabung ${_formatDate(u.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Cards ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _statCard(Icons.receipt_long, 'Pesanan', _orderCount.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard(Icons.money, 'Total Belanja', u.totalSpentFormatted ?? 'Rp0')),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard(Icons.stars_rounded, 'Poin', _pointsBalance.toString())),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Edit Form ──
              if (_editing)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameC,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneC,
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressC,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      // Address type
                      const Text('Tipe Alamat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: RadioListTile<String>(
                              title: const Text('Rumah', style: TextStyle(fontSize: 14)),
                              value: 'home',
                              groupValue: _addressType,
                              onChanged: (v) => setState(() => _addressType = v),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Flexible(
                            child: RadioListTile<String>(
                              title: const Text('Kantor', style: TextStyle(fontSize: 14)),
                              value: 'office',
                              groupValue: _addressType,
                              onChanged: (v) => setState(() => _addressType = v),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // City picker
                      const Text('Kota', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _showCityPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city_outlined, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _cityName ?? 'Pilih kota',
                                  style: TextStyle(
                                    color: _cityName != null ? Colors.black : Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Simpan Profil', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Menu Items ──
              if (!_editing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _menuSection('Akun', [
                    _menuItem(Icons.receipt_long_outlined, 'Riwayat Pesanan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())), badge: _orderCount.toString()),
                    _menuItem(Icons.favorite_outline, 'Wishlist', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())), badge: _wishlistCount.toString()),
                    _menuItem(Icons.local_activity, 'Paket Bundling', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BundlesScreen()))),
                    _menuItem(Icons.chat_outlined, 'Pusat Bantuan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
                    _menuItem(Icons.lock_outline, 'Ubah Password', _showChangePassword),
                    _menuItem(Icons.stars_rounded, 'Riwayat Poin', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyPointsScreen())), badge: _pointsBalance.toString()),
                  ]),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _menuSection('Info', [
                    _menuItem(Icons.dns_outlined, 'Pengaturan Server', _showServerSettings),
                    _menuItem(Icons.store_outlined, 'Tentang Toko', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageScreen(slug: 'tentang-kami')))),
                    _menuItem(Icons.description_outlined, 'Syarat & Ketentuan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageScreen(slug: 'syarat-ketentuan')))),
                    _menuItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageScreen(slug: 'kebijakan-privasi')))),
                  ]),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showDeleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                      label: const Text('Hapus Akun', style: TextStyle(color: Colors.red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback? onTap, {String? badge}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            )
          : const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

class _CityPickerDialog extends StatefulWidget {
  final List<dynamic> cities;
  final int? selectedCityId;

  const _CityPickerDialog({required this.cities, this.selectedCityId});

  @override
  State<_CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<_CityPickerDialog> {
  late TextEditingController _searchC;
  late List<dynamic> _filtered;

  @override
  void initState() {
    super.initState();
    _searchC = TextEditingController();
    _filtered = List.from(widget.cities);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    setState(() {
      _filtered = widget.cities.where((c) {
        final name = (c['name'] as String?)?.toLowerCase() ?? '';
        final province = (c['province'] as String?)?.toLowerCase() ?? '';
        final q = v.toLowerCase();
        return name.contains(q) || province.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Kota'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchC,
              decoration: const InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  return ListTile(
                    dense: true,
                    title: Text('${c['name']} (${c['province']})'),
                    selected: c['id'] == widget.selectedCityId,
                    onTap: () => Navigator.pop(
                      context,
                      {'id': c['id'] as int, 'name': c['name'] as String},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
