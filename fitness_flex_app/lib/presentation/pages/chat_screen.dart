import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  File? _pendingImage; // <-- Store image until send

  @override
  void initState() {
    super.initState();
    _addMessage("Hey there! I'm Coach AI 💪\nWhat's your fitness goal today?", false);
  }

  void _handleSendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    // Add user message (text and/or image)
    if (_pendingImage != null) {
      _addImageMessage(_pendingImage!);
    }
    if (text.isNotEmpty) {
      _addMessage(text, true);
    }
    _messageController.clear();
    _scrollToBottom();

    setState(() {
      _messages.add(ChatMessage(isUser: false, isTyping: true));
    });
    _scrollToBottom();

    String? aiResponse;
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

    setState(() {
      _messages.removeLast();
      _pendingImage = null; // Clear after sending
    });

    if (aiResponse != null) {
      _addMessage(aiResponse, false);
      _scrollToBottom();
    }
  }

  void _handleSendImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() {
      _pendingImage = File(image.path);
    });
  }

  // ✅ Universal API call (works on Web, Android, iOS, Desktop)
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
          return "Food: ${decoded['food']}\n"
              "Calories: ${decoded['calories']} kcal\n"
              "Protein: ${decoded['protein_g']}g\n"
              "Carbs: ${decoded['carbs_g']}g\n"
              "Fat: ${decoded['fat_g']}g\n"
              "Notes: ${decoded['notes']}";
        } else {
          return decoded['reply'] ?? "Sorry, I couldn't process that.";
        }
      } else {
        return "Error: ${response.statusCode} ${response.body}";
      }
    } catch (err) {
      return "Network error: $err";
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _addImageMessage(File imageFile) {
    setState(() {
      _messages.add(ChatMessage(imageFile: imageFile, isUser: true));
    });
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Fitness Coach',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.grey[50]!],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.isTyping) {
                    return _buildTypingIndicator();
                  }
                  return message.isUser
                      ? _buildUserMessage(message)
                      : _buildBotMessage(message);
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.imageFile != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          message.imageFile!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[500],
            child: const Text('🏋️', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text!,
                style: TextStyle(
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[500],
            child: const Text('🏋️', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Dot(),
                _Dot(),
                _Dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingImage != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _pendingImage!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _pendingImage = null;
                    });
                  },
                ),
              ],
            ),
          Row(
            children: [
              PopupMenuButton<ImageSource>(
                icon: Icon(Icons.add_circle, color: Colors.blue[600]),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ImageSource.camera,
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ImageSource.gallery,
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                ],
                onSelected: _handleSendImage,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Ask Coach AI about nutrition or workouts...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: Colors.blue[600]),
                        onPressed: _handleSendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String? text;
  final File? imageFile;
  final bool isUser;
  final bool isTyping;

  ChatMessage({
    this.text,
    this.imageFile,
    required this.isUser,
    this.isTyping = false,
  });
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 4),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}
