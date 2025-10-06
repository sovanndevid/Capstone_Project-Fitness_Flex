// chat_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// ====== Persona config (easy to tweak) ======================================
const _coachName = 'Maya'; // human-friendly coach name
const _coachHint =
    "Chat with $_coachName — workouts, meals, or snap a food photo 🍎";
// If you have a portrait in assets, set this path. Leave null to use emoji.
const String? _coachAvatarAsset = 'assets/images/coach_maya.jpg';
const String _coachEmojiFallback = '🙂';
/// ============================================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _pendingImage;
  bool _sending = false;

  final List<String> _suggestions = const [
    'Log a meal from photo',
    'High-protein lunch ideas',
    'Form tips: deadlift',
    'How many calories in pho?',
    'Build workout plan',
  ];

  @override
  void initState() {
    super.initState();
    _addMessage(
      "Hey! I’m $_coachName, your friendly fitness coach 🙌\nHow can I help today?",
      false,
    );
  }

  // ---------------------- Sending ----------------------
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    if (_pendingImage != null) _addImageMessage(_pendingImage!);
    if (text.isNotEmpty) _addMessage(text, true);
    _messageController.clear();
    _scrollToBottom();

    setState(() => _sending = true);

    String? aiResponse;
    try {
      if (_pendingImage != null) {
        final bytes = await _pendingImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        aiResponse = await _askAI(
          text.isEmpty ? "What food is this and how many calories?" : text,
          imageBase64: base64Image,
        );
      } else {
        aiResponse = await _askAI(text);
      }
    } finally {
      setState(() {
        _pendingImage = null;
        _sending = false;
      });
    }

    if (aiResponse != null) {
      _addMessage(aiResponse, false);
      _scrollToBottom();
    }
  }

  Future<void> _handlePickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;
    setState(() => _pendingImage = File(image.path));
  }

  // ---------------------- API ----------------------
  Future<String?> _askAI(String message, {String? imageBase64}) async {
    const String apiUrl =
        "https://studybuddy-backend-git-main-sovanndevidnong-admins-projects.vercel.app/api/chat";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'message': message,
          if (imageBase64 != null) 'imageBase64': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded.containsKey('food')) {
          return "Here’s what I see:\n"
              "• Food: ${decoded['food']}\n"
              "• Calories: ${decoded['calories']} kcal\n"
              "• Protein: ${decoded['protein_g']} g • "
              "Carbs: ${decoded['carbs_g']} g • "
              "Fat: ${decoded['fat_g']} g\n"
              "Notes: ${decoded['notes']}";
        }
        return decoded['reply'] ?? "Hmm, I couldn’t process that—try rephrasing?";
      } else {
        return "Server error: ${response.statusCode} ${response.body}";
      }
    } catch (err) {
      return "Network error: $err";
    }
  }

  // ---------------------- Helpers ----------------------
  void _addMessage(String text, bool isUser) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: isUser)));
  }

  void _addImageMessage(File imageFile) {
    setState(() => _messages.add(ChatMessage(imageFile: imageFile, isUser: true)));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF3F7BFF);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoachAvatar(size: 30),
            const SizedBox(width: 10),
            Text(
              _coachName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 14,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEFF4FF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7FAFF), Color(0xFFFDFDFD)],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return message.isUser
                      ? _UserBubble(message: message)
                      : _BotBubble(message: message);
                },
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => ActionChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black.withOpacity(.06)),
                  label: Text(
                    _suggestions[i],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                  onPressed: () {
                    _messageController.text = _suggestions[i];
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  },
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _suggestions.length,
              ),
            ),
          _Composer(
            controller: _messageController,
            hintText: _coachHint,
            hasPendingImage: _pendingImage != null,
            pendingPreview: _pendingImage == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_pendingImage!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
            onClearImage: () => setState(() => _pendingImage = null),
            onPickCamera: () => _handlePickImage(ImageSource.camera),
            onPickGallery: () => _handlePickImage(ImageSource.gallery),
            onSend: _sending ? null : _handleSendMessage,
            sending: _sending,
          ),
        ],
      ),
    );
  }
}

/// ---------------------- Message Bubbles ----------------------
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF3F7BFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6AA7FF), Color(0xFF3F7BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: blue.withOpacity(.28), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(message.imageFile!, height: 180, fit: BoxFit.cover),
                        ),
                      ),
                    if (message.text != null)
                      Text(
                        message.text!,
                        style: const TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CoachAvatar(size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black.withOpacity(.06)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                message.text ?? '',
                style: TextStyle(color: Colors.grey.shade800, height: 1.45, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------- Coach Avatar ----------------------
class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) {
    final double border = size >= 34 ? 2 : 1.5;
    final avatar = _coachAvatarAsset == null
        ? Center(child: Text(_coachEmojiFallback, style: TextStyle(fontSize: size * .55)))
        : ClipOval(
            child: Image.asset(
              _coachAvatarAsset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Center(child: Text(_coachEmojiFallback, style: TextStyle(fontSize: size * .55))),
            ),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: border),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB199), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatar,
    );
  }
}

/// ---------------------- Composer ----------------------
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hintText,
    required this.hasPendingImage,
    required this.pendingPreview,
    required this.onClearImage,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final String hintText;
  final bool hasPendingImage;
  final Widget? pendingPreview;
  final VoidCallback onClearImage;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback? onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final canSend = onSend != null && !sending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPendingImage && pendingPreview != null)
              _PendingPreviewCard(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pendingPreview!,
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: onClearImage,
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AttachButton(onCamera: onPickCamera, onGallery: onPickGallery),
                const SizedBox(width: 10),
                Expanded(
                  child: _GlassPill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: hintText,
                          hintStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .1,
                            color: Color(0x99000000),
                            height: 1.25,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        onSubmitted: (_) => onSend?.call(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SendButton(enabled: canSend, onTap: onSend, sending: sending),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0x40A3B8FF), Color(0x40FFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(.86),
          border: Border.all(color: Colors.black.withOpacity(.06)),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
            BoxShadow(color: Color(0x0D3F7BFF), blurRadius: 18, spreadRadius: -6, offset: Offset(0, 12)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PendingPreviewCard extends StatelessWidget {
  const _PendingPreviewCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0x10A3B8FF), Color(0x10FFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(.06)),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6AA7FF), Color(0xFF3F7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        tooltip: 'Attach',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 0,
            child: Row(children: [Icon(Icons.camera_alt, size: 20), SizedBox(width: 8), Text('Take Photo')]),
          ),
          PopupMenuItem(
            value: 1,
            child: Row(children: [Icon(Icons.photo_library, size: 20), SizedBox(width: 8), Text('Choose from Gallery')]),
          ),
        ],
        onSelected: (v) => v == 0 ? onCamera() : onGallery(),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap, required this.sending});
  final bool enabled;
  final VoidCallback? onTap;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF3F7BFF);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF6AA7FF), Color(0xFF3F7BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : Colors.grey.shade400,
          boxShadow: [if (enabled) BoxShadow(color: base.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: sending
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }
}

/// ---------------------- Data model ----------------------
class ChatMessage {
  final String? text;
  final File? imageFile;
  final bool isUser;
  ChatMessage({this.text, this.imageFile, required this.isUser});
}
