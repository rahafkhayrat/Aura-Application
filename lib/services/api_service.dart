import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://172.18.80.1:5000';
  static const String wsUrl = 'ws://172.18.80.1:5000';
  
  static String? _authToken;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Load saved token if available
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      
      // If no token exists, create a guest user
      if (_authToken == null) {
        await _createGuestUser();
      }
      
      _initialized = true;
      print('✅ ApiService initialized');
    } catch (e) {
      print('❌ ApiService initialization failed: $e');
      _initialized = true; // Mark as initialized to prevent infinite retries
    }
  }

  static Future<void> _createGuestUser() async {
    try {
      final guestEmail = 'guest_${DateTime.now().millisecondsSinceEpoch}@aura.app';
      final guestPassword = 'guest123';
      final guestName = 'Guest User';
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': guestName,
          'email': guestEmail,
          'password': guestPassword,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        
        print('✅ Guest user created and authenticated');
      } else {
        print('⚠️ Guest user creation failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Guest user creation error: $e');
    }
  }

  static Future<void> _ensureAuthenticated() async {
    if (_authToken == null) {
      await _createGuestUser();
    }
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Authentication methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        
        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        
        return data;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Chat methods
  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    await _ensureAuthenticated();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Chat failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }

  // Emotion analysis methods
  static Future<Map<String, dynamic>> analyzeEmotion({String? text, String? image, bool realTime = false}) async {
    await _ensureAuthenticated();
    
    try {
      final Map<String, dynamic> body = {};
      if (text != null) body['text'] = text;
      if (image != null) body['image'] = image;
      if (realTime) {
        body['store_data'] = false; // Don't store real-time data
      }

      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Emotion analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Emotion analysis error: $e');
    }
  }

  // Suggestions methods
  static Future<Map<String, dynamic>> getSuggestions() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suggest'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Suggestions failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Suggestions error: $e');
    }
  }

  // Routines methods
  static Future<Map<String, dynamic>> getRoutines() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routines'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Routines failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Routines error: $e');
    }
  }

  static Future<Map<String, dynamic>> addHabit(String habitName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routines'),
        headers: _headers,
        body: jsonEncode({
          'habit': habitName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Add habit failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Add habit error: $e');
    }
  }

  static Future<Map<String, dynamic>> addFocusSession(int duration) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routines'),
        headers: _headers,
        body: jsonEncode({
          'focus_session': {'duration': duration},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Add focus session failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Add focus session error: $e');
    }
  }

  // Analytics methods
  static Future<Map<String, dynamic>> getAnalytics() async {
    await _ensureAuthenticated();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Analytics failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Analytics error: $e');
    }
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Health check error: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _authToken != null;
  
  // Get auth token
  static String? get authToken => _authToken;
}

