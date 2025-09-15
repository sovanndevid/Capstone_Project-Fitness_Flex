import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();

  void _handleSendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addMessage(text, true);
    _messageController.clear();

    // TODO: Replace with your actual backend call
    String? aiResponse = await _askAI(text);

    if (aiResponse != null) {
      _addMessage(aiResponse, false);
    }
  }

  void _handleSendImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    _addImageMessage(File(image.path));

    // TODO: Add your food detection and calorie analysis here
    String detectedFoods = "apple, banana"; // Example data
    String calorieQuestion = "How many calories are in $detectedFoods?";

    String? aiResponse = await _askAI(calorieQuestion);

    if (aiResponse != null) {
      _addMessage(aiResponse, false);
    }
  }

  Future<String?> _askAI(String message) async {
    try {
      // This is your existing backend endpoint
      final response =
          await HttpClient().postUrl(
              Uri.parse(
                "https://studybuddy-backend-git-main-sovanndevidnong-admins-projects.vercel.app/api/chat",
              ),
            )
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'message': message}));

      final data = await response.close();
      final jsonResponse = await data.transform(utf8.decoder).join();
      final decoded = jsonDecode(jsonResponse);
      return decoded['reply'] ?? "Sorry, I couldn't respond.";
    } catch (err) {
      return "Error contacting AI.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return message.isUser
                    ? UserMessageBubble(
                        text: message.text,
                        imageFile: message.imageFile,
                      )
                    : BotMessageBubble(text: message.text!);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _handleSendImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: () => _handleSendImage(ImageSource.gallery),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask about workouts or calories...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
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

  ChatMessage({this.text, this.imageFile, required this.isUser});
}

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, this.text, this.imageFile});

  final String? text;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (imageFile != null)
              Image.file(
                imageFile!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            if (text != null) Text(text!),
          ],
        ),
      ),
    );
  }
}

class BotMessageBubble extends StatelessWidget {
  const BotMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}
