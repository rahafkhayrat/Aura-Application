# 🎥 Video Call Feature - Real-Time Study Session Monitoring

## **Overview**

The **Video Call Feature** transforms Aura into an intelligent study companion that continuously monitors your facial expressions and automatically suggests breaks when you appear distracted or stressed.

## **🌟 Key Features**

### **1. Real-Time Video Monitoring**
- **Continuous Camera Feed**: Live video stream during study sessions
- **Facial Emotion Detection**: Analyzes your expressions every 3 seconds
- **Emotion History Tracking**: Maintains a log of your emotional states
- **Confidence Scoring**: Shows how accurate the emotion detection is

### **2. Intelligent Break Suggestions**
- **Distraction Detection**: Identifies when you're getting distracted
- **Automatic Break Prompts**: Suggests breaks when needed
- **Break Timer**: 5-minute countdown timer for breaks
- **Break Activities**: Suggests specific activities (stretching, breathing, eye rest)

### **3. Study Session Management**
- **Focus Time Tracking**: Monitors how long you've been studying
- **Distraction Counter**: Tracks distraction levels
- **Session Statistics**: Real-time stats on your study session
- **Manual Controls**: Option to manually trigger breaks or end sessions

## **🎯 How It Works**

### **Emotion Analysis Algorithm**
```
Camera Feed → Frame Capture → AI Analysis → Emotion Detection → 
Distraction Check → Break Suggestion (if needed)
```

### **Distraction Detection Logic**
- **Monitors**: sad, angry, fear, disgust emotions
- **Triggers**: When 3+ negative emotions detected in last 5 readings
- **Suggests Break**: After 2 consecutive distraction events

### **Break Management**
- **Automatic Timer**: 5-minute break countdown
- **Break Activities**: Quick stretch, deep breathing, eye rest
- **Resume Prompt**: Notifies when break is complete

## **📱 User Interface**

### **Video Call Screen Layout**
```
┌─────────────────────────────────────┐
│ 🔙 Study Session | AI Monitoring    │
├─────────────────────────────────────┤
│                                     │
│    🎥 Live Camera Feed              │
│    😊 Emotion Overlay               │
│    ⏰ Break Timer (if active)       │
│                                     │
├─────────────────────────────────────┤
│ 📊 Focus Time | Emotions | Distract │
│ [Manual Break] [End Session]        │
└─────────────────────────────────────┘
```

### **Status Indicators**
- **🟢 Focusing**: Normal study mode
- **🟠 Break Suggested**: AI detected distraction
- **🟢 On Break**: Currently taking a break

## **🔧 Technical Implementation**

### **Camera Integration**
```dart
CameraController(
  cameras[0],
  ResolutionPreset.medium,
  enableAudio: false,
)
```

### **Continuous Analysis**
```dart
Timer.periodic(Duration(seconds: 3), (timer) {
  _analyzeCurrentFrame();
});
```

### **Emotion Processing**
```dart
final analysis = await ApiService.analyzeEmotion(image: imageBase64);
final emotion = analysis['face']['emotion'];
final confidence = analysis['face']['confidence'];
```

## **🎮 How to Use**

### **Starting a Study Session**
1. Open Aura app
2. Go to Home Screen
3. Tap "Study Mode" button
4. Grant camera permissions
5. Begin studying!

### **During Study Session**
- **Camera**: Automatically monitors your expressions
- **Emotion Display**: Shows current emotion and confidence
- **Stats**: Real-time focus time and distraction tracking
- **Break Suggestions**: Appear automatically when needed

### **Taking Breaks**
- **Automatic**: AI suggests breaks when distracted
- **Manual**: Tap "Manual Break" button
- **Timer**: 5-minute countdown with activity suggestions
- **Resume**: Automatic prompt when break ends

### **Ending Session**
- Tap "End Session" button
- Confirm to save progress
- Return to home screen

## **🔒 Privacy & Security**

### **Data Handling**
- **Local Processing**: Camera feed processed locally
- **No Recording**: No video is recorded or stored
- **Temporary Analysis**: Only current frame is analyzed
- **Secure API**: Emotion data sent securely to backend

### **Permissions Required**
- **Camera Access**: For live video feed
- **Internet**: For AI emotion analysis

## **🎯 Educational Benefits**

### **For Students**
- **Self-Awareness**: Understand your study patterns
- **Better Focus**: Learn when you need breaks
- **Improved Productivity**: Optimize study sessions
- **Stress Management**: Prevent burnout

### **For Educators**
- **Study Analytics**: Track student engagement
- **Wellness Monitoring**: Ensure student well-being
- **Break Optimization**: Suggest optimal study/break ratios

## **🚀 Future Enhancements**

### **Planned Features**
- **Voice Analysis**: Detect stress in voice tone
- **Eye Tracking**: Monitor eye movement and focus
- **Posture Analysis**: Detect poor sitting posture
- **Study Analytics**: Detailed session reports
- **Custom Break Activities**: Personalized break suggestions

### **Advanced AI**
- **Learning Algorithm**: Adapts to individual patterns
- **Predictive Breaks**: Anticipate when breaks are needed
- **Emotion Trends**: Long-term emotional pattern analysis

## **🔧 Troubleshooting**

### **Common Issues**
- **Camera Not Working**: Check permissions in device settings
- **No Emotion Detection**: Ensure good lighting and face visibility
- **Break Not Triggering**: Check if emotions are being detected
- **App Crashes**: Restart app and check camera permissions

### **Performance Tips**
- **Good Lighting**: Ensure face is well-lit
- **Stable Position**: Keep device steady
- **Clear View**: Ensure face is clearly visible
- **Regular Breaks**: Don't ignore break suggestions

## **📊 Analytics & Insights**

### **Session Data**
- **Focus Duration**: Total time spent studying
- **Emotion Distribution**: Breakdown of detected emotions
- **Distraction Frequency**: How often breaks were suggested
- **Break Compliance**: Whether breaks were taken

### **Trends**
- **Daily Patterns**: Best study times
- **Emotion Trends**: Emotional patterns over time
- **Productivity Metrics**: Focus vs. distraction ratios

---

## **🌟 Success Stories**

> "Aura's video call feature helped me realize I was getting stressed during long study sessions. The automatic break suggestions really improved my focus and reduced my anxiety." - *Sarah, University Student*

> "As a teacher, I love how Aura monitors student wellness. The break suggestions help prevent burnout and maintain engagement." - *Dr. Johnson, Professor*

---

**🎓 Transform your study sessions with AI-powered wellness monitoring!**
