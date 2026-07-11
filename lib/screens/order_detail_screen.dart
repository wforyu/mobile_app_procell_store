import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';
import 'return_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  Order? _order;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<Map<String, dynamic>> _bankAccounts = [];
  Timer? _pollTimer;
  String? _lastStatus;

  static const _statusSteps = ['pending', 'waiting_confirmation', 'processing', 'shipped', 'completed'];
  static const _stepLabels = {
    'pending': 'Menunggu Pembayaran',
    'waiting_confirmation': 'Menunggu Konfirmasi',
    'processing': 'Diproses',
    'shipped': 'Dikirim',
    'completed': 'Selesai',
  };

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _order == null) return;
      _pollOrderStatus();
    });
  }

  Future<void> _pollOrderStatus() async {
    try {
      final res = await _api.get('/orders/${widget.orderId}');
      if (!mounted) return;
      final newOrder = Order.fromJson(res as Map<String, dynamic>, detail: true);
      final newStatus = newOrder.status;
      if (newStatus != _lastStatus && _lastStatus != null) {
        setState(() => _order = newOrder);
        _showStatusChangeSnackbar(_lastStatus!, newStatus);
      }
      _lastStatus = newStatus;
    } catch (_) {}
  }

  void _showStatusChangeSnackbar(String oldStatus, String newStatus) {
    final labels = {
      'pending': 'Menunggu Pembayaran',
      'waiting_confirmation': 'Menunggu Konfirmasi',
      'processing': 'Diproses',
      'shipped': 'Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Status: ${labels[newStatus] ?? newStatus}')),
        ],
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _loadOrder() async {
    _order = null;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/orders/${widget.orderId}');
      if (!mounted) return;
      final loaded = Order.fromJson(res as Map<String, dynamic>, detail: true);
      setState(() {
        _order = loaded;
        _lastStatus = loaded.status;
        _bankAccounts = (res['bank_accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
        _error = 'Gagal memuat pesanan: $e';
        _loading = false;
      });
    }
  }

  Future<void> _uploadPayment() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      await _api.uploadFile('/orders/${widget.orderId}/payment-upload',
          field: 'payment_proof', file: File(file.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti bayar berhasil diupload')));
      _loadOrder();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmReceived() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: const Text('Apakah Anda yakin pesanan sudah diterima dengan selamat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Konfirmasi')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.post('/orders/${widget.orderId}/confirm-received');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pesanan telah diterima')));
      _loadOrder();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.post('/orders/${widget.orderId}/cancel');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pesanan dibatalkan')));
      _loadOrder();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showReviewDialog() async {
    int rating = 5;
    final reviewC = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Beri Ulasan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rating:'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    icon: Icon(star <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 36),
                    onPressed: () => setDialogState(() => rating = star),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewC,
                decoration: const InputDecoration(
                  hintText: 'Komentar (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await _api.post('/orders/${widget.orderId}/review', body: {
        'rating': rating,
        'review': reviewC.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool _canReview() {
    if (_order == null) return false;
    return _order!.status == 'completed';
  }

  bool _canReturn() {
    if (_order == null) return false;
    if (!['shipped', 'completed'].contains(_order!.status)) return false;
    final hasPendingReturn = (_order!.returns ?? []).any(
        (r) => ['pending', 'approved'].contains(r['status'] as String?));
    return !hasPendingReturn;
  }

  bool _canCancel() {
    if (_order == null) return false;
    return ['pending', 'waiting_confirmation', 'processing']
        .contains(_order!.status);
  }

  bool _canUploadPayment() {
    return _order?.status == 'pending' && _order?.paymentMethod == 'bank_transfer';
  }

  bool _canConfirmReceived() {
    return _order?.status == 'shipped';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'waiting_confirmation': return Colors.blue;
      case 'processing': return Colors.cyan;
      case 'shipped': return Colors.indigo;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Pesanan tidak ditemukan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadOrder,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Pesanan tidak ditemukan'))
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 12),
                            _buildStatusTimeline(),
                            const SizedBox(height: 12),
                            _buildProducts(),
                            const SizedBox(height: 12),
                            _buildPriceSummary(),
                            if (_order!.courier != null) ...[
                              const SizedBox(height: 12),
                              _buildCourierInfo(),
                            ],
                            if (_order!.shippingAddress != null) ...[
                              const SizedBox(height: 12),
                              _buildShippingAddress(),
                            ],
                            if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildNotes(),
                            ],
                            if (_order!.paymentProof != null) ...[
                              const SizedBox(height: 12),
                              _buildPaymentProof(),
                            ],
                            if (_bankAccounts.isNotEmpty && _canUploadPayment()) ...[
                              const SizedBox(height: 12),
                              _buildBankAccounts(),
                            ],
                            if (_canUploadPayment()) ...[
                              const SizedBox(height: 12),
                              _buildUploadPaymentButton(),
                            ],
                            if (_canConfirmReceived()) ...[
                              const SizedBox(height: 12),
                              _buildConfirmReceivedButton(),
                            ],
                            if (_canReview()) ...[
                              const SizedBox(height: 8),
                              _buildReviewButton(),
                            ],
                            if (_canReturn()) ...[
                              const SizedBox(height: 8),
                              _buildReturnButton(),
                            ],
                            if (_canCancel()) ...[
                              const SizedBox(height: 8),
                              _buildCancelButton(),
                            ],
                            if (_order!.returns != null && _order!.returns!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildReturnStatus(),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(_order!.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(_order!.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_order!.statusLabel,
                      style: TextStyle(color: _statusColor(_order!.status), fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dibuat: ${_formatDate(_order!.createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            if (_order!.paymentMethodLabel != null) ...[
              const SizedBox(height: 4),
              Text('Pembayaran: ${_order!.paymentMethodLabel}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
            if (_order!.pointsEarned != null && _order!.pointsEarned! > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('+${_order!.pointsEarned} poin',
                      style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final currentIdx = _statusSteps.indexOf(_order!.status);
    if (currentIdx == -1) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Pesanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(_statusSteps.length - 1, (i) {
              final step = _statusSteps[i + 1];
              final done = currentIdx >= (i + 1);
              final current = currentIdx == (i + 1);
              return _buildTimelineItem(
                label: _stepLabels[step]!,
                done: done,
                current: current,
                isLast: i == _statusSteps.length - 2,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required bool done,
    required bool current,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: done ? Colors.green : (current ? AppColors.primary : Colors.grey[300]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : (current ? Icons.hourglass_bottom : Icons.access_time),
                size: 12, color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2, height: 30,
                color: done ? Colors.green[200] : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 20),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: done || current ? FontWeight.w600 : FontWeight.normal,
                color: done || current ? Colors.black87 : Colors.grey[400],
              )),
        ),
      ],
    );
  }

  Widget _buildProducts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Item Pesanan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_order!.itemCount} barang',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 12),
            ...(_order!.items ?? []).map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.productImage != null
                            ? CachedNetworkImage(
                                imageUrl: item.productImage!, width: 56, height: 56, fit: BoxFit.cover)
                            : Container(width: 56, height: 56, color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName ?? 'Produk',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${item.quantity}x ${formatPrice(item.price)}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formatPrice(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal Produk', formatPrice(_order!.totalAmount)),
            if (_order!.shippingCost > 0) _row('Ongkos Kirim', formatPrice(_order!.shippingCost)),
            if (_order!.discountAmount > 0)
              _row('Diskon', '-${formatPrice(_order!.discountAmount)}', color: Colors.green),
            if (_order!.pointsDiscount > 0)
              _row('Poin', '-${formatPrice(_order!.pointsDiscount)}', color: Colors.green),
            const Divider(),
            _row('Total Pesanan', _order!.grandTotalFormatted,
                color: AppColors.primary, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Pengiriman',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _row('Kurir', _order!.courier ?? '-'),
            if (_order!.courierService != null)
              _row('Layanan', _order!.courierService!),
            _row('Ongkos Kirim', formatPrice(_order!.shippingCost)),
            if (_order!.trackingNumber != null) ...[
              const Divider(height: 16),
              _row('No. Resi', _order!.trackingNumber!, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Alamat Pengiriman',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_order!.shippingAddress!,
                style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Catatan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_order!.notes!,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProof() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, size: 18, color: Colors.green),
                const SizedBox(width: 6),
                const Text('Bukti Pembayaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _order!.paymentProof!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccounts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Rekening Tujuan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ..._bankAccounts.map((bank) {
              final name = bank['bank_name'] as String? ?? '';
              final number = bank['account_number'] as String? ?? '';
              final holder = bank['account_holder'] as String? ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(number,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('a.n. $holder',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        // In real app: Clipboard.setData(ClipboardData(text: number));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No. rekening $name: $number')));
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _uploading ? null : _uploadPayment,
        icon: _uploading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.upload_file),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        label: const Text('Upload Bukti Bayar', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildConfirmReceivedButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _confirmReceived,
        icon: const Icon(Icons.check_circle),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        label: const Text('Konfirmasi Pesanan Diterima', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildReviewButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _showReviewDialog,
        icon: const Icon(Icons.star_border),
        label: const Text('Beri Ulasan', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildReturnButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReturnScreen(
                orderId: widget.orderId,
                orderItems: _order!.items ?? [],
              ),
            ),
          ).then((_) => _loadOrder());
        },
        icon: const Icon(Icons.assignment_return),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        label: const Text('Ajukan Retur', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: _cancelOrder,
        icon: const Icon(Icons.cancel_outlined),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        label: const Text('Batalkan Pesanan', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildReturnStatus() {
    final activeReturn = (_order!.returns ?? []).where(
        (r) => ['pending', 'approved'].contains(r['status'])).toList();
    if (activeReturn.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.undo, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                const Text('Status Retur',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...activeReturn.map((r) {
              final status = r['status'] as String? ?? '';
              final label = r['status_label'] as String? ?? status;
              final reason = r['reason'] as String?;
              final isApproved = status == 'approved';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle : Icons.hourglass_bottom,
                          size: 16,
                          color: isApproved ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isApproved ? Colors.green[700] : Colors.orange[700],
                            )),
                      ],
                    ),
                    if (reason != null) ...[
                      const SizedBox(height: 4),
                      Text('Alasan: $reason',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
                fontSize: bold ? 15 : 13,
              )),
        ],
      ),
    );
  }
}
