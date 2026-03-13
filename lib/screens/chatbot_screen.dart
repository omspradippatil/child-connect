import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';
import '../utils/app_data.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _childrenData = [];
  List<Map<String, dynamic>> _programsData = [];
  List<Map<String, dynamic>> _adoptionStepsData = [];
  List<Map<String, dynamic>> _missionData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            'Hello! I am the Child Connect assistant. Ask me about adoption steps, available children, programs, support services, mentoring, or contact guidance.',
        isUser: false,
      ),
    );
    _loadKnowledgeBase();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadKnowledgeBase() async {
    // Build local fallback knowledge from bundled app data.
    _childrenData = AppData.children
        .map(
          (child) => {
            'name': child.name,
            'age': child.age,
            'location': child.location,
            'story': child.story,
            'interests': child.interests,
          },
        )
        .toList();

    _programsData = AppData.programs
        .map((program) => Map<String, dynamic>.from(program))
        .toList();
    _adoptionStepsData = AppData.adoptionSteps
        .map((step) => Map<String, dynamic>.from(step))
        .toList();
    _missionData = AppData.missionPoints
        .map((point) => Map<String, dynamic>.from(point))
        .toList();

    // If online, refresh with the latest app backend data.
    try {
      final childrenResponse = await Supabase.instance.client.rpc(
        'app_get_public_children',
      );
      final childrenRows = childrenResponse as List? ?? const [];
      if (childrenRows.isNotEmpty) {
        _childrenData = childrenRows
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList();
      }

      final programsResponse = await Supabase.instance.client.rpc(
        'app_get_public_programs',
      );
      final programRows = programsResponse as List? ?? const [];
      if (programRows.isNotEmpty) {
        _programsData = programRows
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList();
      }
    } catch (_) {
      // Keep fallback data silently when backend is unavailable.
    }
  }

  Future<void> _refreshAssistant() async {
    await _loadKnowledgeBase();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assistant data refreshed.')));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      await Future.delayed(const Duration(milliseconds: 450));
      final botResponse = await _resolveResponse(text);

      setState(() {
        _messages.add(ChatMessage(text: botResponse, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'I could not process that right now. Please try asking about adoption, children, programs, or contact support.',
            isUser: false,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _resolveResponse(String rawQuery) async {
    final localResponse = _buildLocalResponse(rawQuery);
    if (localResponse != null) {
      return localResponse;
    }

    final geminiResponse = await GeminiService.generateSupportResponse(
      userMessage: rawQuery,
      children: _childrenData,
      programs: _programsData,
      adoptionSteps: _adoptionStepsData,
      missionPoints: _missionData,
    );

    if (geminiResponse != null && geminiResponse.trim().isNotEmpty) {
      return geminiResponse.trim();
    }

    return 'I could not find a direct answer in the app data right now. Try asking about adoption, children, programs, mentoring, or contact support.';
  }

  String? _buildLocalResponse(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    bool hasWord(String word) => query.contains(word);

    if (hasWord('adopt') || hasWord('adoption') || hasWord('process')) {
      final steps = _adoptionStepsData
          .take(4)
          .map(
            (step) =>
                '${step['step']}. ${step['title']}: ${step['description']}',
          )
          .join('\n');
      return 'Adoption process in Child Connect:\n$steps\n\nYou can open Adopt tab and submit the Adoption Application Form to begin.';
    }

    if (hasWord('child') || hasWord('children') || hasWord('kid')) {
      if (_childrenData.isEmpty) {
        return 'No child profiles are available right now. Please check again soon.';
      }

      final shortlist = _childrenData
          .take(3)
          .map((child) {
            final name = (child['name'] ?? '').toString();
            final age = (child['age'] ?? '').toString();
            final location = (child['location'] ?? '').toString();
            final interests = (child['interests'] ?? '').toString();
            return interests.isEmpty
                ? '$name ($age) - $location'
                : '$name ($age) - $location | Activities: $interests';
          })
          .join('\n');

      return 'Here are some children from the app:\n$shortlist\n\nOpen the Adopt section to view full profiles and continue.';
    }

    if (hasWord('program') || hasWord('activity') || hasWord('activities')) {
      final list = _programsData
          .take(4)
          .map((program) => '- ${program['title']}')
          .join('\n');
      return 'Current Child Connect programs include:\n$list\n\nYou can open Programs for complete details.';
    }

    if (hasWord('mentor') || hasWord('volunteer')) {
      return 'You can apply as a mentor from the Mentor section. Share your skills, availability, and motivation, and the team will review your application.';
    }

    if (hasWord('contact') || hasWord('help') || hasWord('support')) {
      final supports = _missionData
          .take(3)
          .map((point) => '- ${point['title']}')
          .join('\n');
      return 'Support options in the app:\n$supports\n\nFor direct help, use Contact to send a message or request an appointment call.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Connect Assistant'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF77F45),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _refreshAssistant,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh assistant data',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFF77F45) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : null,
            bottomLeft: !message.isUser ? const Radius.circular(0) : null,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask about adoption, children, programs...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF77F45),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
