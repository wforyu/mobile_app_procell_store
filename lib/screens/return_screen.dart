import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../helpers/price_formatter.dart';
import '../helpers/theme.dart';

class ReturnScreen extends StatefulWidget {
  final int orderId;
  final List<OrderItem> orderItems;

  const ReturnScreen({super.key, required this.orderId, required this.orderItems});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _descC = TextEditingController();
  String _reason = 'defective';
  final List<File> _images = [];
  bool _submitting = false;

  late Map<int, bool> _selected;
  late Map<int, int> _quantities;

  @override
  void initState() {
    super.initState();
    _selected = {for (var item in widget.orderItems) item.id: false};
    _quantities = {for (var item in widget.orderItems) item.id: item.quantity};
  }

  @override
  void dispose() {
    _descC.dispose();
    super.dispose();
  }

  bool get _hasSelection => _selected.values.any((v) => v);

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _images.add(File(file.path)));
    }
  }

  Future<void> _submit() async {
    if (!_hasSelection) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang untuk diretur')));
      return;
    }
    if (_descC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deskripsi wajib diisi')));
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload minimal 1 foto')));
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final item in widget.orderItems) {
      if (_selected[item.id] == true) {
        items.add({
          'order_item_id': item.id,
          'quantity': _quantities[item.id] ?? 1,
        });
      }
    }

    setState(() => _submitting = true);
    try {
      final fields = <String, String>{
        'reason': _reason,
        'description': _descC.text.trim(),
        'items': items.toString(),
      };
      await _api.uploadFiles('/orders/${widget.orderId}/return',
          field: 'images[]', files: _images, fields: fields);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Retur berhasil diajukan')));
      Navigator.pop(context);
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
    final reasons = {
      'defective': 'Produk Cacat',
      'wrong_item': 'Barang Tidak Sesuai',
      'not_as_described': 'Tidak Sesuai Deskripsi',
      'damaged': 'Rusak Saat Kirim',
      'other': 'Lainnya',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Retur'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Centang barang yang ingin diretur', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            ...widget.orderItems.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selected[item.id],
                      onChanged: (v) => setState(() => _selected[item.id] = v ?? false),
                      activeColor: AppColors.primary,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item.productImage != null
                          ? Image.network(item.productImage!, width: 48, height: 48, fit: BoxFit.cover)
                          : Container(width: 48, height: 48, color: Colors.grey[200], child: const Icon(Icons.image, size: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName ?? 'Produk',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(formatPrice(item.price),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_selected[item.id] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: (_quantities[item.id] ?? 1) > 1
                                ? () => setState(() => _quantities[item.id] = (_quantities[item.id] ?? 1) - 1)
                                : null,
                          ),
                          Text('${_quantities[item.id] ?? 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: (_quantities[item.id] ?? 1) < item.quantity
                                ? () => setState(() => _quantities[item.id] = (_quantities[item.id] ?? 1) + 1)
                                : null,
                          ),
                        ],
                      )
                    else
                      Text('x${item.quantity}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Alasan Retur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: reasons.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v!),
            ),
            const SizedBox(height: 16),
            const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descC,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Jelaskan masalahnya...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Foto Bukti (min 1, maks 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map((f) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.remove(f)),
                            child: Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
                if (_images.length < 5)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.grey),
                          Text('Tambah', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_submitting || !_hasSelection) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ajukan Retur', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
