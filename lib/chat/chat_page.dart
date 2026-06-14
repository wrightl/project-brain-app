// lib/pages/ai_chat_page.dart
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/widgets/chat/message_bubble.dart';
import 'package:projectbrain/widgets/chat/chat_input_field.dart';
import 'package:projectbrain/widgets/chat/conversation_list_item.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:projectbrain/widgets/chat/citations_popout.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Conversation>> _conversationsFuture;
  ChatProvider? _chatProvider;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    // Fetch conversations once during initialization
    _loadConversations();
    // Auto-scroll on chat changes (new message / streamed content) instead of
    // scheduling a scroll on every widget build.
    _chatProvider = context.read<ChatProvider>();
    _chatProvider!.addListener(_handleChatChanged);
  }

  @override
  void dispose() {
    _chatProvider?.removeListener(_handleChatChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Coalesce scroll-to-bottom requests into a single post-frame jump so rapid
  /// streaming updates don't queue many callbacks.
  void _handleChatChanged() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _loadConversations() {
    final chatProvider = context.read<ChatProvider>();
    setState(() {
      _conversationsFuture = chatProvider.fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only watch specific parts to avoid rebuilding TextField
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title:
            Text("${authProvider.profile?.name.split(' ').first}'s AI Buddy"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<ChatProvider>().clearConversation();
            },
            tooltip: 'New conversation',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: FutureBuilder(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: TypingIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final conversation = snapshot.data![index];
                          final isActive =
                              chatProvider.activeConversation?.id ==
                                  conversation.id;
                          return ConversationListItem(
                            conversation: conversation,
                            isActive: isActive,
                            onTap: () {
                              chatProvider.loadConversation(conversation.id);
                              Navigator.pop(context); // Close the drawer
                            },
                          );
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No conversations found.'));
                }
              }),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Loading a previous conversation (not token streaming, which
                // appends to messages): show a spinner instead of a blank list.
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  // Performance optimizations
                  cacheExtent: 500, // Cache 500px above/below viewport
                  addAutomaticKeepAlives:
                      true, // Keep widgets alive when scrolling
                  addRepaintBoundaries: true, // Reduce repaint overhead
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    // Use ValueKey for better widget reuse
                    return MessageBubble(
                      key: ValueKey('${message.role}_$index'),
                      message: message,
                    );
                  },
                );
              },
            ),
          ),
          // Citations popout - shows citations from the last assistant message
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              // Find the last assistant message with citations
              final assistantMessages = chatProvider.messages
                  .where((m) => m.role == 'assistant' && m.citations.isNotEmpty)
                  .toList();

              if (assistantMessages.isEmpty) {
                return const SizedBox.shrink();
              }

              final lastMessageWithCitations = assistantMessages.last;
              return CitationsPopout(
                citations: lastMessageWithCitations.citations,
              );
            },
          ),
          ChatInputField(
            controller: _controller,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }
}
