import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({super.key});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _threadId;
  String? _error;
  List<Map<String, dynamic>> _messages = const [];

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapChat() async {
    final user = AuthService.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Please sign in first.';
        _loading = false;
      });
      return;
    }

    try {
      final threadResponse = await Supabase.instance.client.rpc(
        'app_user_get_or_create_chat_thread',
        params: {'p_session_token': user.sessionToken},
      );

      final threadMap = _asMap(threadResponse);
      final threadId = (threadMap?['id'] ?? '').toString();
      if (threadId.isEmpty) {
        throw Exception('Unable to create mentor chat thread.');
      }

      final messagesResponse = await Supabase.instance.client.rpc(
        'app_user_list_chat_messages',
        params: {'p_session_token': user.sessionToken, 'p_thread_id': threadId},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _threadId = threadId;
        _messages = _asListOfMaps(messagesResponse);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    final user = AuthService.currentUser;
    final threadId = _threadId;
    if (user == null || threadId == null || threadId.isEmpty) {
      return;
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'app_user_list_chat_messages',
        params: {'p_session_token': user.sessionToken, 'p_thread_id': threadId},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = _asListOfMaps(response);
      });
    } catch (_) {
      // Keep previous messages when refresh fails.
    }
  }

  Future<void> _sendMessage() async {
    final user = AuthService.currentUser;
    final threadId = _threadId;
    final body = _messageCtrl.text.trim();
    if (user == null || threadId == null || body.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'app_user_send_chat_message',
        params: {
          'p_session_token': user.sessionToken,
          'p_thread_id': threadId,
          'p_message_text': body,
        },
      );

      _messageCtrl.clear();
      await _refreshMessages();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Support Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFEEF0),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFC62828)),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final row = _messages[index];
                        final role = (row['sender_role'] ?? 'user').toString();
                        final isMine = role == 'user';
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? const Color(0xFFF77F45)
                                  : const Color(0xFFE9EEF6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (row['message_text'] ?? '').toString(),
                                  style: TextStyle(
                                    color: isMine
                                        ? Colors.white
                                        : const Color(0xFF1F3A56),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role == 'mentor' || role == 'admin'
                                      ? 'Mentor Team'
                                      : 'You',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMine
                                        ? Colors.white70
                                        : const Color(0xFF5F6C7C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Write a message for mentors...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _sending ? null : _sendMessage,
                          child: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
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
