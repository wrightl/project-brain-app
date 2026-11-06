// lib/pages/ai_chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/widgets/chat/action_card_widget.dart';
import 'package:projectbrain/widgets/chat/user_choice_chips.dart';
import 'package:projectbrain/widgets/chat/message_bubble.dart';
import 'package:projectbrain/widgets/chat/tool_execution_badge.dart';
import 'package:projectbrain/widgets/chat/chat_input_field.dart';
import 'package:projectbrain/widgets/chat/conversation_list_item.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:projectbrain/widgets/chat/citations_popout.dart';
import 'package:projectbrain/helpers/coach_agent_actions.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
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
  bool _wasSending = false;

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
  /// streaming updates don't queue many callbacks. Only follows the reply when
  /// the user is already at (or near) the bottom, so reading earlier messages
  /// is not interrupted.
  void _handleChatChanged() {
    _announceReplyFinished();
    final actionError = _chatProvider?.consumeActionError();
    if (actionError != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(actionError)));
    }

    if (_scrollScheduled) return;
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.maxScrollExtent - position.pixels > 120) return;
    }
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Tell screen reader users when a streamed reply is complete; the text
  /// arrives a few words at a time and is otherwise not announced.
  void _announceReplyFinished() {
    final provider = _chatProvider;
    if (provider == null || !mounted) return;
    final finished = _wasSending && !provider.isSending;
    _wasSending = provider.isSending;
    if (!finished || provider.messages.isEmpty) return;
    final last = provider.messages.last;
    if (last.role != 'assistant') return;
    final message =
        provider.canRetryLastMessage ? last.content : 'AI Buddy replied';
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
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
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final rawFirstName = authProvider.profile?.name.split(' ').first.trim();
    final firstName =
        (rawFirstName == null || rawFirstName.isEmpty) ? null : rawFirstName;

    return Scaffold(
      key: _scaffoldKey,
      // Refresh the list each time it opens so new conversations show up.
      onDrawerChanged: (isOpen) {
        if (isOpen) _loadConversations();
      },
      appBar: AppBar(
        title: Text(
          firstName == null ? 'Your AI Buddy' : "$firstName's AI Buddy",
        ),
        titleTextStyle: theme.textTheme.titleMedium,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Conversations',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: appTheme.primarySoft,
            ),
            onPressed: () {
              context.read<ChatProvider>().clearConversation();
            },
            tooltip: 'New conversation',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Conversations',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: FutureBuilder(
                    future: _conversationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: TypingIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text("Couldn't load your conversations."));
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
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
                                  onTap: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    Navigator.pop(context); // Close the drawer
                                    try {
                                      await chatProvider
                                          .loadConversation(conversation.id);
                                    } catch (_) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Couldn't open that conversation. "
                                            'Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Text(
                            'No conversations found.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: appTheme.textMuted,
                            ),
                          ),
                        );
                      }
                    }),
              ),
            ],
          ),
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
                  return const Center(
                      child:
                          CircularProgressIndicator(semanticsLabel: 'Loading'));
                }
                if (chatProvider.messages.isEmpty) {
                  return _ChatWelcome(
                    firstName: firstName ?? 'there',
                    onPromptSelected: chatProvider.sendMessage,
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  // Performance optimizations
                  scrollCacheExtent: ScrollCacheExtent.pixels(500),
                  addAutomaticKeepAlives:
                      true, // Keep widgets alive when scrolling
                  addRepaintBoundaries: true, // Reduce repaint overhead
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final extras = chatProvider.messageExtrasFor(index);
                    final isLastMessage =
                        index == chatProvider.messages.length - 1;
                    return Column(
                      crossAxisAlignment: message.role == 'user'
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        MessageBubble(
                          key: ValueKey('${message.role}_$index'),
                          message: message,
                          showTypingIndicator: chatProvider.isSending &&
                              isLastMessage &&
                              message.role == 'assistant' &&
                              message.content.isEmpty,
                        ),
                        if (isLastMessage && chatProvider.canRetryLastMessage)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: TextButton.icon(
                              onPressed: chatProvider.retryLastMessage,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ),
                        if (message.role == 'assistant') ...[
                          for (final tool in extras.toolExecutions
                              .where((tool) => tool.toolName != 'ask_user'))
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ToolExecutionBadge(tool: tool),
                            ),
                          for (final card in extras.actionCards)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ActionCardWidget(
                                card: card,
                                onConfirmPendingAction: (pendingCard) =>
                                    chatProvider.confirmPendingAction(
                                        pendingCard, index),
                                onCancelPendingAction: (pendingCard) =>
                                    chatProvider.cancelPendingAction(
                                        pendingCard, index),
                              ),
                            ),
                          if (extras.userChoices != null &&
                              !chatProvider.isChoiceAnswered(index))
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: UserChoiceChips(
                                choices: extras.userChoices!,
                                disabled: chatProvider.isSending,
                                onSelect: (option) {
                                  if (CoachAgentActions.tryExecute(
                                      context, option)) {
                                    chatProvider.markUserChoiceAnswered(index);
                                    return;
                                  }
                                  chatProvider.selectUserChoice(
                                      index, option.label);
                                },
                              ),
                            ),
                        ],
                      ],
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

/// Shown for a new conversation: a greeting and prompts to start from.
class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome({
    required this.firstName,
    required this.onPromptSelected,
  });

  final String firstName;
  final ValueChanged<String> onPromptSelected;

  static const _prompts = [
    'Help me plan my day',
    "I'm feeling overwhelmed. Where do I start?",
    'Give me a tip for staying focused',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi $firstName, what would you like to talk about?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Try one of these:', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final prompt in _prompts) ...[
            ActionChip(
              label: Text(prompt),
              backgroundColor: appTheme.primarySoft,
              side: BorderSide.none,
              onPressed: () => onPromptSelected(prompt),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
