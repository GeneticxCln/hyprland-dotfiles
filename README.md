# My Hyprland Config

Personal Hyprland desktop setup with 20 themes, coordinated wallpapers, and automation scripts. Built for my own use on CachyOS.

## What's Here

- **20 themes** with matching wallpapers
- **Quickshell** desktop environment
- **Automation scripts** for maintenance, gaming mode, etc.
- **Modular installer** - install what you need

## Installation

```bash
git clone https://github.com/GeneticxCln/hyprland-dotfiles.git
cd hyprland-dotfiles

# Full setup
./install.sh

# Just the basics
./setup.sh

# Pick and choose
./modular-install.sh
```

## Themes Available

20 themes with matching wallpapers:
- Catppuccin (Mocha, Macchiato, Latte, Frappe)
- TokyoNight (Night, Storm, Day)
- Gruvbox (Dark, Light)
- Nord (Classic, Light)
- Rose Pine (Rose Pine, Moon, Dawn) 
- Dracula
- Monokai Pro
- Solarized (Dark, Light)
- Everforest (Dark, Light)

## Scripts

```bash
# Switch themes
./theme-switcher.sh

# Switch themes with demo
./demo-themes.sh

# Manage wallpapers
./wallpaper-manager.sh

# Check config
./verify-configs.sh
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

## Wallpapers

Each theme has a matching wallpaper that changes automatically. Wallpapers are stored in `wallpapers/` and managed by the theme switcher.

## Requirements

- Arch Linux or Arch-based distribution
- Internet connection
- sudo privileges

## Notes

- Configs backed up to `~/.config/hyprland-backup-YYYYMMDD-HHMMSS/`
- For NVIDIA: run `./nvidia-integration.sh` 
- For SDDM theme: run `./sddm-setup.sh`
