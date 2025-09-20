import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markdown/markdown.dart' as md;

class SavedConversationsPage extends StatefulWidget {
  const SavedConversationsPage({super.key});

  @override
  State<SavedConversationsPage> createState() => _SavedConversationsPageState();
}

class _SavedConversationsPageState extends State<SavedConversationsPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('ai_conversation_'));
    List<Map<String, dynamic>> loaded = [];
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        loaded.add({
          'key': key,
          'messages':
              decoded
                  .map((e) => {'role': e['role'], 'text': e['text']})
                  .toList(),
        });
      }
    }
    setState(() {
      _conversations = loaded.reversed.toList(); // newest first
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Conversations'),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? const Center(child: Text('No saved conversations yet.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _conversations.length,
                itemBuilder: (context, idx) {
                  final convo = _conversations[idx];
                  final userMsg = (convo['messages'] as List).firstWhere(
                    (m) => m['role'] == 'user',
                    orElse: () => <String, dynamic>{},
                  );
                  final titleText =
                      userMsg.isNotEmpty &&
                              (userMsg['text'] as String).trim().isNotEmpty
                          ? (userMsg['text'] as String).trim().split('\n').first
                          : 'Conversation ${_conversations.length - idx}';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: ExpansionTile(
                      title: Text(
                        titleText.length > 40
                            ? '${titleText.substring(0, 40)}...'
                            : titleText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      children: [
                        ...List.generate((convo['messages'] as List).length, (
                          msgIdx,
                        ) {
                          final msg = convo['messages'][msgIdx];
                          final isUser = msg['role'] == 'user';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            child: Align(
                              alignment:
                                  isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isUser
                                          ? const Color(0xFF3B9FF4)
                                          : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child:
                                    isUser
                                        ? Text(
                                          msg['text'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        )
                                        : MarkdownBody(
                                          data: msg['text'] ?? '',
                                          styleSheet: MarkdownStyleSheet(
                                            p: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            strong: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
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
                                            listBullet: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          extensionSet: md.ExtensionSet(
                                            md
                                                .ExtensionSet
                                                .gitHubFlavored
                                                .blockSyntaxes,
                                            <md.InlineSyntax>[
                                              md.EmojiSyntax(),
                                              ...md
                                                  .ExtensionSet
                                                  .gitHubFlavored
                                                  .inlineSyntaxes,
                                            ],
                                          ),
                                        ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
