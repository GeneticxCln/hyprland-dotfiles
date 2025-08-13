# 🎯 AI-Enhanced Workload Indicator Widget

## Overview

The Workload Indicator Widget is an intelligent system component that automatically detects and displays your current computing workload, providing visual feedback and system optimization recommendations. It integrates seamlessly with the AI automation system to provide real-time workload classification and performance optimization.

## 🌟 Key Features

### Real-Time Workload Detection
- **Automatic Classification**: Intelligently detects 5 workload types:
  - 🎮 **Gaming**: High-performance gaming sessions
  - 💻 **Development**: Coding and software development
  - 🎬 **Media**: Content creation and media editing
  - 📊 **Productivity**: Office work and general computing
  - 💤 **Idle**: Low-activity or idle system state

### Visual Indicators
- **Color-coded Workloads**: Each workload type has a distinct color theme
- **Confidence Metrics**: Shows AI confidence in workload detection
- **Priority Indicators**: Visual priority levels for different workloads
- **Smooth Animations**: Pulse animations for high-priority workloads

### Interactive Interface
- **Compact/Expanded Views**: Toggle between minimal and detailed displays
- **Real-time Metrics**: CPU, RAM, GPU usage, and confidence levels
- **Quick Actions**: Force apply workloads or reset to idle
- **Hover Effects**: Enhanced visual feedback on interaction

### AI Integration
- **Automatic Optimization**: Applies system optimizations based on detected workload
- **Learning System**: Improves detection accuracy over time
- **Notification System**: Alerts when workload changes occur
- **Performance Tracking**: Monitors system metrics for optimization

## 🚀 Installation & Setup

### Prerequisites
- Hyprland window manager
- Quickshell (for QML widgets)
- Python 3.x with required packages
- System monitoring tools (htop, nvidia-smi, etc.)

### Configuration Files

The workload indicator system consists of several components:

```
configs/quickshell/
├── widgets/
│   ├── WorkloadIndicator.qml      # Main widget UI
│   └── AIStatusWidget.qml         # AI system status panel
├── components/
│   ├── AIIntegration.qml          # AI system bridge
│   └── SystemMonitor.qml          # Resource monitoring
└── shell.qml                      # Main shell configuration

scripts/ai/
└── workload-automation.sh         # Backend automation system
```

### Setup Instructions

1. **Ensure Prerequisites are Installed**:
   ```bash
   # Install required packages
   sudo pacman -S quickshell python python-psutil jq bc
   ```

2. **Configure the System**:
   ```bash
   # Initialize workload automation
   ./scripts/ai/workload-automation.sh
   
   # Test workload detection
   ./scripts/ai/workload-automation.sh detect
   ```

3. **Start the Widget**:
   ```bash
   # Launch Quickshell with the configuration
   quickshell -c configs/quickshell/shell.qml
   ```

## 🎮 Usage Guide

### Basic Operation

1. **Widget Location**: Appears in the top-right corner of your screen
2. **Default View**: Shows workload name, icon, and confidence bar
3. **Expand Details**: Click the "+" button or double-click the widget
4. **Quick Actions**: Use Force/Reset buttons in expanded view

### Workload Types

| Workload | Icon | Color | Trigger Processes | Priority |
|----------|------|-------|------------------|----------|
| Gaming | 🎮 | Red (#f38ba8) | steam, lutris, heroic, wine | High |
| Development | 💻 | Green (#a6e3a1) | code, vim, jetbrains, docker | Medium |
| Media | 🎬 | Orange (#fab387) | obs, blender, gimp, vlc | High |
| Productivity | 📊 | Blue (#89b4fa) | firefox, thunderbird, zoom | Medium |
| Idle | 💤 | Gray (#6c7086) | Low system activity | Low |

### Visual Indicators

- **Pulsing Icon**: High-priority workloads (gaming/media) have animated icons
- **Color Borders**: Widget border color matches current workload
- **Confidence Bar**: Shows AI confidence in workload detection (green = high, yellow = medium, red = low)
- **Priority Indicator**: Small colored bar indicating workload priority

### Metrics Display (Expanded View)

- **CPU Usage**: Real-time processor utilization
- **Memory Usage**: RAM consumption percentage  
- **GPU Usage**: Graphics card utilization (if available)
- **Confidence**: AI detection confidence level

## ⚙️ Configuration

### Workload Detection Rules

The system uses configurable rules stored in `~/.config/hypr/workload-automation/workload_config.json`:

```json
{
  "detection_rules": {
    "gaming": {
      "processes": ["steam", "lutris", "heroic", "bottles", "wine"],
      "gpu_usage_threshold": 70,
      "cpu_usage_threshold": 60,
      "fullscreen_apps": true
    },
    "development": {
      "processes": ["code", "nvim", "vim", "emacs", "jetbrains"],
      "cpu_usage_threshold": 40,
      "memory_usage_threshold": 30
    }
  }
}
```

### Customization Options

#### Widget Appearance
```qml
// In WorkloadIndicator.qml
property color baseColor: "#1e1e2e"        // Background color
property color accentColor: "#cba6f7"      // Accent color
property bool animationsEnabled: true      // Enable/disable animations
```

#### Update Intervals
```qml
// Update frequency
Timer {
    interval: 5000  // 5 seconds (adjust as needed)
}
```

#### Detection Sensitivity
```bash
# In workload-automation.sh
WORKLOAD_CONFIDENCE_THRESHOLD=0.7  # Confidence required for workload switch
MIN_DETECTION_TIME=30              # Minimum detection time in seconds
```

## 🔧 Advanced Features

### Manual Workload Control

```bash
# Force apply specific workload
./scripts/ai/workload-automation.sh apply gaming

# Reset to idle
./scripts/ai/workload-automation.sh reset

# Check current status
./scripts/ai/workload-automation.sh status
```

### Custom Workload Profiles

Create custom workload types:

```bash
# Create a new workload profile
./scripts/ai/workload-automation.sh create streaming
```

### Automation Scheduling

Enable automatic workload monitoring:

```bash
# Schedule automated monitoring every 30 seconds
./scripts/ai/workload-automation.sh schedule

# Check automation status
./scripts/ai/workload-automation.sh dashboard
```

## 🐛 Troubleshooting

### Common Issues

1. **Widget Not Appearing**:
   - Check Quickshell is running: `ps aux | grep quickshell`
   - Verify configuration path: `quickshell -c configs/quickshell/shell.qml`
   - Check for QML errors in console output

2. **Workload Detection Not Working**:
   - Test detection manually: `./scripts/ai/workload-automation.sh detect`
   - Check process detection: `ps aux | grep -E "steam|code|chrome"`
   - Verify configuration file exists: `ls ~/.config/hypr/workload-automation/`

3. **Performance Issues**:
   - Increase update intervals in widget configuration
   - Disable animations: `animationsEnabled: false`
   - Check system resources: `htop`

### Debug Mode

Enable verbose logging:

```bash
# Run workload detection with debug output
bash -x ./scripts/ai/workload-automation.sh detect
```

### Log Files

Check log files for issues:
- Widget logs: Quickshell console output
- Automation logs: `~/.config/hypr/workload-automation/logs/`
- System logs: `journalctl -u quickshell`

## 🔄 Integration with Other Components

### AI System Integration
- Works with AI learning system for improved detection
- Integrates with theme management for workload-specific themes
- Connects to system optimization scripts

### Waybar Integration
- Can display workload info in Waybar panels
- Synchronized with other system indicators
- Shared configuration with other widgets

### Notification System
- Sends desktop notifications on workload changes
- Integrates with Dunst notification daemon
- Configurable notification settings

## 📊 Performance Monitoring

### Metrics Collection
- Real-time system resource monitoring
- Historical data for trend analysis
- AI confidence tracking over time

### Performance Analytics
```bash
# View performance trends
./scripts/ai/workload-automation.sh dashboard

# Export performance data
cat ~/.config/hypr/workload-automation/logs/performance_log.json
```

## 🚀 Future Enhancements

### Planned Features
- **Machine Learning**: Enhanced workload prediction
- **Custom Rules**: GUI for creating detection rules  
- **Profiles Sync**: Cloud synchronization of workload profiles
- **Integration APIs**: REST API for external integrations
- **Mobile Companion**: Mobile app for remote monitoring

### Contributing
Interested in contributing? Check out:
- Widget improvements in `configs/quickshell/widgets/`
- Detection algorithms in `scripts/ai/workload-automation.sh`
- AI integration in `configs/quickshell/components/`

## 📝 Changelog

### Version 1.0.0
- Initial workload indicator implementation
- Basic AI integration and workload detection
- Real-time system monitoring
- Expandable widget interface
- Quick action buttons

## 🤝 Support

Need help? Here are your options:

1. **Documentation**: Check this guide and related docs
2. **Testing Script**: Use `./test-workload-indicator.sh` for testing
3. **GitHub Issues**: Report bugs and request features
4. **Community**: Join discussions in project channels

---

**Happy monitoring! 🎯**
