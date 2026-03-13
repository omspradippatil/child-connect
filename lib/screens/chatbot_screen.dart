import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "Hello! I am your assistant. How can I help you find information regarding clauses, sections, or general legal queries?",
        isUser: false,
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _controller.clear();

    try {
      // NOTE: Here you will integrate your actual API logic.
      // We are pulling an API_KEY from your .env file inside the app.
      final apiKey = dotenv.env['API_KEY'] ?? 'YOUR_DEFAULT_API_KEY';
      assert(apiKey != 'YOUR_DEFAULT_API_KEY', 'Set API_KEY in your .env file (see .env.example)');
      
      // ----------- EXAMPLE API CALL (OpenAI / Any Generic Provider) -------------
      /*
      final response = await http.post(
        Uri.parse('https://api.your-provider.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
           "model": "your-ai-model",
           "messages": [
             {"role": "system", "content": "You are a legal assistant that helps explain clauses and sections."},
             {"role": "user", "content": text}
           ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String botResponse = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add(ChatMessage(text: botResponse, isUser: false));
        });
      } else {
         throw Exception("Failed to fetch data");
      }
      */
      // -------------------------------------------------------------------------
      
      // Simulating a network delay for the placeholder response 
      await Future.delayed(const Duration(seconds: 2));
      
      final botResponse = "This is a placeholder response. To test with real data, uncomment and configure the HTTP POST request using your real API endpoint and API Key in `chatbot_screen.dart`.";
      
      setState(() {
        _messages.add(ChatMessage(text: botResponse, isUser: false));
      });
      
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: Could not fetch response. Please try again.", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Scroll to bottom optionally
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Assistant Bot'),
        centerTitle: true,
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
                 child: CircularProgressIndicator(strokeWidth: 2)
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
          color: message.isUser ? Colors.indigoAccent : Colors.grey[200],
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
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask about clauses, sections...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                backgroundColor: Colors.indigoAccent,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
