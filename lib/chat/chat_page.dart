// lib/pages/ai_chat_page.dart
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/widgets/chat/message_bubble.dart';
import 'package:projectbrain/widgets/chat/chat_input_field.dart';
import 'package:projectbrain/widgets/chat/conversation_list_item.dart';
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

  @override
  void initState() {
    super.initState();
    // Fetch conversations once during initialization
    _loadConversations();
  }

  void _loadConversations() {
    final chatProvider = context.read<ChatProvider>();
    setState(() {
      _conversationsFuture = chatProvider.fetchConversations();
    });
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only watch specific parts to avoid rebuilding TextField
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("${authProvider.profile?.name}'s AI Buddy"),
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final conversation = snapshot.data![index];
                          final isActive = chatProvider.activeConversation?.id ==
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
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  // Performance optimizations
                  cacheExtent: 500, // Cache 500px above/below viewport
                  addAutomaticKeepAlives: true, // Keep widgets alive when scrolling
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
          ChatInputField(
            controller: _controller,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }
}
