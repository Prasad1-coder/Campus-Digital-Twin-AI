import 'dart:async';
import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
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
  bool isListening = false; // 👈 naya flag - mic on/off
  bool speechEnabled = false; // 👈 speech recognition available hai ya nahi

  final List<Map<String, dynamic>> messages = [
    {
      "sender": "AI",
      "text": "👋 Hello! I'm your Campus AI Assistant. Ask me anything.",
      "animate": false,
    }
  ];

  GlobalKey<_TypingTextState>? currentTypingKey;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _initSpeech();
  }

  // 👇 Speech recognition ko initialize karo
  void _initSpeech() async {
    speechEnabled = await speech.initialize(
      onStatus: (status) {
        // Jab listening khud hi ruk jaye (silence ya timeout ki wajah se)
        if (status == "done" || status == "notListening") {
          if (mounted) {
            setState(() {
              isListening = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎤 Voice error: ${error.errorMsg}")),
          );
        }
      },
    );
    setState(() {});
  }

  // 👇 Listening start karo
  void _startListening() async {
    if (!speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎤 Speech recognition available nahi hai")),
      );
      return;
    }

    setState(() {
      isListening = true;
    });

    await speech.listen(
      onResult: (result) {
        setState(() {
          controller.text = result.recognizedWords;
          // Cursor ko end mein rakho
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30), // max 30 sec sunega
      pauseFor: const Duration(seconds: 3), // 3 sec chup rehne par ruk jayega
      localeId: "en_IN", // Hindi ke liye "hi_IN" try kar sakte ho
    );
  }

  // 👇 Manually rokne ke liye
  void _stopListening() async {
    await speech.stop();
    setState(() {
      isListening = false;
    });
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

    // Agar mic on hai to message bhejte waqt band kar do
    if (isListening) {
      _stopListening();
    }

    String question = controller.text;

    setState(() {
      messages.add({
        "sender": "You",
        "text": question,
        "animate": false,
      });

      controller.clear();
      isLoading = true;
    });

    scrollToBottom();

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
        messages.add({
          "sender": "AI",
          "text": "⚠️ Error aaya: $e\nDobara try karo.",
          "animate": false,
        });
      });
    }

    scrollToBottom();
  }

  void stopTyping() {
    currentTypingKey?.currentState?.stopAndShowFullText();
    setState(() {
      isTyping = false;
    });
  }

  void _onTypingFinished() {
    if (mounted) {
      setState(() {
        isTyping = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus AI Assistant"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool me = messages[index]["sender"] == "You";
                bool animate = messages[index]["animate"] == true;

                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: me ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: animate
                        ? TypingText(
                            key: messages[index]["key"] ?? ValueKey(messages[index]["text"]),
                            text: messages[index]["text"]!,
                            style: TextStyle(
                              color: me ? Colors.white : Colors.black,
                            ),
                            onCharacterTyped: _scrollDuringTyping,
                            onFinished: _onTypingFinished,
                          )
                        : Text(
                            messages[index]["text"]!,
                            style: TextStyle(
                              color: me ? Colors.white : Colors.black,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "AI is typing...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // 👇 Listening indicator
          if (isListening)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "🎤 Sun raha hoon...",
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
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
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 👇 Mic button
                  IconButton(
                    onPressed: isLoading ? null : _toggleListening,
                    icon: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.red : Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: isListening ? "Bolo..." : "Ask anything...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      onPressed: isLoading ? null : sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
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
      setState(() {
        // jahan tak type hua wahi rehne do
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
    return Text(
      visibleText,
      style: widget.style,
    );
  }
}