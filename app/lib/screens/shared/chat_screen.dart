import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';

/// Discussion client ⇄ livreur pour une commande.
/// Les nouveaux messages sont récupérés toutes les 5 secondes tant que l'écran est ouvert.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.orderRef, required this.myRole, required this.title});
  final String orderRef, myRole, title;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  late final ApiClient _api;
  Timer? _timer;
  bool _loaded = false, _sending = false, _closed = false, _loading = false;
  String? _error;

  String get _path => '/api/orders/${Uri.encodeComponent(widget.orderRef)}/messages';

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final after = _messages.isEmpty ? 0 : _messages.last.id;
      final d = await _api.get('$_path?after=$after') as Map<String, dynamic>;
      final fresh = (d['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .where((m) => _messages.isEmpty || m.id > _messages.last.id)
          .toList();
      if (!mounted) return;
      setState(() {
        _messages.addAll(fresh);
        _closed = d['closed'] == true;
        _error = null;
        _loaded = true;
      });
      if (fresh.isNotEmpty) _toBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loaded = true;
        });
      }
    }
    _loading = false;
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.post(_path, {'body': body});
      _text.clear();
      await _load();
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => _sending = false);
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderRole == widget.myRole;
    final who = m.senderName ?? (m.senderRole == 'client' ? 'Client' : 'Livreur');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: mine ? Brand.goldGradient : null,
          color: mine ? null : Brand.card,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: Brand.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Text(who, style: const TextStyle(color: Brand.gold, fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(m.body, style: TextStyle(color: mine ? Brand.ink : null, fontSize: 14.5)),
          const SizedBox(height: 3),
          Text('${two(m.time.hour)}:${two(m.time.minute)}', style: TextStyle(color: mine ? Brand.ink.withOpacity(0.6) : Brand.dim, fontSize: 10.5)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: Column(children: [
        Expanded(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? EmptyState(emoji: '💬', title: _error ?? 'Aucun message', subtitle: _error == null ? 'Écris le premier message.' : null)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _bubble(_messages[i]),
                    ),
        ),
        if (_error != null && _messages.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(_error!, style: const TextStyle(color: Brand.danger, fontSize: 12))),
        if (_closed)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Discussion fermée : la commande est terminée.', style: TextStyle(color: Brand.dim)),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Écris ton message…', counterText: ''),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Brand.gold, foregroundColor: Brand.ink),
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
