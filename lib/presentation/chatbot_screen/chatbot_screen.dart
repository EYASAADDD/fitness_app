import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text: 'I am your AI fitness coach powered by Claude. Ask me about posture, reps, workout structure, nutrition or meal timing.',
      isLoading: false,
    ),
  ];
  bool _isLoading = false;
  int _navIndex = 2;

  // Conversation history for multi-turn context
  final List<Map<String, String>> _conversationHistory = [];

  static const List<String> _quickPrompts = [
    'Correct squat posture',
    'How many reps for push-ups?',
    'Best meal after workout',
    'How to fix rounded shoulders?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (route) => false,
      );
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.recipesScreen);
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.searchScreen);
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
      return;
    }
    setState(() => _navIndex = index);
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: query, isLoading: false));
      // Add loading indicator
      _messages.add(const _ChatMessage(isUser: false, text: '', isLoading: true));
      _isLoading = true;
      _inputController.clear();
    });

    _scrollToBottom();

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': query});

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 600,
          'system': '''You are an expert AI fitness coach embedded in the Smart AI Fitness Coach app.
You specialize in:
- Exercise form and posture correction (squats, push-ups, planks)
- Repetition counts, sets and rest periods
- Nutrition timing and macronutrient guidance
- Workout program structure

Keep answers concise (3-5 sentences max), practical and encouraging.
When relevant, mention the app features: live pose analyzer, OCR meal import, product scanner.
Reply in the same language as the user.''',
          'messages': _conversationHistory,
        }),
      );

      String replyText;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        replyText = (data['content'] as List)
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join('\n');
        // Add assistant reply to history
        _conversationHistory.add({'role': 'assistant', 'content': replyText});
      } else {
        replyText = 'Sorry, I could not connect right now. Please try again.';
        // Remove the failed message from history
        _conversationHistory.removeLast();
      }

      if (!mounted) return;
      setState(() {
        // Remove loading bubble
        _messages.removeLast();
        _messages.add(_ChatMessage(isUser: false, text: replyText, isLoading: false));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(const _ChatMessage(
          isUser: false,
          text: 'Network error. Check your connection and try again.',
          isLoading: false,
        ));
        _isLoading = false;
      });
      _conversationHistory.removeLast();
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPromptRow(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Powered by Claude AI',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Live',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptRow() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(prompt),
            onPressed: _isLoading ? null : () => _sendMessage(prompt),
            backgroundColor: AppTheme.bgCard,
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            side: BorderSide(color: AppTheme.borderLight),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _quickPrompts.length,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.bgPage,
        border: Border(top: BorderSide(color: AppTheme.borderLight.withAlpha(160))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              onSubmitted: _isLoading ? null : _sendMessage,
              enabled: !_isLoading,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ask your coach...',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textHint),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_inputController.text),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _isLoading
                    ? AppTheme.primaryBlue.withAlpha(100)
                    : AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.isLoading,
  });

  final bool isUser;
  final String text;
  final bool isLoading;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? AppTheme.primaryBlue : AppTheme.bgCard;
    final textColor = message.isUser ? Colors.black : AppTheme.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: message.isUser ? null : Border.all(color: AppTheme.borderLight),
        ),
        child: message.isLoading
            ? const SizedBox(
                height: 18,
                width: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DotPulse(delay: 0),
                    _DotPulse(delay: 150),
                    _DotPulse(delay: 300),
                  ],
                ),
              )
            : Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
