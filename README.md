#  Aura Wellness AI - Complete Wellness & Emotion Recognition System

## 🎯 **Project Overview**

Aura Wellness AI is a comprehensive wellness application that combines AI-powered emotion recognition, habit tracking, and personalized wellness coaching. The system features real-time facial emotion analysis, text sentiment analysis, and intelligent wellness suggestions powered by Google's Gemini AI.

## ✨ **Key Features**

### 🤖 **AI-Powered Features**
- **Real-time Facial Emotion Recognition** using OpenCV and ML models
- **Text Sentiment Analysis** with HuggingFace models
- **AI Chat Assistant** powered by Google Gemini
- **Personalized Wellness Suggestions** based on user emotions and patterns

### 📱 **Mobile App Features**
- **Cross-platform Flutter app** (Android, iOS, Desktop)
- **Beautiful, modern UI** with gradients, animations, and professional design
- **Real-time camera integration** for facial analysis
- **Habit tracking and focus monitoring**
- **Wellness analytics and mood trends**
- **Multi-language support** (English, Arabic, Spanish, French)

### 🔧 **Backend Features**
- **Flask REST API** with comprehensive endpoints
- **Real-time WebSocket support** for live updates
- **JWT authentication** with secure user management
- **Advanced ML models** for emotion detection
- **Data analytics and insights**
- **Scalable architecture** for cloud deployment

## 🏗️ **System Architecture**

```
┌─────────────────┐     ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │     │   Python Flask  │    │   ML Models     │
│                 │     │   Backend       │    │                 │
│ • UI/UX         │◄──► │ • REST API      │◄──►│ • OpenCV        │
│ • Camera        │     │ • WebSockets    │    │ • HuggingFace   │
│ • State Mgmt    │     │ • JWT Auth      │    │ • PyTorch       │
│ • Local Storag  │     │ • Data Mgmt     │    │ • Gemini AI     │
└─────────────────┘     └─────────────────┘    └─────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**
- Python 3.10+ 
- Flutter SDK 3.0+
- Android Studio / Xcode (for mobile development)
- Google Gemini API key

### **1. Backend Setup**

```bash
# Clone the repository
git clone <repository-url>
cd aura-wellness-ai

# Create virtual environment
python -m venv aura_env_310
aura_env_310\Scripts\activate  # Windows
source aura_env_310/bin/activate  # Linux/Mac

# Install dependencies
cd backend
pip install -r requirements.txt

# Set environment variables
export GEMINI_API_KEY="your_gemini_api_key"
export SECRET_KEY="your_secret_key"
export JWT_SECRET_KEY="your_jwt_secret"

# Start the backend
python start.py
```

### **2. Frontend Setup**

```bash
# Navigate to Flutter app
cd aura_app

# Install dependencies
flutter pub get

# Run the app
flutter run -d emulator-5554  # Android
flutter run -d chrome          # Web
flutter run -d macos           # Desktop
```

### **3. Windows Batch Files (Optional)**

```bash
# Use provided batch files for easy startup
START_BACKEND.bat    # Starts backend
START_FLUTTER.bat    # Starts Flutter app
```

## 📁 **Project Structure**

```
aura-wellness-ai/
├── backend/                     # Python Flask Backend
│   ├── app.py                  # Main Flask application
│   ├── start.py                # Backend startup script
│   ├── requirements.txt        # Python dependencies
│   └── models/                 # ML model files
├── aura_app/                   # Flutter Frontend
│   ├── lib/
│   │   ├── Screens/           # App screens
│   │   │   ├── HomeScreen.dart
│   │   │   ├── Chat.dart
│   │   │   ├── Calendar.dart
│   │   │   ├── Account.dart
│   │   │   ├── Settings.dart
│   │   │   ├── LoginPage.dart
│   │   │   └── SignUp.dart
│   │   ├── services/          # API and service classes
│   │   │   ├── api_service.dart
│   │   │   └── emotion_service.dart
│   │   └── main.dart          # App entry point
│   ├── Images/                # App assets
│   └── pubspec.yaml           # Flutter dependencies
├── start_backend_simple.py     # Simplified backend startup
├── START_BACKEND.bat          # Windows backend startup
├── START_FLUTTER.bat          # Windows Flutter startup
└── README.md                  # This file
```

## 🔌 **API Endpoints**

### **Authentication**
- `POST /auth/register` - User registration
- `POST /auth/login` - User login

### **Core Features**
- `POST /chat` - AI chat with Gemini
- `POST /analyze` - Multi-modal emotion analysis
- `POST /suggest` - Personalized wellness suggestions

### **Data Management**
- `GET /routines` - Get user routines and habits
- `POST /routines` - Add new routines/habits
- `GET /analytics` - Get wellness analytics

### **Health & Status**
- `GET /` - Service status
- `GET /health` - Health check

## 🎨 **UI/UX Features**

### **Design Principles**
- **Modern Material Design** with custom theming
- **Gradient backgrounds** and smooth animations
- **Responsive layout** for all screen sizes
- **Accessibility features** for inclusive design

### **Color Scheme**
- **Primary**: Purple (#9B4DCA)
- **Secondary**: Deep Blue (#2D1B69)
- **Background**: Dark (#18122B)
- **Accents**: Green, Orange, Pink for different features

### **Animations**
- **Fade transitions** between screens
- **Smooth scrolling** and interactions
- **Loading indicators** with custom designs
- **Micro-interactions** for better UX

## 🤖 **AI & ML Integration**

### **Emotion Detection Models**
- **Facial Recognition**: OpenCV + Haar Cascades
- **Text Sentiment**: HuggingFace `cardiffnlp/twitter-roberta-base-sentiment`
- **Voice Analysis**: SpeechBrain (planned for future)

### **AI Assistant (Gemini)**
- **Context-aware responses** based on user emotions
- **Personalized suggestions** for wellness improvement
- **Habit coaching** and motivation
- **Stress management** techniques

### **Data Processing**
- **Real-time analysis** of user inputs
- **Pattern recognition** for mood trends
- **Predictive insights** for wellness optimization

## 📊 **Data & Analytics**

### **User Data**
- **Mood tracking** with timestamps
- **Habit completion** records
- **Focus session** durations
- **Emotion patterns** over time

### **Analytics Dashboard**
- **Mood trends** visualization
- **Habit streaks** and progress
- **Focus time** analytics
- **Wellness score** calculations

### **Privacy & Security**
- **JWT authentication** for secure access
- **Local data storage** for sensitive information
- **Encrypted communication** with backend
- **User consent** for data collection

## 🚀 **Deployment Options**

### **Local Development**
- Backend runs on `localhost:5000`
- Flutter app connects via local network
- Perfect for development and testing

### **Cloud Deployment**
- **Backend**: Deploy to Heroku, AWS, or Google Cloud
- **Database**: Use MongoDB Atlas or PostgreSQL
- **ML Models**: Deploy to specialized ML platforms
- **CDN**: Use CloudFlare for static assets

### **Mobile Distribution**
- **Android**: Build APK or upload to Google Play
- **iOS**: Build and distribute via TestFlight
- **Desktop**: Create installers for Windows/Mac/Linux

## 🧪 **Testing & Quality Assurance**

### **Backend Testing**
- **Unit tests** for API endpoints
- **Integration tests** for ML models
- **Performance testing** for scalability
- **Security testing** for vulnerabilities

### **Frontend Testing**
- **Widget tests** for UI components
- **Integration tests** for app flows
- **Performance profiling** for smooth animations
- **Accessibility testing** for inclusive design

## 🔧 **Configuration & Customization**

### **Environment Variables**
```bash
GEMINI_API_KEY=your_api_key_here
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_here
FLASK_ENV=development
```

### **App Configuration**
- **Theme customization** in `Settings.dart`
- **Language selection** for internationalization
- **Notification preferences** for user engagement
- **Privacy settings** for data control

## 📈 **Performance & Optimization**

### **Backend Optimization**
- **Async processing** for ML models
- **Caching strategies** for repeated requests
- **Database indexing** for fast queries
- **Load balancing** for high traffic

### **Frontend Optimization**
- **Lazy loading** for better performance
- **Image compression** for faster loading
- **State management** optimization
- **Memory management** for smooth operation

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Backend Won't Start**
```bash
# Check Python version
python --version  # Should be 3.10+

# Check dependencies
pip list | grep -E "(Flask|torch|opencv)"

# Check environment variables
echo $GEMINI_API_KEY
```

#### **Flutter Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check Android setup
flutter doctor
```

#### **Connection Issues**
```bash
# Test backend connection
curl http://localhost:5000/health

# Check network configuration
ipconfig  # Windows
ifconfig  # Linux/Mac
```

### **Debug Mode**
```bash
# Backend debug
export FLASK_DEBUG=1
python start.py

# Flutter debug
flutter run --debug
```

## 🤝 **Contributing**
Mohammed Ahmed - 
Rahaf Khayrat

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

### **Code Standards**
- **Python**: Follow PEP 8 guidelines
- **Flutter**: Use official Flutter style guide
- **Documentation**: Add docstrings and comments
- **Testing**: Maintain test coverage above 80%

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Google Gemini AI** for intelligent conversation capabilities
- **HuggingFace** for pre-trained sentiment analysis models
- **OpenCV** for computer vision and facial recognition
- **Flutter Team** for the amazing cross-platform framework
- **Flask Community** for the robust web framework

## 📞 **Support & Contact**

- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Email**: Contact the development team for business inquiries

---

## 🎉 **Getting Started Checklist**

- [ ] Clone the repository
- [ ] Set up Python 3.10+ environment
- [ ] Install backend dependencies
- [ ] Get Google Gemini API key
- [ ] Configure environment variables
- [ ] Start the backend server
- [ ] Install Flutter SDK
- [ ] Install Flutter dependencies
- [ ] Run the Flutter app
- [ ] Test all features
- [ ] Customize for your needs

**Happy coding! 🚀✨**
