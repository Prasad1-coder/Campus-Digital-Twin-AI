import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/gemini_service.dart';
import 'services/ai_command_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

Color _headingOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : _textDark;

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  // =====================================================================
  // 1. STATE & DATA
  // =====================================================================
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;

  final AuthService _authService = AuthService();
  UserModel? get _currentUser => _authService.getCurrentUser();

  bool _isLoading = false;
  bool _isTyping = false;
  bool _isListening = false;
  bool _speechEnabled = false;

  final List<Map<String, dynamic>> _messages = [];
  GlobalKey<_TypingTextState>? _currentTypingKey;

  String get _userName => _currentUser?.fullName.split(' ').first ?? "Guest";

  String get _roleString {
    final role = _currentUser?.role.name;
    if (role == null || role.isEmpty) return "Guest";
    return role[0].toUpperCase() + role.substring(1);
  }

  List<Map<String, String>> get _suggestedCommands {
    switch (_currentUser?.role) {
      case UserRole.student:
        return [
          {"icon": "📊", "label": "My Attendance", "command": "How is my attendance?"},
          {"icon": "📅", "label": "Timetable", "command": "Show today's timetable"},
          {"icon": "💼", "label": "Placement", "command": "Show placement opportunities"},
          {"icon": "📚", "label": "Library", "command": "Find DSA books in library"},
        ];
      case UserRole.teacher:
        return [
          {"icon": "📝", "label": "Att. Summary", "command": "Show SE Computer attendance summary"},
          {"icon": "🗓️", "label": "Lecture Plan", "command": "Generate lecture plan for DBMS"},
          {"icon": "📈", "label": "Performance", "command": "Student performance analytics"},
          {"icon": "📢", "label": "Notices", "command": "Show recent notices"},
        ];
      case UserRole.hod:
        return [
          {"icon": "📊", "label": "Dept Reports", "command": "Department placement statistics"},
          {"icon": "👩‍🏫", "label": "Faculty", "command": "Faculty performance report"},
          {"icon": "📉", "label": "Dept Att.", "command": "Department attendance analytics"},
          {"icon": "💡", "label": "Insights", "command": "AI department insights"},
        ];
      case UserRole.principal:
        return [
          {"icon": "🎓", "label": "College Stats", "command": "College placement analytics"},
          {"icon": "⚖️", "label": "Compare", "command": "Department comparison report"},
          {"icon": "🏆", "label": "Performance", "command": "College performance overview"},
          {"icon": "🚀", "label": "Strategy", "command": "Strategic recommendations"},
        ];
      default:
        return [
          {"icon": "📅", "label": "Timetable", "command": "Show today's timetable"},
          {"icon": "📢", "label": "Notices", "command": "Show recent notices"},
        ];
    }
  }

  // =====================================================================
  // 2. LOGIC (unchanged)
  // =====================================================================
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎤 Voice error: ${error.errorMsg}")),
          );
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎤 Speech recognition not available")),
      );
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_IN",
    );
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _scrollDuringTyping() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if ((position.maxScrollExtent - position.pixels) < 100) {
      _scrollController.jumpTo(position.maxScrollExtent);
    }
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

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    if (_isListening) _stopListening();

    String question = _controller.text;
    String time = _getCurrentTime();

    setState(() {
      _messages.add({"sender": "You", "text": question, "animate": false, "time": time});
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    if (AICommandService.isCommand(question)) {
      final responseText = AICommandService.getResponseMessage(question);
      final key = GlobalKey<_TypingTextState>();
      _currentTypingKey = key;

      setState(() {
        _isLoading = false;
        _isTyping = true;
        _messages.add({"sender": "AI", "text": responseText, "animate": true, "key": key, "time": _getCurrentTime()});
      });

      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        AICommandService.executeCommand(context, question, userRole: _currentUser?.role ?? UserRole.student, currentUserName: _userName);
      }
      return;
    }

    try {
      String reply = await GeminiService.askAI(question);
      if (!mounted) return; // screen was closed while waiting
      final key = GlobalKey<_TypingTextState>();
      _currentTypingKey = key;

      setState(() {
        _isLoading = false;
        _isTyping = true;
        _messages.add({
          "sender": "AI",
          "text": reply.isNotEmpty ? reply : "⚠️ Empty response from AI.",
          "animate": true,
          "key": key,
          "time": _getCurrentTime(),
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({"sender": "AI", "text": "⚠️ Error: $e\nPlease try again.", "animate": false, "time": _getCurrentTime()});
      });
    }

    _scrollToBottom();
  }

  void _sendQuickCommand(String command) {
    _controller.text = command;
    _sendMessage();
  }

  void _stopTyping() {
    _currentTypingKey?.currentState?.stopAndShowFullText();
    setState(() => _isTyping = false);
  }

  void _onTypingFinished() {
    if (mounted) setState(() => _isTyping = false);
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Clear Chat?", style: TextStyle(fontWeight: FontWeight.w800, color: _headingOf(theme))),
          content: const Text("Are you sure you want to clear this conversation?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: theme.hintColor)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _messages.clear());
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  // =====================================================================
  // 3. BUILD (screen skeleton)
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool showEmptyState = _messages.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : _lightBg,
        body: Column(
          children: [
            _buildHeader(),

            // Quick suggestions stay handy once the chat has started
            if (!showEmptyState) _buildSuggestionBar(),

            Expanded(
              child: showEmptyState ? _buildEmptyState() : _buildMessageList(),
            ),

            // SafeArea keeps the input clear of the floating nav bar / system bar
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isListening) _buildListeningChip(),
                  if (_isTyping) _buildStopButton(),
                  _buildInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // 4. HEADER (compact, blueprint style)
  // =====================================================================
  Widget _buildHeader() {
    // Back button only when this screen was pushed (not when it is a tab)
    final bool canGoBack = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeaderGridPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
              child: Row(
                children: [
                  if (canGoBack) ...[
                    _headerButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: "Back",
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // AI avatar with online dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, size: 22, color: Colors.white),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Campus AI Assistant",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Online • $_userName ($_roleString)",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _headerButton(
                    icon: Icons.history_rounded,
                    tooltip: "Chat History",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat history feature is ready for backend integration.")),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _headerButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: "Clear Chat",
                    onTap: _messages.isEmpty ? null : _clearChat,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required String tooltip, required VoidCallback? onTap}) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(enabled ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: enabled ? Colors.white : Colors.white38, size: 20),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // 5. SUGGESTIONS (chips + empty state)
  // =====================================================================
  Widget _buildSuggestionBar() {
    final cmds = _suggestedCommands;
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: cmds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cmd = cmds[index];
          return _CommandChip(
            icon: cmd["icon"]!,
            label: cmd["label"]!,
            onTap: _isLoading ? null : () => _sendQuickCommand(cmd["command"]!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: _EmptyStateSuggestionCard(
        userName: _userName,
        onCommandTap: _sendQuickCommand,
        suggestions: _suggestedCommands,
      ),
    );
  }

  // =====================================================================
  // 6. MESSAGES
  // =====================================================================
  Widget _buildMessageList() {
    final int extra = _isLoading ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: _messages.length + extra,
      itemBuilder: (context, index) {
        // last item = "AI is thinking" bubble
        if (index >= _messages.length) return _buildTypingIndicatorBubble();

        final message = _messages[index];
        final bool me = message["sender"] == "You";
        final bool animate = message["animate"] == true;

        // each new message fades + slides in once
        return TweenAnimationBuilder<double>(
          key: ValueKey('msg-$index'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
            );
          },
          child: _buildMessageBubble(message, me, animate),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool me, bool animate) {
    final theme = Theme.of(context);
    final String text = message["text"] as String;
    final Color textColor = me ? Colors.white : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!me) const _Avatar(isAI: true),
          if (!me) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: me ? const LinearGradient(colors: [_primary, _primaryDark]) : null,
                    color: me ? null : theme.cardColor,
                    border: me ? null : Border.all(color: theme.dividerColor.withOpacity(0.6)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(me ? 20 : 6),
                      bottomRight: Radius.circular(me ? 6 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: me ? _primary.withOpacity(0.25) : Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: animate
                      ? TypingText(
                          key: message["key"] ?? ValueKey(text),
                          text: text,
                          style: TextStyle(color: textColor, fontSize: 14.5, height: 1.42),
                          onCharacterTyped: _scrollDuringTyping,
                          onFinished: _onTypingFinished,
                        )
                      : Text(
                          text,
                          style: TextStyle(color: textColor, fontSize: 14.5, height: 1.42),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message["time"] as String,
                        style: TextStyle(fontSize: 10.5, color: theme.hintColor, fontWeight: FontWeight.w500),
                      ),
                      if (!me) ...[
                        const SizedBox(width: 6),
                        _bubbleAction(Icons.copy_rounded, "Copy", () => _copyMessage(text)),
                        _bubbleAction(Icons.refresh_rounded, "Regenerate", () {
                          // Regenerate logic placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Regenerating response..."), duration: Duration(seconds: 1)),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (me) const SizedBox(width: 8),
          if (me) const _Avatar(isAI: false),
        ],
      ),
    );
  }

  // small tappable icon under an AI message (bigger tap area than the icon)
  Widget _bubbleAction(IconData icon, String tooltip, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 15, color: theme.hintColor),
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorBubble() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _Avatar(isAI: true),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 7. INPUT AREA
  // =====================================================================
  Widget _buildListeningChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                "Listening...",
                style: TextStyle(color: Colors.red.shade600, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton.icon(
        onPressed: _stopTyping,
        icon: const Icon(Icons.stop_circle_outlined, size: 18),
        label: const Text("Stop generating", style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: "Attach",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Attachment feature is ready for PDF/Image analysis.")),
                );
              },
              icon: Icon(Icons.attach_file_rounded, color: theme.hintColor, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(fontSize: 14.5, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Message Campus AI...",
                  hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 4),

            // Mic
            Material(
              color: _isListening ? Colors.red.withOpacity(0.12) : _tintOf(theme),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isLoading ? null : _toggleListening,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? Colors.red : _iconOf(theme),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send
            Opacity(
              opacity: _isLoading ? 0.5 : 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _sendMessage,
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  HEADER BACKGROUND (blueprint grid + corner rings, same as other screens)
// =====================================================================
class _HeaderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Rings from the top-right corner
    final ring = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width - 16, 0);
    for (final r in [36.0, 64.0, 92.0]) {
      canvas.drawCircle(center, r, ring);
    }

    final dot = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(Offset(center.dx - 45, center.dy + 45), 3, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
//  REUSABLE WIDGETS
// ============================================================

class _Avatar extends StatelessWidget {
  final bool isAI;
  const _Avatar({required this.isAI});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAI ? const [_primary, _primaryDark] : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        isAI ? Icons.smart_toy_rounded : Icons.person_rounded,
        size: 17,
        color: Colors.white,
      ),
    );
  }
}

// three bouncing dots while the AI is thinking
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color dotColor = _iconOf(Theme.of(context));

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double phase = (_anim.value - i * 0.15) % 1.0;
            final double lift = math.sin(phase * math.pi); // 0 → 1 → 0
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.translate(
                offset: Offset(0, -4 * lift),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.4 + 0.6 * lift),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CommandChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const _CommandChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: _tintOf(theme),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _iconOf(theme)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateSuggestionCard extends StatelessWidget {
  final String userName;
  final Function(String) onCommandTap;
  final List<Map<String, String>> suggestions;

  const _EmptyStateSuggestionCard({
    required this.userName,
    required this.onCommandTap,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14), // <-- Box ka main padding kam kiya (20 se 14)
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, // <-- Icon size kam kiya (52 se 44)
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22), // <-- Icon size 26 se 22
          ),
          const SizedBox(height: 10), // <-- Spacing kam kiya (16 se 10)
          Text(
            "Hi $userName 👋",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.hintColor),
          ),
          const SizedBox(height: 2),
          Text(
            "How can I help you today?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _headingOf(theme)), // <-- Font size 20 se 18
          ),
          const SizedBox(height: 2),
          Text(
            "Tap a suggestion or type your own question.",
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          const SizedBox(height: 12), // <-- Spacing kam kiya (18 se 12)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8, // <-- Spacing kam kiya (10 se 8)
              mainAxisSpacing: 8,
              mainAxisExtent: 54, // <-- Grid item height kam kiya (62 se 54)
            ),
            itemBuilder: (context, index) {
              final action = suggestions[index];
              return _SuggestionTile(
                icon: action["icon"]!,
                label: action["label"]!,
                onTap: () => onCommandTap(action["command"]!),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: _tintOf(theme).withOpacity(theme.brightness == Brightness.dark ? 0.6 : 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8), // <-- Padding kam kiya (10 se 8)
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 32, // <-- Icon box size kam kiya (36 se 32)
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 16)), // <-- Emoji font size 18 se 16
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, height: 1.15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  TYPING TEXT (typewriter effect - unchanged)
// ============================================================
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback? onCharacterTyped;
  final VoidCallback? onFinished;
  final Duration speed;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.onCharacterTyped,
    this.onFinished,
    this.speed = const Duration(milliseconds: 15),
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String visibleText = "";
  int charIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    const charsPerTick = 2;
    timer = Timer.periodic(widget.speed, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (charIndex < widget.text.length) {
        setState(() {
          charIndex = (charIndex + charsPerTick).clamp(0, widget.text.length);
          visibleText = widget.text.substring(0, charIndex);
        });
        if (charIndex % 8 == 0) {
          widget.onCharacterTyped?.call();
        }
      } else {
        t.cancel();
        widget.onCharacterTyped?.call();
        widget.onFinished?.call();
      }
    });
  }

  void stopAndShowFullText() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        charIndex = widget.text.length;
        visibleText = widget.text;
      });
    }
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(visibleText, style: widget.style);
  }
}