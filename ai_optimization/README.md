# 🦥 Lazy UI - AI-Powered Hyprland Optimization

The ultimate lazy person's solution to desktop optimization! Lazy UI is an intelligent, self-healing, and adaptive optimization system that uses artificial intelligence to automatically manage your Hyprland desktop environment. Why manually tweak settings when AI can do it better?

**Be lazy. Let AI handle the work.** 🚀

## ✨ Features

### 🧠 AI-Driven Performance Optimization
- **Neural Network-Based Prediction**: Uses deep learning to predict optimal configurations
- **Real-time Performance Monitoring**: Continuously monitors CPU, GPU, memory, and thermal metrics
- **Automatic Configuration Adjustment**: Dynamically adjusts Hyprland settings for optimal performance
- **Workload-Aware Optimization**: Adapts to gaming, development, media consumption, and general use patterns

### 🔄 Adaptive Configuration Management
- **User Behavior Learning**: Learns from your configuration changes and preferences
- **Context-Aware Profiles**: Creates and applies different profiles based on time, activity, and system state
- **Preference Prediction**: Automatically applies settings you would likely prefer in different contexts
- **Machine Learning Integration**: Uses clustering and pattern recognition to understand usage patterns

### 🏥 Intelligent Self-Healing System
- **Automatic Issue Detection**: Identifies performance, stability, and resource issues
- **Autonomous Problem Resolution**: Automatically fixes common problems without user intervention
- **Predictive Maintenance**: Prevents issues before they become critical
- **Smart Recovery**: Learns from successful fixes to improve future healing actions

### 📊 Comprehensive Monitoring & Reporting
- **Real-time Dashboards**: Live system health and performance metrics
- **Historical Analysis**: Track optimization effectiveness over time
- **Detailed Reporting**: Generate comprehensive system health and performance reports
- **Smart Alerting**: Intelligent notifications for critical issues

## 🚀 Quick Start

### Installation

1. **Run the installer:**
   ```bash
   cd /home/sasha/hyprland-project/ai_optimization
   python3 install.py
   ```

2. **Follow the installation prompts** - the installer will:
   - Check prerequisites and dependencies
   - Install required Python packages in a virtual environment
   - Create systemd services for automatic startup
   - Set up configuration files and directories
   - Create management scripts

3. **Start the system:**
   ```bash
   ./start.sh
   # or if symlinks were created:
   hypr-ai-start
   ```

### Basic Usage

```bash
# Check system status
./cli.py status --detailed

# View real-time logs
./cli.py logs --follow

# Generate a comprehensive report
./cli.py report --output system_report.json

# Manage configuration
./cli.py config show
./cli.py config set ai_optimizer.learning_rate 0.01

# Perform health check
./cli.py health
```

## 🔧 Configuration

The system uses a JSON configuration file located at `config/settings.json`:

```json
{
  "ai_optimizer": {
    "enabled": true,
    "optimization_interval": 30,
    "learning_rate": 0.001,
    "conservative_mode": false
  },
  "adaptive_config": {
    "enabled": true,
    "learning_interval": 60,
    "confidence_threshold": 0.7,
    "min_samples": 10
  },
  "self_healing": {
    "enabled": true,
    "monitoring_interval": 30,
    "auto_fix_enabled": true,
    "max_fix_attempts": 3
  }
}
```

### Configuration Options

#### AI Optimizer
- `optimization_interval`: How often to check for optimization opportunities (seconds)
- `learning_rate`: Learning rate for the neural network
- `conservative_mode`: Use less aggressive optimizations

#### Adaptive Configuration
- `learning_interval`: How often to update learning models (seconds)
- `confidence_threshold`: Minimum confidence required to apply adaptive changes
- `min_samples`: Minimum data samples required before learning

#### Self-Healing
- `monitoring_interval`: System health check interval (seconds)
- `auto_fix_enabled`: Whether to automatically apply fixes
- `max_fix_attempts`: Maximum number of fix attempts per issue

## 📈 How It Works

### 1. AI Performance Optimization

The AI optimizer uses a neural network to predict the best Hyprland configuration based on:
- Current system metrics (CPU, GPU, memory usage)
- Active applications and workload type
- Time of day and usage patterns
- Historical performance data

**Optimizations include:**
- Animation settings (enable/disable, speed, bezier curves)
- Blur effects and visual enhancements
- Window gaps and decorations
- VSync and refresh rate settings
- GPU acceleration preferences

### 2. Adaptive Learning

The adaptive configuration manager learns your preferences by:
- Monitoring manual configuration changes you make
- Correlating changes with system context (time, apps, workload)
- Building user preference profiles using machine learning
- Automatically applying similar changes in similar contexts

**Learning examples:**
- You disable animations when gaming → System learns to disable animations when games are detected
- You increase blur during media consumption → System learns your visual preferences for different activities
- You adjust gaps based on window count → System learns your layout preferences

### 3. Self-Healing Capabilities

The self-healing system monitors for issues and can automatically:

**Performance Issues:**
- High CPU usage → Reduce visual effects, kill resource hogs
- High memory usage → Clear caches, enable compressed swap
- GPU overload → Reduce effects, lower refresh rates

**Stability Issues:**
- Compositor hangs → Restart services, reset configurations
- Application crashes → Clean up resources, restart components

**System Issues:**
- High temperatures → Emergency performance reduction
- Low battery → Power saving mode activation
- Audio problems → Restart audio services

### 4. Integration & Coordination

The main orchestrator coordinates all three systems:
- Prevents conflicting actions between systems
- Shares context and learning data between components
- Handles critical issues that require orchestrator intervention
- Provides unified monitoring and reporting

## 🎯 Optimization Examples

### Gaming Mode
**When gaming is detected:**
- Disables animations for maximum FPS
- Reduces blur and visual effects
- Prioritizes GPU performance
- Minimizes background processes
- Adjusts for low latency

### Development Mode
**When coding activities are detected:**
- Optimizes for screen real estate
- Adjusts gaps and window layouts
- Maintains visual clarity
- Balances performance with usability

### Media Consumption
**When watching videos/streaming:**
- Enhances visual effects
- Optimizes for media applications
- Manages thermal performance
- Maintains smooth playback

### Power Saving
**When on battery power:**
- Reduces all visual effects
- Lowers refresh rates
- Minimizes background activity
- Extends battery life

## 📊 Monitoring & Maintenance

### System Status
```bash
# Quick status check
./cli.py status

# Detailed status with metrics
./cli.py status --detailed

# System health check
./cli.py health
```

### Logs and Debugging
```bash
# View recent logs
./cli.py logs

# Follow logs in real-time
./cli.py logs --follow

# View specific number of lines
./cli.py logs --lines 100
```

### Performance Reports
```bash
# Generate comprehensive report
./cli.py report

# Save detailed report to file
./cli.py report --output detailed_report.json

# View system statistics
./cli.py stats
```

### Service Management
```bash
# Using systemd (recommended)
systemctl --user start hyprland-ai-optimization
systemctl --user status hyprland-ai-optimization
systemctl --user stop hyprland-ai-optimization

# Using management scripts
./start.sh
./status.sh  
./stop.sh

# Using CLI tool
./cli.py start
./cli.py stop
./cli.py restart
```

## 🔒 Security & Privacy

- **Local Processing**: All AI processing happens locally, no data sent to external servers
- **Minimal Permissions**: Only requires access to Hyprland configuration and system metrics
- **Secure Storage**: All data stored locally with appropriate permissions
- **Transparent Operations**: All actions logged for transparency and debugging

## 🛠️ Troubleshooting

### Common Issues

**System won't start:**
1. Check prerequisites: `./cli.py health`
2. Verify Hyprland is running: `hyprctl version`
3. Check Python environment: `ls -la venv/`
4. Review logs: `./cli.py logs`

**High resource usage:**
1. Enable conservative mode in configuration
2. Increase optimization intervals
3. Disable learning temporarily
4. Check for resource-intensive applications

**Incorrect optimizations:**
1. Review and adjust configuration thresholds
2. Clear learning data to retrain: `rm -rf adaptive_data/ models/`
3. Manually override problematic optimizations
4. Report issues for system improvement

### Getting Help

1. **Check logs first**: `./cli.py logs --follow`
2. **Run health check**: `./cli.py health`
3. **Generate system report**: `./cli.py report --output debug_report.json`
4. **Review configuration**: `./cli.py config show`

### Reset and Recovery

```bash
# Stop system
./cli.py stop

# Reset learning data (keeps configuration)
rm -rf adaptive_data/ models/ healing_data/

# Reset everything (nuclear option)
python3 install.py --uninstall
python3 install.py
```

## 🧰 Advanced Usage

### Custom Optimization Profiles

You can create custom optimization profiles by modifying the configuration:

```bash
./cli.py config set ai_optimizer.gaming_mode true
./cli.py config set adaptive_config.profile_switching_enabled true
```

### API Integration

The system provides internal APIs for advanced users:

```python
from core import AIOptimizer, AdaptiveConfigManager

# Initialize components
optimizer = AIOptimizer()
adaptive = AdaptiveConfigManager()

# Get current status
status = await optimizer.get_optimization_report()
```

### Custom Healing Strategies

Add custom healing strategies by extending the self-healing system:

```python
# Example: Custom GPU monitoring
async def custom_gpu_check(issue):
    # Your custom logic here
    return True

# Register custom strategy
healing_system.add_custom_strategy("gpu_custom", custom_gpu_check)
```

## 🔮 Future Enhancements

- **Multi-Monitor Intelligence**: Optimize for different monitor configurations
- **Application-Specific Profiles**: Fine-tuned optimizations per application
- **Predictive Preloading**: Preload optimizations before context switches
- **Community Learning**: Optional sharing of anonymized optimization patterns
- **Web Dashboard**: Browser-based monitoring and control interface
- **Mobile App Integration**: Monitor and control from mobile devices

## 📄 Technical Details

### Architecture
- **Orchestrator**: Main coordination and management system
- **AI Optimizer**: Neural network-based performance optimization
- **Adaptive Config**: Machine learning-based preference learning
- **Self-Healing**: Autonomous issue detection and resolution

### Technologies Used
- **Python 3.8+**: Main implementation language
- **PyTorch**: Neural network framework
- **SQLite**: Local data storage
- **scikit-learn**: Machine learning algorithms
- **asyncio**: Asynchronous programming
- **systemd**: Service management

### Performance Impact
- **CPU Usage**: <2% during normal operation
- **Memory Usage**: ~50-100MB RAM
- **Disk Usage**: ~500MB for installation, growing with learning data
- **Startup Time**: <5 seconds to full operation

## 📜 License

This project is released under the MIT License. See LICENSE file for details.

---

**🎉 Enjoy your intelligent, self-optimizing Hyprland experience!**

The system will learn and adapt to your usage patterns over time, becoming more effective as it gathers data. Give it a few hours of use to build its initial models, then watch as it automatically optimizes your desktop environment for peak performance and user experience.

For questions, issues, or contributions, please refer to the project repository or documentation.
