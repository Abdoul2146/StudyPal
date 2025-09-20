import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../services/ai_tutor_service.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:agent36/screens/AITutor/saved_conversations.dart';

class AiTutorPage extends StatefulWidget {
  const AiTutorPage({super.key});

  @override
  State<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends State<AiTutorPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'model',
      'text':
          "Hi there! I'm your AI tutor. Ask me anything about your subjects, and I'll do my best to help you understand.",
      'avatar': 'assets/images/avatarbot.png',
    },
  ];
  final AiTutorService _aiTutor = AiTutorService(' '); // Replace with your key
  bool _loading = false;
  bool _useContext = false;

  Future<void> _saveConversation() async {
    final prefs = await SharedPreferences.getInstance();
    // Save only role and text for each message
    final conversation =
        _messages.map((m) => {'role': m['role'], 'text': m['text']}).toList();
    // You can use a timestamp as a key for multiple saves
    final key = 'ai_conversation_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(key, jsonEncode(conversation));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation saved!')));
    }
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': question,
        'avatar': 'assets/images/avatar.png',
      });
      _loading = true;
      _controller.clear();
    });

    try {
      // Prepare context for Gemini
      List<Map<String, String>> contextMessages = [];

      if (_useContext && _messages.length > 1) {
        // Add last AI response and current question if context is enabled
        final lastAiMessage =
            _messages.where((m) => m['role'] == 'model').lastOrNull;

        if (lastAiMessage != null) {
          contextMessages.add({
            'role': 'model',
            'text': lastAiMessage['text']!,
          });
        }
      }

      // Add current question
      contextMessages.add({'role': 'user', 'text': question});

      final answer = await _aiTutor.ask(contextMessages);

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'model',
            'text': answer,
            'avatar': 'assets/images/avatarbot.png',
          });
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _messages.add({
            'role': 'model',
            'text': 'Sorry, I encountered an error: ${e.toString()}',
            'avatar': 'assets/images/avatarbot.png',
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            tooltip: 'Saved Conversations',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SavedConversationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return ChatBubble(
                  isUser: msg['role'] == 'user',
                  message: msg['text'] ?? '',
                  avatar: msg['avatar'] ?? 'assets/images/avatarbot.png',
                );
              },
            ),
          ),
          // Action buttons ("Save" and "More Examples") - unchanged
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.bookmark_outline,
                          color: Colors.black54,
                        ),
                        onPressed: _saveConversation,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Save', style: TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 16),
                // Container(
                //   height: 48,
                //   width: 48,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFF0F0F0),
                //     borderRadius: BorderRadius.circular(24),
                //   ),
                //   //   child: IconButton(
                //   //     icon: const Icon(Icons.add, color: Colors.black54),
                //   //     onPressed: () {},
                //   //   ),
                //   // ),
                //   // const Text(
                //   //   'More Examples',
                //   //   style: TextStyle(color: Colors.black54),
                // ),
                // const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Relate to previous messages'),
                  value: _useContext,
                  onChanged: (val) {
                    setState(() {
                      _useContext = val;
                    });
                  },
                ),
              ],
            ),
          ),
          // Chat input field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: const AssetImage('assets/images/avatar.png'),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _loading ? null : _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _loading ? null : _sendMessage,
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// MARK: - Chat Bubble Widget

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String message;
  final String avatar;

  const ChatBubble({
    super.key,
    required this.isUser,
    required this.message,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 18,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF3B9FF4) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                  bottomRight:
                      isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                ),
              ),
              child:
                  isUser
                      ? Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                      : MarkdownBody(
                        data: message,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          h1: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          listBullet: const TextStyle(fontSize: 16),
                        ),
                        extensionSet: md.ExtensionSet(
                          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                          <md.InlineSyntax>[
                            md.EmojiSyntax(),
                            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                          ],
                        ),
                      ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 18,
              backgroundColor: Colors.grey[200],
            ),
          ],
        ],
      ),
    );
  }
}
