import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getChatConversations();
      if (!mounted) return;
      setState(() {
        _conversations = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showNewChatDialog() async {
    final subjectC = TextEditingController();
    final messageC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var sending = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pesan Baru'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: subjectC,
                    decoration: const InputDecoration(
                      labelText: 'Subjek (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageC,
                    decoration: const InputDecoration(
                      labelText: 'Pesan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 5000,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Pesan harus diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => sending = true);
                      try {
                        await _api.startChat(messageC.text.trim(),
                            subject: subjectC.text.trim().isEmpty
                                ? null
                                : subjectC.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } on ApiException catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.message)));
                        }
                        setDialogState(() => sending = false);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')));
                        }
                        setDialogState(() => sending = false);
                      }
                    },
              child: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kirim'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil dikirim')));
      _loadConversations();
    }
  }

  String _latestPreview(Map<String, dynamic> c) {
    final msg = c['latest_message'];
    if (msg is Map && msg['message'] != null) return msg['message'] as String;
    return '(tidak ada pesan)';
  }

  String _timestamp(Map<String, dynamic> c) {
    final msg = c['latest_message'];
    if (msg is Map && msg['created_at'] != null) return msg['created_at'] as String;
    return c['created_at'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada percakapan',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      final isOpen = c['status'] == 'open' || c['status'] == 'aktif';
                      final subject = c['subject'] as String?;
                      final displayTitle = subject != null && subject.isNotEmpty
                          ? subject
                          : 'Percakapan #${c['id']}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatDetailScreen(conversationId: c['id'] as int),
                            ),
                          ).then((_) => _loadConversations()),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(displayTitle,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isOpen ? Colors.green : Colors.red)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOpen ? 'Terbuka' : 'Ditutup',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isOpen ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _latestPreview(c),
                                  style: TextStyle(color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _timestamp(c),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
