# 🌟 Hyprland Dotfiles - Complete Desktop Environment

A comprehensive, interactive installation script for **Hyprland** on **Arch Linux** featuring **6 complete themes**, full desktop environment setup, and extensive customization options. Built to rival JaKooLit's dotfiles with professional quality and attention to detail.

## ✨ Features

### 🎨 **6 COMPLETE Themes** (Not just colors - full configurations!)
- **🟣 Catppuccin Mocha** - Dark purple elegance with full config suite
- **🔵 Catppuccin Macchiato** - Warm blue comfort with coordinated styling
- **🌃 TokyoNight** - Cyberpunk vibes with neon accents
- **🟡 Gruvbox** - Retro warm colors with vintage appeal
- **🔷 Nord** - Arctic frost theme with cool blues
- **🌹 Rose Pine** - Soft rose aesthetic with elegant pastels

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

1. **Run the installation**:
   ```bash
   ./hyprland-setup.sh
   ```

2. **Reboot your system**

3. **Select Hyprland** from your display manager (SDDM/GDM)

4. **Configure your dotfiles** in `~/.config/`

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
