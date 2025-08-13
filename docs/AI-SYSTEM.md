# 🤖 AI System Documentation

## Overview

The AI System provides intelligent automation and optimization for your Hyprland desktop environment. It learns from your usage patterns and automatically adapts system settings, themes, and performance configurations to match your workflow.

## Features

### 🧠 **Intelligent Learning**
- **Usage Pattern Recognition**: Learns your daily computer usage habits
- **Workload Detection**: Automatically detects gaming, development, media, or productivity sessions
- **Time-based Adaptation**: Adjusts recommendations based on time of day and day of week
- **Feedback Learning**: Improves recommendations based on user feedback

### 🎨 **Smart Theme Management**
- **Context-Aware Switching**: Themes adapt to detected workload and time
- **Gaming Mode**: Dark themes optimized for gaming sessions
- **Development Mode**: Coding-friendly themes with proper contrast
- **Productivity Mode**: Comfortable themes for office work
- **Time-based Themes**: Light themes for morning, balanced for afternoon, warm for evening

### ⚡ **Performance Optimization**
- **CPU Governor Management**: Automatic switching between performance, ondemand, and powersave
- **I/O Scheduler Optimization**: BFQ for interactive workloads, mq-deadline for gaming
- **Memory Management**: Intelligent cache clearing and swappiness adjustment
- **Battery Optimization**: Power-saving features for laptop users

### 🧹 **Intelligent Cleanup**
- **Pattern-based Cleanup**: Cleans system based on usage patterns
- **Threshold-based Actions**: Automatic cleanup when disk/memory usage is high
- **Safe Operation**: Only cleans when system load is low
- **User-controlled**: Manual override available for all cleanup actions

### 📱 **Smart Notifications**
- **Break Reminders**: Suggests breaks based on session duration
- **System Health Alerts**: Memory, disk, and temperature warnings
- **Proactive Recommendations**: Theme and optimization suggestions
- **Battery Notifications**: Critical battery and charging status alerts

## Components

### 1. AI Enhancements (`ai-enhancements.sh`)

Main script providing AI-powered system enhancements.

```bash
# Individual functions
./scripts/ai/ai-enhancements.sh theme      # Smart theme switching
./scripts/ai/ai-enhancements.sh cleanup    # Intelligent cleanup
./scripts/ai/ai-enhancements.sh optimize   # Performance optimization
./scripts/ai/ai-enhancements.sh notify     # Smart notifications
./scripts/ai/ai-enhancements.sh battery    # Battery optimization
./scripts/ai/ai-enhancements.sh report     # Daily system report

# Run all enhancements
./scripts/ai/ai-enhancements.sh all
```

### 2. Learning System (`learning-system.py`)

Python-based AI learning and recommendation engine.

```bash
# Collect usage data
python3 scripts/ai/learning-system.py collect

# Generate recommendations
python3 scripts/ai/learning-system.py recommend

# Provide feedback for learning
python3 scripts/ai/learning-system.py feedback --feedback-action "theme_switch" --feedback-value "positive"
```

### 3. AI Scheduler (`ai-scheduler.sh`)

Background automation and monitoring system.

```bash
# Install as systemd service
./scripts/ai/ai-scheduler.sh setup

# Check system status
./scripts/ai/ai-scheduler.sh status

# Manual optimization trigger
./scripts/ai/ai-scheduler.sh optimize

# Control scheduler
./scripts/ai/ai-scheduler.sh stop
./scripts/ai/ai-scheduler.sh restart
```

## Architecture

### Data Collection
The system continuously collects:
- **System Metrics**: CPU usage, memory usage, disk usage, load average
- **Application Usage**: Running applications and their resource consumption
- **Usage Patterns**: Time-based usage patterns by day of week and hour
- **User Feedback**: Positive/negative feedback on AI actions

### Machine Learning
- **Pattern Recognition**: Identifies recurring usage patterns
- **Workload Classification**: Categorizes sessions into workload types
- **Recommendation Engine**: Generates intelligent suggestions based on collected data
- **Confidence Scoring**: Provides confidence levels for recommendations
- **Feedback Integration**: Learns from user preferences over time

### Automation Levels
1. **Manual**: Run individual AI functions as needed
2. **Semi-automatic**: Receive recommendations and apply manually
3. **Fully Automatic**: Background scheduler runs optimizations automatically

## Installation & Setup

### Prerequisites
- Python 3.6+ with `psutil` module
- Bash shell
- systemd (for background automation)
- notify-send (for notifications)

### Quick Start
```bash
# Install Python dependencies
pip3 install --user psutil

# Make scripts executable
chmod +x scripts/ai/*.sh scripts/ai/*.py

# Test the system
./scripts/ai/demo.sh

# For production use
./scripts/ai/ai-scheduler.sh setup
```

## Usage Examples

### Daily Usage
```bash
# Morning routine - optimize for the day
./scripts/ai/ai-enhancements.sh all

# Check AI recommendations
python3 scripts/ai/learning-system.py recommend

# Apply theme for current workload
./scripts/ai/ai-enhancements.sh theme
```

### Development Workflow
```bash
# The AI automatically detects code editors (VS Code, Vim, etc.)
# and applies development-optimized settings:
# - BFQ I/O scheduler for better interactivity
# - Ondemand CPU governor for balanced performance
# - Development-friendly themes (monokai-pro, etc.)
```

### Gaming Session
```bash
# The AI detects gaming applications (Steam, Lutris, etc.)
# and automatically applies:
# - Performance CPU governor
# - mq-deadline I/O scheduler for low latency
# - Dark themes to reduce eye strain
# - Closes unnecessary background processes
```

## Configuration Files

### Learning Data (`~/.config/hypr/ai-enhancements/learning_data.json`)
Stores collected usage patterns and application statistics:
```json
{
  "usage_patterns": {
    "Monday_09": {
      "cpu_usage": [5.2, 3.1, 7.8],
      "memory_usage": [12.5, 15.2, 18.1],
      "active_apps": ["firefox", "code", "terminal"],
      "count": 15
    }
  },
  "app_usage": {
    "code": {
      "total_time": 120,
      "usage_times": ["2023-12-01T09:15:00", ...],
      "contexts": ["development"]
    }
  }
}
```

### Recommendations (`~/.config/hypr/ai-enhancements/recommendations.json`)
Current AI recommendations:
```json
{
  "theme_recommendation": {
    "theme": "monokai-pro",
    "reason": "Optimized for development workload at 10:00",
    "workload": "development"
  },
  "performance_recommendation": {
    "cpu_governor": "ondemand",
    "io_scheduler": "bfq",
    "reason": "Balanced performance for development"
  },
  "confidence_score": 0.85
}
```

## Workload Detection

The AI system automatically detects workloads based on running applications:

### Gaming Workload
**Detected Applications**: steam, lutris, heroic, wine, proton
**Optimizations**:
- Performance CPU governor
- mq-deadline I/O scheduler
- Dark themes (tokyonight-night, dracula, gruvbox-dark)
- Close unnecessary background apps

### Development Workload
**Detected Applications**: code, nvim, vim, jetbrains, cargo, make, gcc, python
**Optimizations**:
- Ondemand CPU governor
- BFQ I/O scheduler
- Coding themes (monokai-pro, tokyonight-storm)
- Terminal performance optimization

### Media Workload
**Detected Applications**: vlc, mpv, ffmpeg, obs, gimp, inkscape, blender
**Optimizations**:
- Performance CPU governor for processing
- BFQ I/O scheduler
- Media-optimized themes
- Hardware acceleration

### Productivity Workload
**Detected Applications**: firefox, chrome, thunderbird, libreoffice, discord
**Optimizations**:
- Powersave CPU governor
- BFQ I/O scheduler
- Comfortable themes for long sessions
- Power-efficient settings

## Advanced Features

### Predictive Capabilities
- **App Prediction**: Suggests likely applications based on time patterns
- **Performance Forecasting**: Predicts system load and adjusts settings preemptively
- **Theme Recommendations**: Suggests optimal themes before context changes

### Health Monitoring
- **System Health Score**: Overall system health rating (0-100)
- **Resource Monitoring**: Continuous monitoring of CPU, memory, disk, temperature
- **Proactive Alerts**: Warnings before critical thresholds are reached

### Learning Improvements
- **Confidence Building**: Recommendations become more accurate over time
- **Pattern Refinement**: Usage patterns become more precise with more data
- **Preference Learning**: System learns user preferences from feedback

## Troubleshooting

### Common Issues

**AI not detecting workload correctly**
```bash
# Check running applications
ps aux | grep -E "(code|steam|chrome)"

# Force workload detection
python3 scripts/ai/learning-system.py recommend
```

**Low confidence recommendations**
```bash
# Collect more data over time
python3 scripts/ai/learning-system.py collect

# Check data collection
cat ~/.config/hypr/ai-enhancements/learning_data.json
```

**Notifications not working**
```bash
# Test notification system
notify-send "Test" "Notification working"

# Check if notify-send is installed
which notify-send
```

### Debug Mode
Enable debug output by setting environment variable:
```bash
export AI_DEBUG=1
./scripts/ai/ai-enhancements.sh all
```

### Reset Learning Data
```bash
# Clear all learning data
rm -f ~/.config/hypr/ai-enhancements/learning_data.json
rm -f ~/.config/hypr/ai-enhancements/recommendations.json

# Start fresh
python3 scripts/ai/learning-system.py collect
```

## Performance Impact

The AI system is designed to be lightweight:
- **Data Collection**: ~1% CPU usage for 5 seconds every 5 minutes
- **Background Processing**: Minimal memory footprint (~10MB)
- **Storage**: Learning data typically <1MB after months of use
- **Network**: No network access required - fully offline

## Privacy & Security

- **Local Processing**: All AI processing happens locally
- **No Network Access**: No data is sent to external servers
- **User Control**: All features can be disabled or customized
- **Data Transparency**: All collected data is stored in readable JSON format
- **Secure Operations**: Requires user permissions for system-level changes

## Future Enhancements

### Planned Features
- **Window Layout Learning**: Remember and restore optimal window arrangements
- **Application Preloading**: Preload frequently used applications
- **Network Optimization**: Optimize network settings based on usage
- **Temperature-based Adjustments**: Adjust performance based on CPU temperature
- **Multi-monitor Optimization**: Optimize settings for different monitor setups

### Contributing
The AI system is modular and extensible. New features can be added by:
1. Extending the learning system with new data collection
2. Adding new recommendation algorithms
3. Creating new optimization functions
4. Implementing new workload detection patterns

## License

This AI system is part of the Hyprland project and follows the same license terms.

---

*This AI system learns and adapts to your usage patterns to provide the best possible desktop experience. The more you use it, the smarter it becomes!*
