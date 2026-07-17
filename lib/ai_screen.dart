import 'dart:async';
import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/ai_command_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late stt.SpeechToText speech;

  bool isLoading = false;
  bool isTyping = false;
  bool isListening = false;
  bool speechEnabled = false;

  final List<Map<String, dynamic>> messages = [
    {
      "sender": "AI",
      "text": "👋 Welcome to Campus AI Assistant!\n\n"
          "I can help you with:\n\n"
          "📚 Library\n"
          "📅 Timetable\n"
          "📊 Attendance\n"
          "🪪 Digital ID\n"
          "📢 Notices\n"
          "🎉 Events\n"
          "🗺 Campus Map\n"
          "👤 Profile\n\n"
          "Try asking:\n"
          "• Open Library\n"
          "• Show Attendance\n"
          "• Open Timetable\n"
          "• Show Notices",
      "animate": false,
    }
  ];

  GlobalKey<_TypingTextState>? currentTypingKey;

  final List<Map<String, String>> _suggestedCommands = const [
    {"icon": "📚", "label": "Library", "command": "Open Library"},
    {"icon": "📅", "label": "Timetable", "command": "Open Timetable"},
    {"icon": "📊", "label": "Attendance", "command": "Show Attendance"},
    {"icon": "🪪", "label": "Digital ID", "command": "Open Digital ID"},
    {"icon": "📢", "label": "Notices", "command": "Show Notices"},
    {"icon": "🎉", "label": "Events", "command": "Open Events"},
    {"icon": "🗺", "label": "Campus Map", "command": "Open Campus Map"},
  ];

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    speechEnabled = await speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) setState(() => isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎤 Voice error: ${error.errorMsg}")),
          );
        }
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎤 Speech recognition available nahi hai")),
      );
      return;
    }

    setState(() => isListening = true);

    await speech.listen(
      onResult: (result) {
        setState(() {
          controller.text = result.recognizedWords;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_IN",
    );
  }

  void _stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  void _toggleListening() {
    if (isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 100;
  }

  void _scrollDuringTyping() {
    if (!scrollController.hasClients) return;
    if (_isNearBottom()) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    if (isListening) _stopListening();

    String question = controller.text;

    setState(() {
      messages.add({"sender": "You", "text": question, "animate": false});
      controller.clear();
      isLoading = true;
    });

    scrollToBottom();

    if (AICommandService.isCommand(question)) {
      final responseText = AICommandService.getResponseMessage(question);
      final key = GlobalKey<_TypingTextState>();
      currentTypingKey = key;

      setState(() {
        isLoading = false;
        isTyping = true;
        messages.add({"sender": "AI", "text": responseText, "animate": true, "key": key});
      });

      scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        AICommandService.executeCommand(context, question);
      }
      return;
    }

    try {
      String reply = await GeminiService.askAI(question);
      final key = GlobalKey<_TypingTextState>();
      currentTypingKey = key;

      setState(() {
        isLoading = false;
        isTyping = true;
        messages.add({
          "sender": "AI",
          "text": reply.isNotEmpty ? reply : "⚠️ Empty response mila AI se.",
          "animate": true,
          "key": key,
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        messages.add({"sender": "AI", "text": "⚠️ Error aaya: $e\nDobara try karo.", "animate": false});
      });
    }

    scrollToBottom();
  }

  void _sendQuickCommand(String command) {
    controller.text = command;
    sendMessage();
  }

  void stopTyping() {
    currentTypingKey?.currentState?.stopAndShowFullText();
    setState(() => isTyping = false);
  }

  void _onTypingFinished() {
    if (mounted) setState(() => isTyping = false);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              const Text("Campus AI Commands", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "Type or tap any of these to navigate instantly",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              ..._suggestedCommands.map((cmd) => _helpCommandRow(cmd["icon"]!, cmd["command"]!)),
              _helpCommandRow("👤", "Open Profile"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text("Got it", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpCommandRow(String icon, String command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(command, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showEmptyStateSuggestions = messages.length == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Campus AI Assistant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text("Always here to help", style: TextStyle(fontSize: 10.5, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: "Help",
            onPressed: _showHelpDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 👇 Suggested chips - subtle gradient strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedCommands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cmd = _suggestedCommands[index];
                  return _CommandChip(
                    icon: cmd["icon"]!,
                    label: cmd["label"]!,
                    onTap: isLoading ? null : () => _sendQuickCommand(cmd["command"]!),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
              children: [
                ...messages.map((message) {
                  bool me = message["sender"] == "You";
                  bool animate = message["animate"] == true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!me) _Avatar(isAI: true),
                        if (!me) const SizedBox(width: 8),
                        Flexible(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: me
                                  ? LinearGradient(colors: [Colors.blue, Colors.blue.shade700])
                                  : null,
                              color: me ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(me ? 18 : 4),
                                bottomRight: Radius.circular(me ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: me ? Colors.blue.withOpacity(0.25) : Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: animate
                                ? TypingText(
                                    key: message["key"] ?? ValueKey(message["text"]),
                                    text: message["text"]!,
                                    style: TextStyle(
                                      color: me ? Colors.white : Colors.black87,
                                      fontSize: 14.5,
                                      height: 1.4,
                                    ),
                                    onCharacterTyped: _scrollDuringTyping,
                                    onFinished: _onTypingFinished,
                                  )
                                : Text(
                                    message["text"]!,
                                    style: TextStyle(
                                      color: me ? Colors.white : Colors.black87,
                                      fontSize: 14.5,
                                      height: 1.4,
                                    ),
                                  ),
                          ),
                        ),
                        if (me) const SizedBox(width: 8),
                        if (me) _Avatar(isAI: false),
                      ],
                    ),
                  );
                }),

                if (showEmptyStateSuggestions) _EmptyStateSuggestionCard(onCommandTap: _sendQuickCommand),
              ],
            ),
          ),

          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade300),
                    ),
                    const SizedBox(width: 8),
                    Text("AI is typing...", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 12.5)),
                  ],
                ),
              ),
            ),

          if (isListening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text("Sun raha hoon...", style: TextStyle(color: Colors.red.shade600, fontStyle: FontStyle.italic, fontSize: 12.5)),
                  ],
                ),
              ),
            ),

          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: stopTyping,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _toggleListening,
                    icon: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: isListening ? Colors.red : Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: isListening ? "Bolo..." : "Ask AI or try \"Open Library\"",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isLoading ? null : sendMessage,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 👇 Avatar circle for chat bubbles
class _Avatar extends StatelessWidget {
  final bool isAI;
  const _Avatar({required this.isAI});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAI ? [Colors.blue, Colors.blue.shade700] : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAI ? Icons.smart_toy_rounded : Icons.person_rounded,
        size: 15,
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
      color: Colors.blue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.blue.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateSuggestionCard extends StatelessWidget {
  final Function(String) onCommandTap;

  const _EmptyStateSuggestionCard({required this.onCommandTap});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {"icon": Icons.menu_book_outlined, "label": "Open Library", "command": "Open Library"},
      {"icon": Icons.calendar_month_outlined, "label": "Today's Timetable", "command": "Open Timetable"},
      {"icon": Icons.fact_check_outlined, "label": "Attendance", "command": "Show Attendance"},
      {"icon": Icons.map_outlined, "label": "Campus Map", "command": "Open Campus Map"},
      {"icon": Icons.badge_outlined, "label": "Digital ID", "command": "Open Digital ID"},
      {"icon": Icons.campaign_outlined, "label": "Notices", "command": "Show Notices"},
      {"icon": Icons.celebration_outlined, "label": "Events", "command": "Open Events"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "What would you like to do today?",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions.map((action) {
              return _QuickActionButton(
                icon: action["icon"] as IconData,
                label: action["label"] as String,
                onTap: () => onCommandTap(action["command"] as String),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87)),
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
    startTyping();
  }

  void startTyping() {
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
      setState(() {});
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