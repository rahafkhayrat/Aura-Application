import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../services/api_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  int _distractionCounter = 0;
  int _lookAwayCounter = 0;
  int _phoneUseCounter = 0;
  bool _showBreakSuggestion = false;
  bool _showWarning = false;
  Timer? _analysisTimer;
  Timer? _breakTimer;
  Timer? _warningTimer;
  Timer? _geminiSaveTimer; // New timer for saving Gemini responses
  List<String> _emotionHistory = [];
  List<String> _distractionHistory = [];
  int _focusTime = 0;
  int _breakTime = 0;
  int _totalDistractions = 0;
  int _consecutiveLookAways = 0;
  
  // Performance monitoring for real-time processing
  int _analysisCount = 0;
  int _successfulAnalyses = 0;
  double _averageResponseTime = 0.0;
  DateTime? _lastAnalysisStart;
  
  // Face detection tracking with improved logic
  bool _currentFaceDetected = false;
  int _faceDetectionStreak = 0; // Track consecutive face detections
  int _noFaceStreak = 0; // Track consecutive no-face detections
  bool _isOnBreak = false; // Track if user is on break
  DateTime? _lastGeminiSave; // Track last Gemini response save
  String _lastGeminiActivity = 'unknown'; // Track last Gemini activity detection

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startContinuousAnalysis();
    _startGeminiSaveTimer(); // Start periodic Gemini response saving
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _analysisTimer?.cancel();
    _breakTimer?.cancel();
    _warningTimer?.cancel();
    _geminiSaveTimer?.cancel(); // Cancel Gemini save timer
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorDialog('Camera Error', 'Failed to initialize camera. Please check permissions.');
    }
  }

  void _startContinuousAnalysis() {
    // Real-time analysis with adaptive timing (reduced frequency to avoid rate limits)
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (_isInitialized && !_isAnalyzing && !_isOnBreak) {
        _analyzeCurrentFrame();
      }
    });
  }

  void _startGeminiSaveTimer() {
    // Save Gemini responses every minute
    _geminiSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _saveGeminiResponse();
    });
  }

  Future<void> _saveGeminiResponse() async {
    try {
      // Create a summary of the current session for Gemini
      final sessionSummary = {
        'focus_time': _focusTime,
        'total_distractions': _totalDistractions,
        'emotion_history': _emotionHistory.take(10).toList(), // Last 10 emotions
        'current_status': _getCurrentStatus(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send to backend for Gemini processing
      await ApiService.sendChatMessage(
        'Session Update: ${sessionSummary['current_status']}. '
        'Focus time: ${(_focusTime ~/ 60).toString().padLeft(2, '0')}:${(_focusTime % 60).toString().padLeft(2, '0')}. '
        'Distractions: $_totalDistractions. '
        'Recent emotions: ${_emotionHistory.take(5).join(', ')}. '
        'Face detection streak: $_faceDetectionStreak, No-face streak: $_noFaceStreak'
      );

      _lastGeminiSave = DateTime.now();
      print('✅ Gemini response saved at ${_lastGeminiSave}');
    } catch (e) {
      print('❌ Failed to save Gemini response: $e');
    }
  }

  String _getCurrentStatus() {
    if (_isOnBreak) return 'On break';
    if (_showBreakSuggestion) return 'Break suggested';
    if (_showWarning) return 'Warning shown';
    if (!_currentFaceDetected) return 'Not studying (face not detected or not studying activity)';
    if (_lookAwayCounter > 0) return 'Looking away from study area';
    return 'Studying (confirmed by Gemini analysis)';
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _lastAnalysisStart = DateTime.now();
    _analysisCount++;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Optimized image capture for real-time processing
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Compress image for faster transmission and processing
      final compressedBytes = await _compressImage(bytes);
      final imageBase64 = base64Encode(compressedBytes);

      // Use timeout for faster response with real-time optimization
      final analysis = await ApiService.analyzeEmotion(image: imageBase64, realTime: true)
          .timeout(const Duration(seconds: 3), onTimeout: () {
        return {'error': 'timeout', 'face': null};
      });
      
      String emotion = 'neutral';
      bool faceDetected = false;
      bool isStudying = false;

      if (analysis['face'] != null) {
        final face = analysis['face'];
        emotion = (face['emotion'] ?? 'neutral').toString();
        faceDetected = face['face_detected'] ?? false;
        
        // Get study activity from Gemini analysis
        String studyActivity = face['study_activity'] ?? 'unknown';
        _lastGeminiActivity = studyActivity;
        
        // Debug logging
        print('🔍 Gemini Activity: $studyActivity, Face Detected: $faceDetected, Is Studying: $isStudying');
        isStudying = studyActivity == 'studying' || 
                    studyActivity == 'studying_at_screen' ||
                    studyActivity == 'reading_book';
        
        // Improved face detection logic with streak tracking
        if (faceDetected) {
          _faceDetectionStreak++;
          _noFaceStreak = 0;
          
          // Only consider face detected if we have a consistent streak
          if (_faceDetectionStreak >= 2) {
            faceDetected = true;
          } else {
            faceDetected = false; // Still building streak
          }
        } else {
          _noFaceStreak++;
          _faceDetectionStreak = 0;
          
          // Only consider no face if we have a consistent streak
          if (_noFaceStreak >= 3) {
            faceDetected = false;
          } else {
            faceDetected = true; // Still building streak
          }
        }
        
        // Update tracking based on Gemini's study activity assessment
        setState(() {
          _currentFaceDetected = faceDetected && isStudying;
        });
      } else {
        // No face data - increment no-face streak
        _noFaceStreak++;
        _faceDetectionStreak = 0;
        faceDetected = false;
        isStudying = false;
        setState(() {
          _currentFaceDetected = false;
        });
      }

      setState(() {
        _emotionHistory.add(emotion);
        
        // Keep only last 20 emotions for analysis
        if (_emotionHistory.length > 20) {
          _emotionHistory.removeAt(0);
        }
      });

      // Use Gemini's assessment for distraction checking
      _checkDistractionLevel(faceDetected && isStudying);
      _updateFocusTime();

      // Update performance metrics
      if (_lastAnalysisStart != null) {
        final responseTime = DateTime.now().difference(_lastAnalysisStart!).inMilliseconds;
        _averageResponseTime = (_averageResponseTime * (_successfulAnalyses) + responseTime) / (_successfulAnalyses + 1);
        _successfulAnalyses++;
        
        // Log performance for debugging
        if (_analysisCount % 10 == 0) {
          print('📊 Analysis Performance: ${_successfulAnalyses}/${_analysisCount} successful, '
                'Avg response: ${_averageResponseTime.toStringAsFixed(1)}ms');
        }
      }

    } catch (e) {
      print('Frame analysis error: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
      
      // Adjust timing based on performance
      _adjustAnalysisTiming();
    }
  }

  void _checkDistractionLevel(bool faceDetected) {
    // Don't check for distractions during breaks
    if (_breakTime > 0 || _isOnBreak) {
      return;
    }
    
    // Check for look-away (no face detected)
    if (!faceDetected) {
      _lookAwayCounter++;
      _consecutiveLookAways++;
      
      // Check for phone use (looking down frequently)
      if (_consecutiveLookAways >= 3) {
        _phoneUseCounter++;
        _distractionHistory.add('phone_use');
      }
      
      // More lenient timing for study environments
      // Warning after 8 seconds of looking away (increased for study flexibility)
      if (_lookAwayCounter >= 8 && !_showWarning) {
        _showDistractionWarning('Looking away from study area');
      }
      
      // Break suggestion after 15 seconds of looking away (increased for study flexibility)
      if (_lookAwayCounter >= 15 && !_showBreakSuggestion) {
        _suggestBreak('You\'ve been looking away for too long');
      }
      
      // Auto-start break after 30 seconds of looking away
      if (_lookAwayCounter >= 30 && !_isOnBreak) {
        _startAutoBreak();
      }
    } else {
      // Face detected - reset look-away counters
      _lookAwayCounter = 0;
      _consecutiveLookAways = 0;
      
      // Check for emotional distraction (only if face is clearly visible)
      if (_emotionHistory.isNotEmpty) {
        final recentEmotions = _emotionHistory.length >= 5 
            ? _emotionHistory.sublist(_emotionHistory.length - 5) 
            : _emotionHistory;
        final distractedEmotions = recentEmotions.where((e) => 
          e == 'sad' || e == 'angry' || e == 'fear' || e == 'disgust'
        ).length;

        if (distractedEmotions >= 3) {
          _distractionCounter++;
          _distractionHistory.add('emotional_distraction');
          
          if (_distractionCounter >= 3 && !_showBreakSuggestion) {
            _suggestBreak('You seem distracted. Time for a break?');
          }
        } else {
          _distractionCounter = (_distractionCounter - 1).clamp(0, double.infinity).toInt();
        }
      }
    }
    
    // Update total distractions
    _totalDistractions = _distractionHistory.length;
  }

  void _startAutoBreak() {
    setState(() {
      _isOnBreak = true;
      _showBreakSuggestion = false;
      _showWarning = false;
    });

    // Show auto-break dialog
    _showAutoBreakDialog();
  }

  void _showAutoBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              Text(
                'Auto-Break Started',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'I noticed you\'ve been away for a while. I\'ve started a break for you. '
                'Take this time to rest or come back when you\'re ready to continue studying.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Analysis will resume when you return to the camera',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeFromBreak();
              },
              child: Text(
                'Resume Now',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startBreakTimer(5); // Start 5-minute break
              },
              child: Text(
                'Take 5-Min Break',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resumeFromBreak() {
    setState(() {
      _isOnBreak = false;
      _lookAwayCounter = 0;
      _consecutiveLookAways = 0;
      _distractionCounter = 0;
      _faceDetectionStreak = 0;
      _noFaceStreak = 0;
    });

    // Resume analysis
    _startContinuousAnalysis();
  }

  void _showDistractionWarning(String message) {
    setState(() {
      _showWarning = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Auto-hide warning after 3 seconds
    _warningTimer?.cancel();
    _warningTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showWarning = false;
      });
    });
  }

  void _suggestBreak([String? reason]) {
    setState(() {
      _showBreakSuggestion = true;
    });

    _showBreakDialog(reason);
  }

  void _showBreakDialog([String? reason]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Row(
            children: [
              Icon(Icons.coffee, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              Text(
                'Time for a Break!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reason ?? 'I noticed you might be getting distracted. Taking a short break can help you refocus!',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              _buildBreakSuggestionCard(
                'Quick Stretch',
                'Stand up and stretch for 2 minutes',
                Icons.accessibility,
                Colors.green,
              ),
              const SizedBox(height: 10),
              _buildBreakSuggestionCard(
                'Deep Breathing',
                'Take 5 deep breaths to reset',
                Icons.air,
                Colors.blue,
              ),
              const SizedBox(height: 10),
              _buildBreakSuggestionCard(
                'Eye Rest',
                'Look away from screen for 1 minute',
                Icons.visibility,
                Colors.purple,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showBreakDurationDialog();
              },
              child: Text(
                'Take Break',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showBreakSuggestion = false;
                  _distractionCounter = 0;
                  _lookAwayCounter = 0;
                });
              },
              child: Text(
                'Continue Studying',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreakSuggestionCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBreakDurationDialog() {
    int selectedMinutes = 5;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18122B),
              title: Row(
                children: [
                  Icon(Icons.timer, color: Colors.green, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    'Choose Break Duration',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How long would you like your break to be?',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationButton(1, selectedMinutes, setState),
                      _buildDurationButton(3, selectedMinutes, setState),
                      _buildDurationButton(5, selectedMinutes, setState),
                      _buildDurationButton(10, selectedMinutes, setState),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startBreakTimer(selectedMinutes);
                  },
                  child: Text(
                    'Start Break',
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDurationButton(int minutes, int selected, Function setState) {
    final isSelected = minutes == selected;
    return GestureDetector(
      onTap: () => setState(() => selected = minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.green.withOpacity(0.3),
          ),
        ),
        child: Text(
          '${minutes}m',
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.green,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _startBreakTimer([int minutes = 5]) {
    setState(() {
      _showBreakSuggestion = false;
      _distractionCounter = 0;
      _lookAwayCounter = 0;
      _breakTime = minutes * 60; // Convert minutes to seconds
      _isOnBreak = true; // Mark as on break
    });

    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _breakTime--;
      });

      if (_breakTime <= 0) {
        timer.cancel();
        _showBreakEndDialog();
      }
    });
  }

  void _showBreakEndDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                'Break Complete!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Great job taking a break! You\'re now refreshed and ready to continue studying.',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _breakTime = 0;
                });
              },
              child: Text(
                'Continue Studying',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateFocusTime() {
    // Only update focus time when not on break and not showing break suggestion
    if (_breakTime == 0 && !_showBreakSuggestion) {
      setState(() {
        _focusTime++;
      });
    }
  }

  // Image compression for faster real-time processing
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Decode image
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 640,  // Reduce resolution for faster processing
        targetHeight: 480,
      );
      
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      
      return data!.buffer.asUint8List();
    } catch (e) {
      print('Image compression error: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  // Adaptive analysis timing based on system performance
  void _adjustAnalysisTiming() {
    // Dynamically adjust timing based on analysis performance
    if (_isAnalyzing) {
      // If analysis is taking too long, increase interval
      _analysisTimer?.cancel();
      _analysisTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (_isInitialized && !_isAnalyzing) {
          _analyzeCurrentFrame();
        }
      });
    } else {
      // If analysis is fast, decrease interval for more responsive detection
      _analysisTimer?.cancel();
      _analysisTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
        if (_isInitialized && !_isAnalyzing) {
          _analyzeCurrentFrame();
        }
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
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
              // Header
              _buildHeader(),
              
              // Video Call Area
              Expanded(
                child: _buildVideoCallArea(),
              ),
              
              // Controls and Status
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Session',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AI Mood Monitoring Active',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (_showBreakSuggestion) {
      statusColor = Colors.orange;
      statusText = 'Break Suggested';
      statusIcon = Icons.coffee;
    } else if (_breakTime > 0) {
      statusColor = Colors.green;
      statusText = 'On Break';
      statusIcon = Icons.timer;
    } else {
      statusColor = Colors.blue;
      statusText = 'Focusing';
      statusIcon = Icons.psychology;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            
            // Distraction Status (hidden emotion display)
            Positioned(
              top: 16,
              left: 16,
              child: _buildDistractionStatus(),
            ),
            
            // Break Timer
            if (_breakTime > 0)
              Positioned(
                top: 16,
                right: 16,
                child: _buildBreakTimer(),
              ),
            
            // Analysis Indicator
            if (_isAnalyzing)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildAnalysisIndicator(),
              ),
            
            // Gemini Activity Debug (only show in debug mode)
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildGeminiActivityIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractionStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (_showWarning) {
      statusColor = Colors.orange;
      statusText = 'Warning';
      statusIcon = Icons.warning;
    } else if (_showBreakSuggestion) {
      statusColor = Colors.red;
      statusText = 'Distracted';
      statusIcon = Icons.visibility_off;
    } else if (!_currentFaceDetected) {
      // Use Gemini activity for more specific status
      switch (_lastGeminiActivity) {
        case 'not_in_frame':
          statusColor = Colors.red;
          statusText = 'Not Visible';
          statusIcon = Icons.person_off;
          break;
        case 'using_phone':
          statusColor = Colors.red;
          statusText = 'Using Phone';
          statusIcon = Icons.phone;
          break;
        case 'looking_away':
          statusColor = Colors.orange;
          statusText = 'Looking Away';
          statusIcon = Icons.visibility_off;
          break;
        default:
          statusColor = Colors.red;
          statusText = 'Not Studying';
          statusIcon = Icons.person_off;
      }
    } else if (_lookAwayCounter > 0) {
      statusColor = Colors.yellow;
      statusText = 'Looking Away';
      statusIcon = Icons.visibility;
    } else {
      // Use Gemini activity for study status
      switch (_lastGeminiActivity) {
        case 'studying_at_screen':
          statusColor = Colors.green;
          statusText = 'Studying';
          statusIcon = Icons.menu_book;
          break;
        case 'reading_book':
          statusColor = Colors.blue;
          statusText = 'Reading';
          statusIcon = Icons.book;
          break;
        default:
          statusColor = Colors.green;
          statusText = 'Studying';
          statusIcon = Icons.menu_book;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_lookAwayCounter > 0)
            Text(
              '${_lookAwayCounter}s',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakTimer() {
    final minutes = _breakTime ~/ 60;
    final seconds = _breakTime % 60;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.timer, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analyzing...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              if (_averageResponseTime > 0)
                Text(
                  '${_averageResponseTime.toStringAsFixed(0)}ms',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiActivityIndicator() {
    Color activityColor;
    IconData activityIcon;
    
    switch (_lastGeminiActivity) {
      case 'studying':
      case 'studying_at_screen':
        activityColor = Colors.green;
        activityIcon = Icons.menu_book;
        break;
      case 'reading_book':
        activityColor = Colors.blue;
        activityIcon = Icons.book;
        break;
      case 'using_phone':
        activityColor = Colors.red;
        activityIcon = Icons.phone;
        break;
      case 'looking_away':
        activityColor = Colors.orange;
        activityIcon = Icons.visibility_off;
        break;
      case 'not_in_frame':
        activityColor = Colors.grey;
        activityIcon = Icons.person_off;
        break;
      default:
        activityColor = Colors.purple;
        activityIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: activityColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(activityIcon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            'Gemini: ${_lastGeminiActivity.replaceAll('_', ' ')}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Focus Time',
                '${(_focusTime ~/ 60).toString().padLeft(2, '0')}:${(_focusTime % 60).toString().padLeft(2, '0')}',
                Icons.timer,
                Colors.blue,
              ),
              _buildStatCard(
                'Look Aways',
                '$_totalDistractions',
                Icons.visibility_off,
                Colors.orange,
              ),
              _buildStatCard(
                'Phone Use',
                '$_phoneUseCounter',
                Icons.phone,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Performance Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Analysis Rate',
                '${_analysisCount > 0 ? (_successfulAnalyses / _analysisCount * 100).toStringAsFixed(0) : 0}%',
                Icons.speed,
                Colors.green,
              ),
              _buildStatCard(
                'Response Time',
                '${_averageResponseTime.toStringAsFixed(0)}ms',
                Icons.timer_outlined,
                Colors.purple,
              ),
              _buildStatCard(
                'FPS',
                '${_averageResponseTime > 0 ? (1000 / _averageResponseTime).toStringAsFixed(1) : 0}',
                Icons.videocam,
                Colors.cyan,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          
          
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                'Manual Break',
                Icons.coffee,
                Colors.orange,
                () => _suggestBreak(),
              ),
              _buildControlButton(
                'End Session',
                Icons.stop,
                Colors.red,
                () => _endSession(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Text(
            'End Study Session?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to end this study session? Your progress will be saved.',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: Text(
                'End Session',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
