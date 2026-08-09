import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart'; // 👈 FIX: Added missing import for Clipboard
import 'services/gemini_service.dart';
import 'services/ai_command_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> with TickerProviderStateMixin {
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

  // ---------- Theme ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _textDark = Color(0xFF1A237E);

  late final AnimationController _fadeController;

  String get _userName => _currentUser?.fullName.split(' ').first ?? "Guest";
  
  // FIX: Null safety error fixed here
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
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
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
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
      builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text("Clear Chat?", style: TextStyle(fontWeight: flutter.FontWeight.bold, color: _textDark)),
        content: const Text("Are you sure you want to clear this conversation?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _messages.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Clear"),
          ),
        ],
      ),
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showEmptyState = _messages.isEmpty;

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy_rounded, size: 20, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryDark, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Campus AI Assistant", style: TextStyle(fontSize: 16, fontWeight: flutter.FontWeight.w700, color: Colors.white)),
                  Text("Online • $_userName ($_roleString)", style: TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: flutter.FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: "Chat History",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chat history feature is ready for backend integration.")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: "Clear Chat",
            onPressed: _messages.isEmpty ? null : _clearChat,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Quick Suggestions Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 0, 8),
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedCommands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cmd = _suggestedCommands[index];
                return _CommandChip(
                  icon: cmd["icon"]!,
                  label: cmd["label"]!,
                  onTap: _isLoading ? null : () => _sendQuickCommand(cmd["command"]!),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              children: [
                ..._messages.map((message) {
                  bool me = message["sender"] == "You";
                  bool animate = message["animate"] == true;

                  return FadeTransition(
                    opacity: _fadeController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)),
                      child: _buildMessageBubble(message, me, animate),
                    ),
                  );
                }).toList(),
                if (showEmptyState) _EmptyStateSuggestionCard(onCommandTap: _sendQuickCommand, suggestions: _suggestedCommands),
                if (_isLoading) _buildTypingIndicatorBubble(),
              ],
            ),
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text("Listening...", style: TextStyle(color: Colors.red.shade600, fontStyle: FontStyle.italic, fontSize: 12.5, fontWeight: flutter.FontWeight.w600)),
                  ],
                ),
              ),
            ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: _stopTyping,
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text("Stop generating"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool me, bool animate) {
    String text = message["text"]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!me) _Avatar(isAI: true),
          if (!me) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: me ? const LinearGradient(colors: [_primary, _primaryDark]) : null,
                    color: me ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(me ? 20 : 4),
                      bottomRight: Radius.circular(me ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: me ? _primary.withOpacity(0.25) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: animate
                      ? TypingText(
                          key: message["key"] ?? ValueKey(text),
                          text: text,
                          style: TextStyle(
                            color: me ? Colors.white : Colors.black87,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                          onCharacterTyped: _scrollDuringTyping,
                          onFinished: _onTypingFinished,
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            color: me ? Colors.white : Colors.black87,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message["time"]!,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: flutter.FontWeight.w500),
                      ),
                      if (!me) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyMessage(text),
                          child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            // Regenerate logic placeholder
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Regenerating response..."), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Icon(Icons.refresh_rounded, size: 14, color: Colors.grey.shade400),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (me) const SizedBox(width: 8),
          if (me) _Avatar(isAI: false),
        ],
      ),
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _Avatar(isAI: true),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Attachment feature is ready for PDF/Image analysis.")),
                );
              },
              icon: Icon(Icons.attach_file_rounded, color: Colors.grey.shade500),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(fontSize: 14.5, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Message Campus AI...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              onPressed: _isLoading ? null : _toggleListening,
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? Colors.red : _primary,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_primary, _primaryDark]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

mixin FontWeight {
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
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAI ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)] : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAI ? Icons.smart_toy_rounded : Icons.person_rounded,
        size: 16,
        color: Colors.white,
      ),
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
    return Material(
      color: const Color(0xFFE3F2FD),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: flutter.FontWeight.w700, color: Color(0xFF1565C0))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateSuggestionCard extends StatelessWidget {
  final Function(String) onCommandTap;
  final List<Map<String, String>> suggestions;

  const _EmptyStateSuggestionCard({required this.onCommandTap, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  "How can I help you today?",
                  style: TextStyle(fontSize: 18, fontWeight: flutter.FontWeight.w800, color: Color(0xFF1A237E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions.map((action) {
              return _QuickActionButton(
                icon: action["icon"]!,
                label: action["label"]!,
                onTap: () => onCommandTap(action["command"]!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F9FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: flutter.FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

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