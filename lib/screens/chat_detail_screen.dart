import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _messageC = TextEditingController();
  final ScrollController _scrollC = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String _status = 'open';
  String _subject = '';
  String? _lastMessageTime;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getChatMessages(widget.conversationId);

      final conv = res['conversation'] as Map<String, dynamic>?;
      _status = conv?['status'] as String? ?? 'open';
      _subject = conv?['subject'] as String? ?? '';

      final msgs = (res['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      if (msgs.isNotEmpty) {
        _lastMessageTime = msgs.last['created_at'] as String?;
      }
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res = await _api.pollChatMessages(widget.conversationId,
            since: _lastMessageTime);
        if (!mounted) return;
        final newMsgs =
            (res['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (newMsgs.isNotEmpty) {
          setState(() {
            _messages.addAll(newMsgs);
            _lastMessageTime = newMsgs.last['created_at'] as String?;
          });
          _scrollToBottom();
        }
        if (res['status'] != null) {
          setState(() => _status = res['status'] as String);
        }
      } catch (_) {}
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageC.text.trim();
    if (text.isEmpty) return;

    _messageC.clear();
    try {
      final res = await _api.sendChatMessage(widget.conversationId, text);
      final msg = res['message'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (msg != null) {
        setState(() => _messages.add(msg));
        _lastMessageTime = msg['created_at'] as String?;
        _scrollToBottom();
      } else {
        _loadMessages();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isOpen => _status == 'open' || _status == 'aktif';

  String _senderName(Map<String, dynamic> msg) {
    final user = msg['user'] as Map<String, dynamic>?;
    if (user != null && user['name'] != null) return user['name'] as String;
    return msg['is_admin'] == true ? 'Admin' : 'Anda';
  }

  @override
  Widget build(BuildContext context) {
    final title = _subject.isNotEmpty
        ? _subject
        : 'Chat #${widget.conversationId}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              _isOpen ? 'Terbuka' : 'Ditutup',
              style: TextStyle(
                fontSize: 12,
                color: _isOpen ? Colors.green[300] : Colors.red[300],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text('Belum ada pesan',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          controller: _scrollC,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isAdmin =
                                msg['is_admin'] == true || msg['is_admin'] == 1;
                            final time =
                                msg['created_at'] as String? ?? '';
                            final text =
                                msg['message'] as String? ?? '';
                            final name = _senderName(msg);

                            return Column(
                              crossAxisAlignment: isAdmin
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isAdmin
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? Colors.blueGrey[50]
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: Radius.circular(
                                                isAdmin ? 12 : 4),
                                            bottomRight: Radius.circular(
                                                isAdmin ? 4 : 12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              text,
                                              style: const TextStyle(
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              time,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageC,
                            enabled: _isOpen,
                            decoration: InputDecoration(
                              hintText: _isOpen
                                  ? 'Ketik pesan...'
                                  : 'Percakapan ditutup',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: _isOpen ? (_) => _sendMessage() : null,
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isOpen ? _sendMessage : null,
                          icon: const Icon(Icons.send),
                          color: _isOpen
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
