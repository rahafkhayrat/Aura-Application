import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class EmotionService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize emotion service
      _initialized = true;
      print('✅ EmotionService initialized');
    } catch (e) {
      print('❌ EmotionService initialization failed: $e');
      _initialized = true; // Mark as initialized to prevent infinite retries
    }
  }

  // Analyze text sentiment using backend
  static Future<Map<String, dynamic>> analyzeTextSentiment(String text) async {
    try {
      final result = await ApiService.analyzeEmotion(text: text);
      return result['analysis']?['text'] ?? {
        'sentiment': 'neutral',
        'confidence': 0.5,
        'model': 'fallback'
      };
    } catch (e) {
      print('Text sentiment analysis error: $e');
      return {
        'sentiment': 'neutral',
        'confidence': 0.5,
        'model': 'fallback'
      };
    }
  }

  // Get emotion color based on sentiment
  static Color getEmotionColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
      case 'happy':
      case 'joy':
        return Colors.green;
      case 'negative':
      case 'sad':
      case 'angry':
      case 'fear':
        return Colors.red;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  // Get emotion emoji
  static String getEmotionEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
      case 'happy':
      case 'joy':
        return '😊';
      case 'negative':
      case 'sad':
        return '😔';
      case 'angry':
        return '😠';
      case 'fear':
        return '😨';
      case 'surprise':
        return '😲';
      case 'disgust':
        return '🤢';
      default:
        return '😐';
    }
  }

  // Get emotion message
  static String getEmotionMessage(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
      case 'happy':
      case 'joy':
        return 'Great mood! Keep it up!';
      case 'negative':
      case 'sad':
        return 'It\'s okay to feel this way. You\'re not alone.';
      case 'angry':
        return 'Take a deep breath. This feeling will pass.';
      case 'fear':
        return 'You\'re safe. Focus on what you can control.';
      case 'surprise':
        return 'Life is full of unexpected moments!';
      case 'disgust':
        return 'Sometimes we need to step back and reset.';
      default:
        return 'You\'re doing great. Keep going!';
    }
  }

  // Build emotion display widget
  static Widget buildEmotionDisplay({
    required String sentiment,
    required double confidence,
    String? model,
    bool showDetails = true,
  }) {
    final color = getEmotionColor(sentiment);
    final emoji = getEmotionEmoji(sentiment);
    final message = getEmotionMessage(sentiment);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            sentiment.toUpperCase(),
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
                          Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
          if (showDetails) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(confidence * 100).toStringAsFixed(1)}% confidence',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (model != null) ...[
              const SizedBox(height: 8),
              Text(
                'Model: $model',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Build emotion trend chart data
  static List<Map<String, dynamic>> buildEmotionTrendData(List<Map<String, dynamic>> emotions) {
    if (emotions.isEmpty) return [];

    final Map<String, int> emotionCounts = {};
    
    for (final emotion in emotions) {
      final sentiment = emotion['analysis']?['text']?['sentiment'] ?? 'neutral';
      emotionCounts[sentiment] = (emotionCounts[sentiment] ?? 0) + 1;
    }

    return emotionCounts.entries.map((entry) {
      return {
        'emotion': entry.key,
        'count': entry.value,
        'color': getEmotionColor(entry.key),
        'emoji': getEmotionEmoji(entry.key),
      };
    }).toList();
  }

  // Get wellness score based on emotions
  static double calculateWellnessScore(List<Map<String, dynamic>> emotions) {
    if (emotions.isEmpty) return 0.5;

    double totalScore = 0;
    int validEmotions = 0;

    for (final emotion in emotions) {
      final sentiment = emotion['analysis']?['text']?['sentiment'];
      if (sentiment != null) {
        switch (sentiment.toLowerCase()) {
          case 'positive':
            totalScore += 1.0;
            break;
          case 'neutral':
            totalScore += 0.5;
            break;
          case 'negative':
            totalScore += 0.0;
            break;
        }
        validEmotions++;
      }
    }

    return validEmotions > 0 ? totalScore / validEmotions : 0.5;
  }

  // Build wellness indicator
  static Widget buildWellnessIndicator(double score) {
    final percentage = (score * 100).toInt();
    Color color;
    String status;
    IconData icon;

    if (score >= 0.7) {
      color = Colors.green;
      status = 'Excellent';
      icon = Icons.sentiment_very_satisfied;
    } else if (score >= 0.4) {
      color = Colors.orange;
      status = 'Good';
      icon = Icons.sentiment_satisfied;
    } else {
      color = Colors.red;
      status = 'Needs Attention';
      icon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wellness Score',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Check if service is initialized
  static bool get isInitialized => _initialized;
}

