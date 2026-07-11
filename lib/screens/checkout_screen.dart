import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // Data from API
  List<dynamic> _bankAccounts = [];
  List<dynamic> _cities = [];
  Map<String, dynamic> _couriers = {};
  int _totalWeight = 0;
  int _cartTotal = 0;
  int _pointsBalance = 0;
  int _maxRedeemPoints = 0;

  // Profile auto-fill
  String? _profileAddress;
  int? _profileCityId;
  String? _profileCityName;
  String? _profileAddressType;
  bool _profileLoaded = false;

  // Selected values
  final _addressC = TextEditingController();
  int? _selectedCityId;
  String? _selectedCityName;
  String? _selectedCourier;
  String? _selectedService;
  int _shippingCost = 0;
  String _paymentMethod = 'bank_transfer';
  int? _selectedBankId;
  final _couponC = TextEditingController();
  int _couponDiscount = 0;
  String? _appliedCouponCode;
  bool _checkingCoupon = false;
  int _pointsToUse = 0;
  bool _usePoints = false;

  Map<String, dynamic>? _availableServices;
  bool _loadingRates = false;

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
    _loadCheckout();
  }

  @override
  void dispose() {
    _addressC.dispose();
    _couponC.dispose();
    super.dispose();
  }

  Future<void> _loadCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/checkout');
      if (!mounted) return;

      // Profile auto-fill
      final profile = res['profile'] as Map<String, dynamic>?;
      final profileAddress = profile?['address'] as String? ?? '';
      final profileCityId = profile?['city_id'] as int?;
      final profileCityName = profile?['city_name'] as String?;
      final profileAddressType = profile?['address_type'] as String?;

      setState(() {
        _bankAccounts = (res['bank_accounts'] as List?) ?? [];
        _cities = (res['cities'] as List?) ?? [];
        _couriers = Map<String, dynamic>.from(res['couriers'] as Map? ?? {});
        _totalWeight = res['total_weight'] as int? ?? 0;
        _cartTotal = (res['cart']['total'] as int?) ?? 0;
        _pointsBalance = res['points_balance'] as int? ?? 0;
        _maxRedeemPoints = res['max_redeem_points'] as int? ?? 0;

        _profileAddress = profileAddress;
        _profileCityId = profileCityId;
        _profileCityName = profileCityName;
        _profileAddressType = profileAddressType;
        _profileLoaded = true;

        _addressC.text = profileAddress;
        _selectedCityId = profileCityId;
        _selectedCityName = profileCityName;

        _loading = false;
      });

      if (profileCityId != null) {
        _loadRates();
      }
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

  Future<void> _checkCoupon() async {
    final code = _couponC.text.trim();
    if (code.isEmpty) return;
    setState(() => _checkingCoupon = true);
    try {
      final res = await _api.applyCoupon(code, _cartTotal);
      if (!mounted) return;
      setState(() {
        _couponDiscount = res['discount'] as int? ?? 0;
        _appliedCouponCode = code;
        _checkingCoupon = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diskon: ${res['discount_formatted']}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _couponDiscount = 0;
        _appliedCouponCode = null;
        _checkingCoupon = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removeCoupon() async {
    try {
      await _api.removeCoupon();
    } catch (_) {}
    setState(() {
      _couponDiscount = 0;
      _appliedCouponCode = null;
      _couponC.clear();
    });
  }

  Future<void> _showCityPicker() async {
    final TextEditingController searchC = TextEditingController();
    List<dynamic> filtered = List.from(_cities);

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Kota'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchC,
                      decoration: const InputDecoration(
                        hintText: 'Cari kota...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      autofocus: true,
                      onChanged: (v) {
                        setDialogState(() {
                          filtered = _cities.where((c) {
                            final name = (c['name'] as String?)?.toLowerCase() ?? '';
                            final province = (c['province'] as String?)?.toLowerCase() ?? '';
                            final q = v.toLowerCase();
                            return name.contains(q) || province.contains(q);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: filtered.map((c) => ListTile(
                          dense: true,
                          title: Text('${c['name']} (${c['province']})'),
                          selected: c['id'] == _selectedCityId,
                          onTap: () => Navigator.pop(ctx, { 'id': c['id'] as int, 'name': c['name'] as String }),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ],
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCityId = selected['id'] as int;
        _selectedCityName = selected['name'] as String;
        _selectedCourier = null;
        _selectedService = null;
        _shippingCost = 0;
        _availableServices = null;
      });
      _loadRates();
    }
    searchC.dispose();
  }

  Future<void> _loadRates() async {
    if (_selectedCityId == null || _totalWeight <= 0) return;
    setState(() => _loadingRates = true);
    try {
      final res = await _api.post('/checkout/courier-rates', body: {
        'destination': _selectedCityId,
        'weight': _totalWeight,
      });
      if (!mounted) return;
      setState(() {
        _couriers = Map<String, dynamic>.from(res['couriers'] as Map? ?? {});
        _selectedCourier = null;
        _selectedService = null;
        _shippingCost = 0;
        _availableServices = null;
        _loadingRates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRates = false);
    }
  }

  int get _discountAmount => _couponDiscount;

  int get _pointsDiscount {
    if (!_usePoints || _pointsToUse <= 0) return 0;
    final rate = 100; // points_redeem_rate default
    final maxDiscount = (_cartTotal * 0.5).toInt();
    return (_pointsToUse * rate).clamp(0, maxDiscount);
  }

  int get _grandTotal {
    return _cartTotal + _shippingCost - _discountAmount - _pointsDiscount;
  }

  Future<void> _submit() async {
    if (_addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alamat pengiriman wajib diisi')));
      return;
    }
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih kota tujuan')));
      return;
    }
    if (_selectedCourier == null || _selectedService == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih kurir dan layanan')));
      return;
    }
    if (_paymentMethod == 'bank_transfer' && _selectedBankId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih rekening bank tujuan')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await _api.post('/checkout/process', body: {
        'shipping_address': _addressC.text.trim(),
        'destination_city': _selectedCityId,
        'courier': _selectedCourier,
        'courier_service': _selectedService,
        'payment_method': _paymentMethod,
        'bank_account_id': _paymentMethod == 'bank_transfer' ? _selectedBankId : null,
        'coupon_code': _couponC.text.trim().isEmpty ? null : _couponC.text.trim(),
        'points_to_use': _usePoints ? _pointsToUse : 0,
        'notes': null,
        'city_name': _selectedCityName,
        'address_type': _profileAddressType,
      });
      if (!mounted) return;
      final order = res['order'] as Map<String, dynamic>;
      final midtransUrl = order['midtrans_redirect_url'] as String?;

      if (midtransUrl != null && midtransUrl.isNotEmpty) {
        final uri = Uri.parse(midtransUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _OrderSuccessScreen(
            orderNumber: order['order_number'] as String,
            grandTotal: order['grand_total_formatted'] as String,
            paymentMethod: order['payment_method'] as String,
            midtransUrl: midtransUrl,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Alamat Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_profileAddressType != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _profileAddressType == 'home' ? Colors.blue[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _profileAddressType == 'home' ? 'Rumah' : 'Kantor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _profileAddressType == 'home' ? Colors.blue[700] : Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressC,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Kota Tujuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCityPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCityName ?? 'Pilih kota',
                        style: TextStyle(
                          color: _selectedCityName != null ? Colors.black : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (_selectedCityName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_selectedCityName!, style: const TextStyle(fontSize: 12, color: Colors.green)),
              ),
            const SizedBox(height: 16),
            const Text('Kurir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loadingRates)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_couriers.isEmpty)
              const Text('Pilih kota terlebih dahulu', style: TextStyle(color: Colors.grey))
            else
              RadioGroup<String>(
                groupValue: _selectedCourier,
                onChanged: (v) {
                  setState(() {
                    _selectedCourier = v;
                    _selectedService = null;
                    _shippingCost = 0;
                    final data = _couriers[v] as Map<String, dynamic>?;
                    final svc = data?['services'];
                    if (svc is Map) {
                      _availableServices = Map<String, dynamic>.from(svc);
                    } else {
                      _availableServices = {};
                    }
                  });
                },
                child: Column(
                  children: _couriers.entries.map((entry) {
                    final code = entry.key;
                    final data = entry.value as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        title: Text(data['name'] as String? ?? code.toUpperCase()),
                        value: code,
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (_availableServices != null && _availableServices!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Layanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              RadioGroup<String>(
                groupValue: _selectedService,
                onChanged: (v) {
                  setState(() {
                    _selectedService = v;
                    final svcVal = _availableServices?[v];
                    _shippingCost = (svcVal is int) ? svcVal : ((svcVal as Map?)?['cost'] as int? ?? 0);
                  });
                },
                child: Column(
                  children: _availableServices!.entries.map((entry) {
                    final svc = entry.key;
                    final svcVal = entry.value;
                    final cost = (svcVal is int) ? svcVal : ((svcVal as Map?)?['cost'] as int? ?? 0);
                    final etd = (svcVal is Map) ? svcVal['etd'] as String? : null;
                    return RadioListTile<String>(
                      title: Text('$svc — ${formatPrice(cost)}'),
                      subtitle: etd != null ? Text('Estimasi: $etd') : null,
                      value: svc,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: 'bank_transfer', child: const Text('Transfer Bank')),
                DropdownMenuItem(value: 'midtrans', child: const Text('Midtrans (Kartu/VA/QRIS/E-Wallet)')),
              ],
              onChanged: (v) {
                setState(() {
                  _paymentMethod = v!;
                  _selectedBankId = null;
                });
              },
            ),
            if (_paymentMethod == 'bank_transfer' && _bankAccounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Pilih Rekening Tujuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              RadioGroup<int>(
                groupValue: _selectedBankId,
                onChanged: (v) => setState(() => _selectedBankId = v),
                child: Column(
                  children: _bankAccounts.map((b) => RadioListTile<int>(
                    title: Text('${b['bank_name']} — ${b['account_number']}'),
                    subtitle: Text('a.n. ${b['account_holder']}'),
                    value: b['id'] as int,
                    dense: true,
                  )).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Kupon (opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponC,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan kode kupon',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_appliedCouponCode != null)
                  TextButton(
                    onPressed: _removeCoupon,
                    child: const Text('Hapus'),
                  )
                else
                  ElevatedButton(
                    onPressed: _checkingCoupon ? null : _checkCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _checkingCoupon
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Gunakan'),
                  ),
              ],
            ),
            if (_appliedCouponCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Kupon "$_appliedCouponCode" aktif',
                    style: const TextStyle(color: Colors.green, fontSize: 12)),
              ),
            if (_pointsBalance > 0) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Gunakan Poin'),
                subtitle: Text('Saldo: $_pointsBalance poin (maks $_maxRedeemPoints)'),
                value: _usePoints,
                onChanged: (v) => setState(() => _usePoints = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_usePoints)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah poin (maks $_maxRedeemPoints)',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? 0;
                      setState(() => _pointsToUse = parsed.clamp(0, _maxRedeemPoints));
                    },
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', formatPrice(_cartTotal)),
                    _summaryRow('Ongkos Kirim', _shippingCost > 0 ? formatPrice(_shippingCost) : '-'),
                    if (_discountAmount > 0)
                      _summaryRow('Diskon Kupon', '-${formatPrice(_discountAmount)}', color: Colors.green),
                    if (_pointsDiscount > 0)
                      _summaryRow('Diskon Poin', '-${formatPrice(_pointsDiscount)}', color: Colors.green),
                    const Divider(),
                    _summaryRow('Total', formatPrice(_grandTotal), color: AppColors.primary, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Buat Pesanan', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final String grandTotal;
  final String paymentMethod;
  final String? midtransUrl;

  const _OrderSuccessScreen({
    required this.orderNumber,
    required this.grandTotal,
    required this.paymentMethod,
    this.midtransUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Dibuat'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Pesanan Berhasil Dibuat!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('No. Pesanan: $orderNumber', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Total: $grandTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(paymentMethod == 'midtrans' ? 'Pembayaran: Midtrans' : 'Pembayaran: Transfer Bank',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (midtransUrl != null)
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(midtransUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuka: $midtransUrl')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Bayar Sekarang'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
