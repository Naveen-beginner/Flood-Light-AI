import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:floodlight/services/offline_ai_engine.dart';
import 'package:floodlight/services/device_ai_capability.dart';
import 'package:material_ui/material_ui.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isOffline;
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.isOffline,
    required this.timestamp,
  });
}

class FloodHybridChatScreen extends StatefulWidget {
  const FloodHybridChatScreen({super.key});

  @override
  State<FloodHybridChatScreen> createState() => _FloodHybridChatScreenState();
}

class _FloodHybridChatScreenState extends State<FloodHybridChatScreen> {
  static const Color bgWhite = Colors.white;
  static const Color primaryIndigo = Colors.indigoAccent;
  static const Color darkIndigo = Color(0xFF1A237E);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = true;
  bool _supportsNano = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your Flood Light AI assistant. I automatically switch between Cloud AI (Gemini 3.8 Flash) and On-Device Edge AI depending on your network status.",
      isUser: false,
      isOffline: false,
      timestamp: "10:42 AM",
    ),
  ];

  final List<String> _quickPrompts = [
    "Purify flood water",
    "Nearest high ground",
    "Electrical safety",
    "SOS SMS template",
  ];

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    _checkNanoCapability();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
          if (!mounted) return;
          setState(() {
            _isOnline = !results.contains(ConnectivityResult.none);
          });
        });
  }

  Future<void> _checkNanoCapability() async {
    final supportsNano =
        await DeviceAiCapability.supportsGeminiNano();
    if (mounted) {
      setState(() {
        _supportsNano = supportsNano;
      });
    }
  }

  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      final online = !connectivityResult.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOnline = online;
        });
      }
    } catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text.trim(),
          isUser: true,
          isOffline: !_isOnline,
          timestamp: _formatNow(),
        ),
      );
    });
    _controller.clear();
    _scrollToBottom();

    // Recheck network automatically
    await _checkNetworkStatus();

    String aiResponseText = "";
    bool usedOffline = !_isOnline;

    if (_isOnline) {
      try {
        final model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-3.8-flash',
        );
        final response = await model.generateContent([
          Content.text(
            "You are Flood Light AI, an expert emergency and disaster safety assistant. Answer this query helpfully, concisely, and accurately: $text",
          ),
        ]);
        aiResponseText =
            response.text ?? "I couldn't generate a response at the moment.";
        usedOffline = false;
      } catch (e) {
        aiResponseText =
            "Cloud Gemini is temporarily unavailable. Please retry this question.";
        usedOffline = false;
      }
    } else {
      aiResponseText = OfflineAiEngine.generateResponse(
        text,
        supportsNano: _supportsNano,
      );
      usedOffline = true;
    }

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: aiResponseText,
          isUser: false,
          isOffline: usedOffline,
          timestamp: _formatNow(),
        ),
      );
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatNow() {
    final now = TimeOfDay.now();
    return "${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period.name.toUpperCase()}";
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
      backgroundColor: bgWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildAutoHybridStatusBanner(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildQuickPrompts(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: bgWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 12,
      leading: IconButton(
        tooltip: "Back",
        onPressed: () => Navigator.of(context).maybePop(),
        style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
        icon: const Icon(Icons.arrow_back, color: textDark, size: 20),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            "Flood Light AI",
            style: TextStyle(
              color: darkIndigo,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Automatic Hybrid Routing (No Manual Switch)",
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  /// Clean auto-switching banner matching HomeScreen card design
  Widget _buildAutoHybridStatusBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isOnline ? const Color(0xFFEEF2FF) : const Color(0xFFF1F8F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isOnline ? Colors.indigo.shade200 : Colors.green.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _isOnline ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
              size: 20,
              color: _isOnline ? Colors.indigo.shade700 : Colors.green.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isOnline
                    ? "☁️ Automatic Mode: 100% Cloud AI (Gemini 3.8 Flash) Active"
                    : _supportsNano
                        ? "⚡ Automatic Mode: Gemini Nano 4 Edge AI Active"
                        : "⚡ Automatic Mode: Offline Emergency Guidance Active",
                style: const TextStyle(
                  fontSize: 13,
                  color: textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: primaryIndigo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isOffline
                          ? Colors.green.shade50
                          : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: msg.isOffline
                            ? Colors.green.shade200
                            : Colors.indigo.shade200,
                      ),
                    ),
                    child: Text(
                      msg.isOffline
                          ? (_supportsNano
                              ? "⚡ Gemini Nano 4"
                              : "⚡ Offline Emergency AI")
                          : "☁️ Gemini 3.8 Flash",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: msg.isOffline
                            ? Colors.green.shade800
                            : Colors.indigo.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: msg.isUser ? primaryIndigo : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 6),
                bottomRight: Radius.circular(msg.isUser ? 6 : 18),
              ),
              border: msg.isUser
                  ? null
                  : Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: msg.isUser
                      ? primaryIndigo.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : textDark,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Text(
              msg.timestamp,
              style: const TextStyle(
                fontSize: 10,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            elevation: 0,
            pressElevation: 0,
            backgroundColor: Colors.indigo.shade50,
            side: BorderSide(color: primaryIndigo.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _quickPrompts[index],
                style: const TextStyle(
                  color: primaryIndigo,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onPressed: () => _sendMessage(_quickPrompts[index]),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(color: textDark, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: "Ask for help or guidance...",
                        hintStyle: TextStyle(color: textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(18, 15, 12, 15),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: primaryIndigo,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryIndigo.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
