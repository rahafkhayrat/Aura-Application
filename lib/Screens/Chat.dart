import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/emotion_service.dart';
import 'package:image_picker/image_picker.dart';

class Chat extends StatefulWidget {
  final bool autoOpenCamera;
  
  const Chat({super.key, this.autoOpenCamera = false});

  @override
  State<Chat> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<Chat> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _addWelcomeMessage();
    
    // Auto-open camera if requested
    if (widget.autoOpenCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickAndAnalyzeFace();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await ApiService.initialize();
    await EmotionService.initialize();
  }

  void _addWelcomeMessage() {
    _messages.add(Message(
      text: "Hello! I'm Aura, your AI wellness assistant. How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isLoading = true;
    });

    try {
      // Analyze text sentiment first
      final sentiment = await EmotionService.analyzeTextSentiment(text);
      
      // Send message to AI backend
      final response = await ApiService.sendChatMessage(text);
      
      setState(() {
        _messages.add(Message(
          text: response['response'] ?? "I'm here to help you with your emotions. How are you feeling?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Show sentiment analysis result
      if (sentiment['sentiment'] != null) {
        _showSentimentResult(sentiment);
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: "Sorry, I'm having trouble connecting right now. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      print('Chat error: $e');
    }
  }

  void _showSentimentResult(Map<String, dynamic> sentiment) {
    final sentimentText = sentiment['sentiment'] ?? 'neutral';
    final confidence = sentiment['confidence'] ?? 0.0;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detected emotion: $sentimentText (${(confidence * 100).toStringAsFixed(1)}% confidence)'),
        backgroundColor: _getSentimentColor(sentimentText),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildMessage(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: message.isUser
                ? [const Color(0xFF9B4DCA), const Color(0xFF7B2CBF)]
                : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          border: Border.all(
            color: message.isUser 
                ? Colors.transparent 
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.poppins(
                color: message.isUser ? Colors.white : Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.poppins(
                    color: message.isUser ? Colors.white70 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (!message.isUser && message.text.contains("I'm here to help")) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAndAnalyzeFace() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyzing face...')),
      );

      final analysis = await ApiService.analyzeEmotion(image: imageBase64);

      // Try to extract face emotion; fall back to overall/sentiment
      String label = 'neutral';
      double confidence = 0.5;
      if (analysis['face'] != null) {
        final face = analysis['face'];
        label = (face['emotion'] ?? face['sentiment'] ?? 'neutral').toString();
        confidence = (face['confidence'] ?? 0.5).toDouble();
      } else if (analysis['overall'] != null) {
        final overall = analysis['overall'];
        label = (overall['emotion'] ?? 'neutral').toString();
        confidence = (overall['confidence'] ?? 0.5).toDouble();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detected facial emotion: $label (${(confidence * 100).toStringAsFixed(1)}%)'),
          backgroundColor: _getSentimentColor(label),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face analysis failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF2D1B69), Color(0xFF9B4DCA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const CircleAvatar(
                      backgroundImage: AssetImage('Images/Aura.webp'),
                      radius: 20,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aura AI Assistant',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emotion-Aware Chat',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[_messages.length - 1 - index]);
                  },
                ),
              ),

              // Loading Indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aura is thinking...',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Input Area
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions, color: Colors.white70),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'How are you feeling today?',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (text) {
                          // Text change handling removed for simplicity
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_camera, color: Colors.white70),
                      onPressed: _pickAndAnalyzeFace,
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9B4DCA), Color(0xFF7B2CBF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
