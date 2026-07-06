import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    _order = null;
    setState(() => _loading = true);
    try {
      final res = await _api.get('/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = Order.fromJson(res, detail: true);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    if (_order!.status != 'completed') return false;
    return true;
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_confirmation':
        return Colors.blue;
      case 'processing':
        return Colors.cyan;
      case 'shipped':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Pesanan tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_order!.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(_order!.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(_order!.statusLabel,
                                          style: TextStyle(color: _statusColor(_order!.status))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_order!.createdAt,
                                    style: TextStyle(color: Colors.grey[500])),
                                if (_order!.paymentMethodLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Pembayaran: ${_order!.paymentMethodLabel}'),
                                ],
                                if (_order!.courier != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Kurir: ${_order!.courier} ${_order!.courierService ?? ''}'),
                                ],
                                if (_order!.trackingNumber != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Resi: ${_order!.trackingNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                                if (_order!.shippingAddress != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Alamat: ${_order!.shippingAddress}'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_order!.items ?? []).map((item) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
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
                                              style: const TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text('${item.quantity}x Rp ${item.price}'),
                                        ],
                                      ),
                                    ),
                                    Text('Rp ${item.subtotal}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _row('Subtotal', 'Rp ${_order!.totalAmount}'),
                                _row('Ongkir', 'Rp ${_order!.shippingCost}'),
                                if (_order!.discountAmount > 0)
                                  _row('Diskon', '-Rp ${_order!.discountAmount}', color: Colors.green),
                                const Divider(),
                                _row('Total', _order!.grandTotalFormatted, color: const Color(0xFF1A73E8), bold: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_order!.status == 'pending')
                          SizedBox(
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
                          ),
                        if (_order!.status == 'shipped')
                          SizedBox(
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
                          ),
                        if (_canReview())
                          const SizedBox(height: 8),
                        if (_canReview())
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _showReviewDialog,
                              icon: const Icon(Icons.star_border),
                              label: const Text('Beri Ulasan', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        if (_canReturn())
                          const SizedBox(height: 8),
                        if (_canReturn())
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReturnScreen(orderId: widget.orderId),
                                  ),
                                ).then((_) => _loadOrder());
                              },
                              icon: const Icon(Icons.assignment_return),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              label: const Text('Ajukan Retur', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        if (_canCancel())
                          const SizedBox(height: 8),
                        if (_canCancel())
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton.icon(
                              onPressed: _cancelOrder,
                              icon: const Icon(Icons.cancel_outlined),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              label: const Text('Batalkan Pesanan', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
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
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
              )),
        ],
      ),
    );
  }
}
