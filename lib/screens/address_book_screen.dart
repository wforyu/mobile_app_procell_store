import 'package:flutter/material.dart';
import '../helpers/theme.dart';
import '../services/api_service.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    try {
      _addresses = await _api.getAddresses();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addOrEdit({Map<String, dynamic>? address}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AddressFormScreen(address: address)),
    );
    if (result == true) _loadAddresses();
  }

  Future<void> _delete(Map<String, dynamic> address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteAddress(address['id'] as int);
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _setDefault(Map<String, dynamic> address) async {
    try {
      await _api.setDefaultAddress(address['id'] as int);
      _loadAddresses();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alamat Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('Belum ada alamat tersimpan', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Tambah alamat untuk mempermudah checkout', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (_, i) => _addressCard(_addresses[i]),
                  ),
                ),
    );
  }

  Widget _addressCard(Map<String, dynamic> addr) {
    final isDefault = addr['is_default'] == true;
    final label = addr['label'] ?? 'Rumah';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDefault ? AppColors.primaryLight : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDefault ? AppColors.primary : Colors.grey[700],
                    ),
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Utama', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green)),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    if (!isDefault) const PopupMenuItem(value: 'default', child: Text('Jadikan Utama')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (v) {
                    if (v == 'default') _setDefault(addr);
                    if (v == 'edit') _addOrEdit(address: addr);
                    if (v == 'delete') _delete(addr);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(addr['recipient_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(addr['recipient_phone'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text(
              _formatAddress(addr),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = <String>[
      addr['address_line'] ?? '',
      if (addr['subdistrict_name'] != null) 'Kel. ${addr['subdistrict_name']}',
      if (addr['district_name'] != null) 'Kec. ${addr['district_name']}',
      addr['city_name'] ?? '',
      addr['province_name'] ?? '',
      addr['postal_code'] ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}

// ─── Form Tambah/Edit Alamat ───

class _AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? address;
  const _AddressFormScreen({this.address});

  @override
  State<_AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<_AddressFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelC;
  late TextEditingController _nameC;
  late TextEditingController _phoneC;
  late TextEditingController _addressC;
  late TextEditingController _postalC;

  int? _cityId;
  String? _cityName;
  bool _isDefault = false;
  bool _saving = false;

  List<dynamic> _cities = [];

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelC = TextEditingController(text: a?['label'] ?? 'Rumah');
    _nameC = TextEditingController(text: a?['recipient_name'] ?? '');
    _phoneC = TextEditingController(text: a?['recipient_phone'] ?? '');
    _addressC = TextEditingController(text: a?['address_line'] ?? '');
    _postalC = TextEditingController(text: a?['postal_code'] ?? '');
    _cityId = a?['city_id'];
    _cityName = a?['city_name'];
    _isDefault = a?['is_default'] ?? false;
    _loadCities();
  }

  @override
  void dispose() {
    _labelC.dispose();
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _postalC.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final res = await _api.get('/cities');
      if (!mounted) return;
      setState(() {
        _cities = (res['cities'] as List?) ?? [];
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kota tujuan')));
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'label': _labelC.text.trim().isEmpty ? 'Rumah' : _labelC.text.trim(),
        'recipient_name': _nameC.text.trim(),
        'recipient_phone': _phoneC.text.trim(),
        'address_line': _addressC.text.trim(),
        'city_id': _cityId,
        'city_name': _cityName,
        'postal_code': _postalC.text.trim().isEmpty ? null : _postalC.text.trim(),
        'is_default': _isDefault,
      };

      if (_isEditing) {
        await _api.updateAddress(widget.address!['id'] as int, data);
      } else {
        await _api.addAddress(data);
      }

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alamat' : 'Tambah Alamat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              const Text('Label Alamat', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _labelChip('Rumah'),
                  const SizedBox(width: 8),
                  _labelChip('Kantor'),
                  const SizedBox(width: 8),
                  _labelChip('Lainnya'),
                ],
              ),
              const SizedBox(height: 16),

              // Nama Penerima
              const Text('Nama Penerima', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(hintText: 'Nama lengkap penerima', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Telepon
              const Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '08xxxxxxxxxx', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Alamat Lengkap
              const Text('Alamat Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressC,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nama jalan, No. Rumah, RT/RW, Patokan/Landmark',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Kota
              const Text('Kota/Kabupaten', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
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
                          _cityName ?? 'Pilih kota',
                          style: TextStyle(color: _cityName != null ? Colors.black : Colors.grey, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Kode Pos
              const Text('Kode Pos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _postalC,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: const InputDecoration(hintText: '5 digit', border: OutlineInputBorder(), isDense: true, counterText: ''),
              ),
              const SizedBox(height: 12),

              // Default
              SwitchListTile(
                title: const Text('Jadikan Alamat Utama'),
                subtitle: const Text('Alamat ini otomatis dipilih saat checkout', style: TextStyle(fontSize: 12)),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // Simpan
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
                      : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Alamat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelChip(String label) {
    final selected = _labelC.text == label;
    return GestureDetector(
      onTap: () => setState(() => _labelC.text = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 13)),
      ),
    );
  }

  Future<void> _showCityPicker() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CityPickerDialog(cities: _cities, selectedCityId: _cityId),
    );
    if (selected != null && mounted) {
      setState(() {
        _cityId = selected['id'] as int;
        _cityName = selected['name'] as String;
      });
    }
  }
}

// ─── City Picker Dialog ───

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
              decoration: const InputDecoration(hintText: 'Cari kota...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true),
              onChanged: (v) {
                setState(() {
                  _filtered = widget.cities.where((c) {
                    final name = (c['name'] as String?)?.toLowerCase() ?? '';
                    final province = (c['province'] as String?)?.toLowerCase() ?? '';
                    return name.contains(v.toLowerCase()) || province.contains(v.toLowerCase());
                  }).toList();
                });
              },
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
                    onTap: () => Navigator.pop(context, {'id': c['id'] as int, 'name': c['name'] as String}),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      ],
    );
  }
}
