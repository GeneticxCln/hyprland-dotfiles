# 🌟 Hyprland Dotfiles - Complete Desktop Environment

A comprehensive, interactive installation script for **Hyprland** on **Arch Linux** featuring **20 complete themes**, NVIDIA integration, SDDM Simple2 theme, display scaling support, and extensive customization options. Built to rival JaKooLit's dotfiles with professional quality and attention to detail.

## ✨ Features

### 🎨 **20 COMPLETE Themes** (Not just colors - full configurations!)
- **🟣 Catppuccin Family** - Mocha, Macchiato, Latte, Frappe variants
- **🌃 TokyoNight Family** - Night, Storm, Day variants
- **🟡 Gruvbox Family** - Dark and Light variants
- **🔷 Nord Family** - Classic Nord and Light variants
- **🌹 Rose Pine Family** - Rose Pine, Moon, Dawn variants
- **🧛 Dracula** - The classic dark vampire theme
- **🎨 Monokai Pro** - Modern developer favorite
- **☀️ Solarized** - Dark and Light scientific color schemes
- **🌲 Everforest** - Dark and Light nature-inspired themes

### 🖥️ **Complete Desktop Stack**
- 🚀 **Hyprland** - Modern Wayland compositor with advanced features
- 📊 **Waybar** - Customizable status bar with theme integration
- 🎯 **Quickshell** - Qt-based desktop environment with panels & widgets
- 🔍 **Rofi Wayland** - Beautiful application launcher
- 🖼️ **Wallpaper Collections** - Theme-matching backgrounds
- 🎵 **Media Integration** - Music controls and system monitoring

### 💫 **Advanced Features** 
- ✅ **Interactive Installation** - Guided setup with theme selection
- ✅ **Comprehensive Backup System** - Safe configuration management
- ✅ **Multiple App Suites** - Development, gaming, productivity packages
- ✅ **Automatic Service Management** - System integration
- ✅ **Smart Package Detection** - AUR helper auto-installation
- ✅ **Error Recovery** - Robust installation process
- 🖥️ **NVIDIA Integration** - Complete NVIDIA driver setup and optimization
- 🎨 **SDDM Simple2 Theme** - Beautiful login manager with Hyprland integration
- 💻 **Multi-Resolution Support** - FHD, 2K, 4K display scaling

## 🚀 Quick Start

```bash
# Clone or download the repository
chmod +x install.sh
./install.sh
```

## What Gets Installed

### Core Components
- **hyprland** - Wayland compositor
- **quickshell-git** - Modern Qt-based shell (from AUR)
- **waybar** - Status bar
- **rofi-wayland** - Application launcher (from AUR)

### Essential Tools
- **Audio**: pipewire, pipewire-pulse, pavucontrol
- **Screenshots**: grim, slurp, swappy
- **Notifications**: dunst  
- **Terminal**: kitty
- **File Manager**: thunar
- **Wallpapers**: swww
- **Clipboard**: wl-clipboard

### Development & Media
- **Browser**: firefox
- **Media**: mpv, imv
- **Monitoring**: btop

## Configuration Directories

After installation, configure your dotfiles in:
```
~/.config/hypr/          # Hyprland configuration
~/.config/waybar/        # Status bar configuration  
~/.config/quickshell/    # Quickshell QML configuration
~/.config/rofi/          # Application launcher themes
~/.config/dunst/         # Notification settings
~/.config/kitty/         # Terminal configuration
```

## Usage

### Standard Installation
1. **Run the installation**:
   ```bash
   ./install.sh
   ```

2. **Follow the interactive setup** - Select theme, apps, and additional features

3. **Reboot your system**

4. **Select Hyprland** from your display manager

### NVIDIA Users
1. **Run the main installer** and select NVIDIA integration when prompted, OR
2. **Run NVIDIA setup separately**:
   ```bash
   ./nvidia-integration.sh
   ```

3. **Configure your display resolution** and scaling during setup
4. **Reboot after installation** to load NVIDIA drivers

### SDDM Simple2 Theme
1. **Run during main installation** by selecting SDDM option, OR
2. **Install separately**:
   ```bash
   ./sddm-setup.sh
   ```

3. **Reboot to see the new login screen**

## Requirements

- Arch Linux or Arch-based distribution (CachyOS, EndeavourOS, Manjaro)
- Internet connection
- sudo privileges

## Backup

The script automatically backs up existing configurations to:
```
~/.config/hyprland-backup-YYYYMMDD-HHMMSS/
```

## Troubleshooting

### AUR Helper Issues
If you don't have `yay` or `paru`, the script will automatically install `yay`.

### Package Installation Fails
The script checks for existing packages and skips already installed ones.

### Configuration Issues
- Check backup directory for your old configs
- Verify configuration directories were created
- Ensure proper file permissions

## Customization

Edit the package arrays in `hyprland-setup.sh` to add/remove packages:

```bash
# Add to OFFICIAL_PACKAGES array for pacman packages
OFFICIAL_PACKAGES+=(
    "your-package-name"
)

# Add to AUR_PACKAGES array for AUR packages  
AUR_PACKAGES+=(
    "your-aur-package"
)
```

## Next Steps

After installation:
1. Configure Hyprland in `~/.config/hypr/hyprland.conf`
2. Set up Waybar themes and modules
3. Create Quickshell QML configurations
4. Customize Rofi themes and modi
5. Set wallpapers and themes

## Support

This script is designed for Arch Linux systems. For other distributions, modify the package manager commands accordingly.

## License

MIT License - Feel free to modify and distribute.
