import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ReturnScreen extends StatefulWidget {
  final int orderId;

  const ReturnScreen({super.key, required this.orderId});

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

  @override
  void dispose() {
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _images.add(File(file.path)));
    }
  }

  Future<void> _submit() async {
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

    setState(() => _submitting = true);
    try {
      final fields = <String, String>{
        'reason': _reason,
        'description': _descC.text.trim(),
      };
      // Send each image as a separate field with the same name
      // The backend expects 'images' as an array of files
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
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: _submitting ? null : _submit,
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
