# 📦 Installation Guide

## 🚀 Quick Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/hyprland-project.git
cd hyprland-project

# Make scripts executable
chmod +x *.sh

# Run the installer
./install.sh
```

## 📋 Prerequisites

### System Requirements
- **OS**: Arch Linux, CachyOS, EndeavourOS, or Manjaro
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 10GB free space
- **GPU**: NVIDIA GTX 900+ or AMD Radeon RX 400+
- **Network**: Active internet connection

### Dependencies
The installer will automatically install these if missing:
- `git` - Version control
- `yay` or `paru` - AUR helper
- `base-devel` - Build tools

## 🎛️ Installation Options

### Standard Installation
```bash
./install.sh
```
This provides an interactive menu for:
- Theme selection (20 options)
- Component selection
- NVIDIA integration
- SDDM theme setup

### Minimal Installation
```bash
./setup.sh
```
Installs only core components without additional applications.

### Advanced Installation
```bash
# Install with specific theme
./install.sh --theme catppuccin-mocha

# Install with all components
./install.sh --full

# Install for NVIDIA systems
./install.sh --nvidia
```

## 🎨 Theme Selection

Choose from 20 professionally crafted themes:

**Catppuccin Family** (4 variants)
- Mocha, Macchiato, Latte, Frappe

**TokyoNight Family** (3 variants)  
- Night, Storm, Day

**Gruvbox Family** (2 variants)
- Dark, Light

**And 11 more beautiful themes...**

## 🖥️ Post-Installation

### 1. Reboot Your System
```bash
sudo reboot
```

### 2. Select Hyprland at Login
Choose "Hyprland" from your display manager

### 3. First Boot Setup
- Press `SUPER + H` for help overlay
- Press `SUPER + ENTER` to open terminal
- Press `SUPER + D` to launch application menu

### 4. Theme Switching
```bash
# Switch themes anytime
./theme-switcher.sh

# Or apply specific theme
./theme-switcher.sh catppuccin-mocha
```

## 🔧 Configuration Locations

After installation, your configs are located at:
```
~/.config/hypr/          # Hyprland configuration
~/.config/waybar/        # Status bar
~/.config/quickshell/    # Desktop shell
~/.config/rofi/          # App launcher
~/.config/kitty/         # Terminal
```

## 🆘 Troubleshooting

### Common Issues
1. **Packages fail to install**: Run `sudo pacman -Syu` first
2. **AUR helper missing**: Script auto-installs `yay`
3. **Permission denied**: Check script permissions with `ls -la`

### NVIDIA Issues
1. Run: `./nvidia-integration.sh` separately
2. Reboot after NVIDIA driver installation
3. Check [NVIDIA Troubleshooting](../troubleshooting/nvidia.md)

## 🔄 Backup & Recovery

Your original configs are backed up to:
```
~/.config/hyprland-backup-YYYYMMDD-HHMMSS/
```

To restore:
```bash
# Run the cleanup script
./cleanup-and-restore.sh

# Follow the interactive restoration menu
```

## 📞 Getting Help

- 📖 [Full Documentation](../README.md)
- 🐛 [Report Issues](https://github.com/yourusername/hyprland-project/issues)
- 💬 [Discord Community](https://discord.gg/your-server)
