import 'package:aura_app/Screens/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:aura_app/Screens/Account.dart';
import 'Chat.dart';
import 'Calender.dart';
import 'VideoCallScreen.dart';
import '../services/api_service.dart';
import '../services/emotion_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String email;
  final String address;
  final int age;
  final String gender;
  final String bio;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.age,
    required this.gender,
    required this.bio,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Backend integration state
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _routines = {};
  String _currentMood = 'neutral';
  double _moodScore = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Initialize backend services
    _initializeServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await ApiService.initialize();
      await EmotionService.initialize();
      await _loadUserData();
    } catch (e) {
      print('Service initialization error: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Load analytics and routines from backend
      final analytics = await ApiService.getAnalytics();
      final routines = await ApiService.getRoutines();
      
      setState(() {
        _analytics = analytics;
        _routines = routines;
      });
      
      // Update mood based on analytics
      _updateMoodFromAnalytics();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _updateMoodFromAnalytics() {
    if (_analytics['mood_trends'] != null) {
      final moodTrends = _analytics['mood_trends'];
      _currentMood = moodTrends['average_mood'] ?? 'neutral';
      _moodScore = _calculateMoodScore();
    }
  }

  double _calculateMoodScore() {
    switch (_currentMood.toLowerCase()) {
      case 'positive':
        return 0.9;
      case 'negative':
        return 0.3;
      default:
        return 0.6;
    }
  }

  Color _getMoodColor() {
    switch (_currentMood.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getMoodMessage() {
    switch (_currentMood.toLowerCase()) {
      case 'positive':
        return 'Great day to focus!';
      case 'negative':
        return 'Take care of yourself today';
      default:
        return 'Balanced and centered';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18122B),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeContent(),
            _buildAccountScreen(),
            _buildCalendarScreen(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF9B4DCA),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              "Aura",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B4DCA), Color(0xFF7B2CBF)],
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(),
                const SizedBox(height: 24),
                _buildEmotionChatSection(),
                const SizedBox(height: 20),
                _buildHabitTrackingSection(),
                const SizedBox(height: 20),
                _buildFocusMonitorSection(),
                const SizedBox(height: 20),
                _buildWellnessAnalyticsSection(),
                const SizedBox(height: 20),
                _buildQuickActionsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Hero(
            tag: 'userAvatar',
            child: CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage('Images/Aura.webp'),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMoodColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMoodMessage(),
                    style: TextStyle(color: _getMoodColor(), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _showNotifications(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChatSection() {
    return _FeatureCard(
      title: "Emotion-Aware Chat",
      icon: Icons.chat_bubble,
      color: Colors.purple,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FeatureButton(
              icon: Icons.chat,
              label: "Chat",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Chat()),
              ),
            ),
            _FeatureButton(
              icon: Icons.camera_alt,
              label: "Camera",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Chat(autoOpenCamera: true)),
              ),
            ),
            _FeatureButton(
              icon: Icons.videocam,
              label: "Study Mode",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VideoCallScreen()),
              ),
            ),
            _FeatureButton(
              icon: Icons.analytics,
              label: "Mood",
              onTap: () => _showMoodAnalysis(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitTrackingSection() {
    final habits = _routines['habits'] ?? [];
    final completedToday = habits.where((h) => h['completed_today'] == true).length;
    
    return _FeatureCard(
      title: "Habit Tracking",
      icon: Icons.track_changes,
      color: Colors.orange,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              "$completedToday/${habits.length} Habits Today",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildAddButton(),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isNotEmpty)
          Wrap(
            spacing: 8,
            children: habits.map<Widget>((habit) {
              final isCompleted = habit['completed_today'] == true;
              return _StatusChip(
                label: "${habit['name']} ${isCompleted ? '✅' : '⏳'}",
                color: isCompleted ? Colors.green : Colors.orange,
              );
            }).toList(),
          )
        else
          const Text(
            "No habits yet. Add your first habit!",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildFocusMonitorSection() {
    final focusSessions = _routines['focus_sessions'] ?? [];
    final totalMinutes = focusSessions.fold<int>(0, (int sum, dynamic session) => sum + ((session['duration'] ?? 0) as int));
    
    return _FeatureCard(
      title: "Focus Monitor",
      icon: Icons.visibility,
      color: Colors.green,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "Total Focus: ${totalMinutes}min",
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          "Start Focus Session",
          onTap: () {
            _startFocusSession(context);
          },
        ),
      ],
    );
  }

  Widget _buildWellnessAnalyticsSection() {
    final habitStreaks = _analytics['habit_streaks'] ?? {};
    final focusTime = _analytics['focus_time'] ?? {};
    
    return _FeatureCard(
      title: "Wellness Analytics",
      icon: Icons.analytics,
      color: Colors.blue,
      children: [
        _buildWellnessMetricCard(
          "Mood Score",
          "${(_moodScore * 100).toInt()}%",
          Icons.mood,
          _getMoodColor(),
          "Current mood: $_currentMood",
        ),
        const SizedBox(height: 12),
        _buildWellnessMetricCard(
          "Habit Streak",
          "${habitStreaks['streak'] ?? 0} days",
          Icons.local_fire_department,
          Colors.orange,
          "Keep it up!",
        ),
        const SizedBox(height: 12),
        _buildWellnessMetricCard(
          "Focus Time",
          "${focusTime['total_minutes'] ?? 0} min",
          Icons.timer,
          Colors.green,
          "Today's focus sessions",
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWellnessButton(
              "Daily Check-in",
              Icons.check_circle,
              () => _showDailyCheckIn(context),
            ),
            _buildWellnessButton(
              "View Trends",
              Icons.trending_up,
              () => _showWellnessTrends(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWellnessMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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

  Widget _buildWellnessButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return _FeatureCard(
      title: "Quick Actions",
      icon: Icons.flash_on,
      color: Colors.pink,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FeatureButton(
              icon: Icons.self_improvement,
              label: "Meditate",
              onTap: () => _showMeditationOptions(context),
            ),
            _FeatureButton(
              icon: Icons.air,
              label: "Breathe",
              onTap: () => _startBreathingExercise(context),
            ),
            _FeatureButton(
              icon: Icons.movie,
              label: "Fun",
              onTap: () => _showFunActivities(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountScreen() {
    return Account(
      userName: widget.userName,
      phoneNumber: widget.phoneNumber,
      email: widget.email,
      address: widget.address,
      age: widget.age,
      gender: widget.gender,
      bio: widget.bio,
    );
  }

  Widget _buildCalendarScreen(BuildContext context) {
    return const Calendar();
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF231942),
      selectedItemColor: const Color(0xFF9B4DCA),
      unselectedItemColor: Colors.white70,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Calendar",
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showAddHabitDialog(context);
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text("Add"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 0,
      ),
    );
  }

  Widget _buildActionButton(String text, {required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
      child: Text(text),
    );
  }

  // Feature dialogs and actions
  void _showMoodAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mood Analysis',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildMoodEmoji(_currentMood),
              const SizedBox(height: 16),
              Text(
                'Current Mood: $_currentMood',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                'Score: ${(_moodScore * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  color: _getMoodColor(),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodEmoji(String mood) {
    String emoji;
    
    switch (mood.toLowerCase()) {
      case 'positive':
        emoji = '😊';
        break;
      case 'negative':
        emoji = '😔';
        break;
      default:
        emoji = '😐';
    }
    
    return Text(
      emoji,
      style: const TextStyle(fontSize: 60),
    );
  }

  void _showDailyCheckIn(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Wellness Check-in',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'How are you feeling today?',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodEmojiButton('😊', 'Happy', Colors.green),
                  _buildMoodEmojiButton('😐', 'Neutral', Colors.orange),
                  _buildMoodEmojiButton('😔', 'Sad', Colors.blue),
                  _buildMoodEmojiButton('😤', 'Stressed', Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodEmojiButton(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        
        try {
          // Send mood to backend
          await ApiService.analyzeEmotion(text: "I am feeling $label today");
          
          _showFeatureDialog(
            context,
            'Mood Recorded',
            'Your mood "$label" has been recorded. Keep tracking your wellness journey!',
          );
          
          // Refresh data
          await _loadUserData();
        } catch (e) {
          _showFeatureDialog(
            context,
            'Error',
            'Failed to record mood. Please try again.',
          );
        }
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  void _showWellnessTrends(BuildContext context) {
    final habitStreaks = _analytics['habit_streaks'] ?? {};
    final focusTime = _analytics['focus_time'] ?? {};
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wellness Trends',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTrendItem(
                'Mood Score',
                '${(_moodScore * 100).toInt()}%',
                Icons.trending_up,
                _getMoodColor(),
              ),
              _buildTrendItem(
                'Habit Streak',
                '${habitStreaks['streak'] ?? 0} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildTrendItem(
                'Focus Time',
                '${focusTime['total_minutes'] ?? 0} min',
                Icons.timer,
                Colors.blue,
              ),
              _buildTrendItem(
                'Total Habits',
                '${habitStreaks['total_habits'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendItem(
    String metric,
    String value,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(metric, style: const TextStyle(color: Colors.white)),
      subtitle: Text(value, style: TextStyle(color: color)),
    );
  }

  void _startFocusSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: const Text(
            'Focus Session',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your focus duration:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationButton(context, 15),
                  _buildDurationButton(context, 25),
                  _buildDurationButton(context, 45),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationButton(BuildContext context, int duration) {
    return ElevatedButton(
      onPressed: () async {
        Navigator.of(context).pop();
        
        try {
          // Add focus session to backend
          await ApiService.addFocusSession(duration);
          
          _showFeatureDialog(
            context,
            'Focus Session Started',
            'Your $duration-minute focus session has started. Stay focused!',
          );
          
          // Refresh data
          await _loadUserData();
        } catch (e) {
          _showFeatureDialog(
            context,
            'Error',
            'Failed to start focus session. Please try again.',
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9B4DCA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('$duration min'),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final TextEditingController habitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: const Text(
            'Add New Habit',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: habitController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter habit name...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF9B4DCA)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (habitController.text.isNotEmpty) {
                  try {
                    // Add habit to backend
                    await ApiService.addHabit(habitController.text);
                    
                    Navigator.of(context).pop();
                    
                    _showFeatureDialog(
                      context,
                      'Habit Added',
                      'Your new habit "${habitController.text}" has been added successfully!',
                    );
                    
                    // Refresh data
                    await _loadUserData();
                  } catch (e) {
                    _showFeatureDialog(
                      context,
                      'Error',
                      'Failed to add habit. Please try again.',
                    );
                  }
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Color(0xFF9B4DCA)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMeditationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Meditation',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildMeditationOption(context, '5-Minute Breathing', Icons.air),
              _buildMeditationOption(
                context,
                '10-Minute Mindfulness',
                Icons.self_improvement,
              ),
              _buildMeditationOption(
                context,
                '15-Minute Body Scan',
                Icons.accessibility,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeditationOption(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9B4DCA)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).pop();
        _showFeatureDialog(
          context,
          'Meditation Started',
          'Starting $title session. Find a comfortable position and relax.',
        );
      },
    );
  }

  void _startBreathingExercise(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: const Text(
            'Breathing Exercise',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Follow the breathing guide:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              Text(
                'Inhale for 4 seconds\nHold for 4 seconds\nExhale for 4 seconds',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFeatureDialog(
                  context,
                  'Breathing Exercise',
                  'Starting 4-4-4 breathing exercise. Breathe with the rhythm.',
                );
              },
              child: const Text(
                'Start',
                style: TextStyle(color: Color(0xFF9B4DCA)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFunActivities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fun Activities',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildFunActivity(
                context,
                'Watch Funny Videos',
                Icons.video_library,
              ),
              _buildFunActivity(context, 'Play Mini Games', Icons.games),
              _buildFunActivity(context, 'Listen to Music', Icons.music_note),
              _buildFunActivity(context, 'Read Jokes', Icons.emoji_emotions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunActivity(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9B4DCA)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).pop();
        _showFeatureDialog(
          context,
          'Fun Activity',
          'Opening $title. Enjoy your break!',
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18122B),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildNotificationItem(
                'Daily Check-in',
                'How are you feeling today?',
                Icons.favorite,
              ),
              _buildNotificationItem(
                'Habit Reminder',
                'Time for your daily meditation',
                Icons.self_improvement,
              ),
              _buildNotificationItem(
                'Focus Session',
                'Your 25-min focus session starts in 5 minutes',
                Icons.timer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9B4DCA)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
    );
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18122B),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF9B4DCA)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
