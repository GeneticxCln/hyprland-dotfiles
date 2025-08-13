#!/bin/bash

# NVIDIA Integration & Display Scaling Script
# Comprehensive NVIDIA setup with display scaling for FHD, 2K, and 4K
# Based on JaKooLit's approach with enhancements

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect NVIDIA GPU
detect_nvidia() {
    log "Detecting NVIDIA GPU..."
    
    if lspci | grep -i nvidia > /dev/null; then
        NVIDIA_GPU=$(lspci | grep -i nvidia | head -1 | cut -d: -f3- | sed 's/^ *//')
        success "NVIDIA GPU detected: $NVIDIA_GPU"
        return 0
    else
        warning "No NVIDIA GPU detected. This script is optimized for NVIDIA systems."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        return 1
    fi
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    log "Installing NVIDIA drivers and utilities..."
    
    # Check if drivers are already installed
    if pacman -Qs nvidia > /dev/null; then
        success "NVIDIA drivers already installed"
        return 0
    fi
    
    # Install NVIDIA packages
    NVIDIA_PACKAGES=(
        nvidia-dkms
        nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        libva-nvidia-driver
        nvidia-prime
    )
    
    sudo pacman -S --needed --noconfirm "${NVIDIA_PACKAGES[@]}"
    
    # Enable nvidia-persistenced service
    sudo systemctl enable nvidia-persistenced.service
    
    success "NVIDIA drivers installed successfully"
}

# Configure NVIDIA settings
configure_nvidia() {
    log "Configuring NVIDIA settings..."
    
    # Create nvidia configuration for Wayland
    cat > /tmp/nvidia-wayland.conf << 'EOF'
# NVIDIA Wayland Configuration
options nvidia_drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_InitializeSystemMemoryAllocations=0
options nvidia NVreg_DynamicPowerManagement=0x02
EOF
    
    sudo cp /tmp/nvidia-wayland.conf /etc/modprobe.d/nvidia.conf
    
    # Update initramfs
    sudo mkinitcpio -P
    
    # Create X11 nvidia config (for compatibility)
    sudo mkdir -p /etc/X11/xorg.conf.d
    cat > /tmp/20-nvidia.conf << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    Option "NoLogo" "true"
    Option "UseEDID" "false"
    Option "ConnectedMonitor" "DFP"
    Option "CustomEDID" "DFP:/etc/X11/edid.bin"
    Option "IgnoreEDID" "false"
    Option "UseDisplayDevice" "DFP"
EndSection
EOF
    
    sudo cp /tmp/20-nvidia.conf /etc/X11/xorg.conf.d/
    
    success "NVIDIA configuration applied"
}

# Detect display resolution and scaling
detect_display_config() {
    log "Detecting display configuration..."
    
    # Get display information using hyprctl if available, otherwise use fallback
    if command -v hyprctl > /dev/null 2>&1; then
        DISPLAY_INFO=$(hyprctl monitors -j 2>/dev/null || echo "[]")
    else
        # Fallback to xrandr or other methods
        DISPLAY_INFO="[]"
    fi
    
    # Manual resolution selection
    echo -e "\n${CYAN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│         📺 DISPLAY CONFIGURATION        │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────╯${NC}"
    echo
    
    echo "Select your primary display resolution:"
    echo "  1. 1920x1080 (Full HD) - Scale 1.0"
    echo "  2. 2560x1440 (2K/QHD) - Scale 1.25"
    echo "  3. 3840x2160 (4K/UHD) - Scale 1.5"
    echo "  4. 3840x2160 (4K/UHD) - Scale 2.0"
    echo "  5. Custom resolution"
    echo
    
    while true; do
        read -p "Select option (1-5): " choice
        case $choice in
            1)
                RESOLUTION="1920x1080"
                SCALE="1.0"
                DPI="96"
                break
                ;;
            2)
                RESOLUTION="2560x1440"
                SCALE="1.25"
                DPI="120"
                break
                ;;
            3)
                RESOLUTION="3840x2160"
                SCALE="1.5"
                DPI="144"
                break
                ;;
            4)
                RESOLUTION="3840x2160"
                SCALE="2.0"
                DPI="192"
                break
                ;;
            5)
                read -p "Enter resolution (WIDTHxHEIGHT): " RESOLUTION
                read -p "Enter scale factor (e.g., 1.25): " SCALE
                read -p "Enter DPI (e.g., 120): " DPI
                break
                ;;
            *)
                warning "Invalid selection. Please choose 1-5."
                ;;
        esac
    done
    
    success "Display config: ${RESOLUTION} @ ${SCALE}x scale (${DPI} DPI)"
}

# Create Hyprland NVIDIA configuration
create_hyprland_nvidia_config() {
    log "Creating Hyprland NVIDIA configuration..."
    
    mkdir -p "$HOME/.config/hypr"
    
    cat > "$HOME/.config/hypr/nvidia.conf" << EOF
# NVIDIA-specific Hyprland Configuration
# Generated by nvidia-integration.sh

# NVIDIA environment variables
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_DRM_NO_ATOMIC,1
env = NVIDIA_DRIVER_ALLOW_UNOFFICIAL_RENDERING,1

# Display configuration
monitor = ,${RESOLUTION}@60,0x0,${SCALE}

# NVIDIA-optimized rendering
render {
    explicit_sync = 0
    explicit_sync_kms = 0
}

# Cursor configuration for NVIDIA
cursor {
    no_hardware_cursors = true
    allow_dumb_copy = true
}

# Performance optimizations
decoration {
    drop_shadow = false  # Shadows can cause performance issues on NVIDIA
}

# OpenGL optimizations
opengl {
    nvidia_anti_flicker = true
    force_introspection = 0
}

# Misc NVIDIA optimizations
misc {
    vrr = 2  # Variable refresh rate
    vfr = true  # Variable frame rate
    no_direct_scanout = false
    force_default_wallpaper = 0
}
EOF
    
    success "Hyprland NVIDIA config created at ~/.config/hypr/nvidia.conf"
}

# Create display scaling configurations
create_scaling_configs() {
    log "Creating display scaling configurations..."
    
    # GTK scaling
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # GTK 3 settings
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter ${DPI}
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-xft-dpi=${DPI}000
EOF
    
    # GTK 4 settings
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter ${DPI}
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-xft-dpi=${DPI}000
EOF
    
    # Qt scaling
    mkdir -p "$HOME/.config/qt5ct"
    mkdir -p "$HOME/.config/qt6ct"
    
    # Environment variables for scaling
    cat > "$HOME/.config/hypr/scaling.conf" << EOF
# Display Scaling Configuration
# Resolution: ${RESOLUTION} @ ${SCALE}x scale

# Qt scaling
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_SCALE_FACTOR,${SCALE}
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1

# GDK scaling
env = GDK_SCALE,${SCALE}
env = GDK_DPI_SCALE,1

# Cursor scaling
env = XCURSOR_SIZE,$(echo "${DPI} * 0.25" | bc | cut -d. -f1)

# Firefox scaling
env = MOZ_ENABLE_WAYLAND,1
env = MOZ_WAYLAND_DRM_DEVICE,/dev/dri/card1
EOF
    
    # Waybar scaling config
    mkdir -p "$HOME/.config/waybar"
    cat > "$HOME/.config/waybar/scaling.css" << EOF
/* Waybar Scaling CSS for ${RESOLUTION} @ ${SCALE}x */
* {
    font-size: $(echo "${DPI} * 0.125" | bc)px;
    font-family: "JetBrainsMono Nerd Font";
}

window#waybar {
    background: transparent;
    border: none;
}

.modules-left,
.modules-center,
.modules-right {
    margin: 0 $(echo "${DPI} * 0.05" | bc | cut -d. -f1)px;
}
EOF
    
    success "Display scaling configurations created"
}

# Install additional NVIDIA utilities
install_nvidia_utilities() {
    log "Installing additional NVIDIA utilities..."
    
    # Additional packages for NVIDIA optimization
    NVIDIA_UTILS=(
        nvtop          # NVIDIA process monitor
        nvidia-ml-py   # Python bindings
        libglvnd       # OpenGL vendor neutral dispatch
        egl-wayland    # EGL Wayland platform
    )
    
    sudo pacman -S --needed --noconfirm "${NVIDIA_UTILS[@]}" 2>/dev/null || true
    
    # AUR packages
    if command -v yay > /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru > /dev/null; then
        AUR_HELPER="paru"
    else
        warning "No AUR helper found, skipping AUR packages"
        return 0
    fi
    
    NVIDIA_AUR=(
        nvidia-system-monitor-qt  # GUI system monitor
        green-with-envy          # GPU overclocking tool
    )
    
    for pkg in "${NVIDIA_AUR[@]}"; do
        $AUR_HELPER -S --needed --noconfirm "$pkg" 2>/dev/null || true
    done
    
    success "NVIDIA utilities installed"
}

# Create optimization scripts
create_optimization_scripts() {
    log "Creating NVIDIA optimization scripts..."
    
    mkdir -p "$HOME/.local/bin"
    
    # GPU monitoring script
    cat > "$HOME/.local/bin/gpu-monitor" << 'EOF'
#!/bin/bash
# GPU Monitoring Script

echo "NVIDIA GPU Status:"
echo "=================="
nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits
echo
echo "Driver Version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits)"
echo "CUDA Version: $(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' || echo "Not installed")"
EOF
    
    # Performance optimization script
    cat > "$HOME/.local/bin/nvidia-optimize" << 'EOF'
#!/bin/bash
# NVIDIA Performance Optimization

echo "Applying NVIDIA optimizations..."

# Set performance mode
sudo nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1"

# Set maximum performance level
sudo nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffset[3]=1000"
sudo nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffset[3]=100"

# Enable persistence mode
sudo nvidia-smi -pm 1

echo "NVIDIA optimizations applied!"
EOF
    
    # Make scripts executable
    chmod +x "$HOME/.local/bin/gpu-monitor"
    chmod +x "$HOME/.local/bin/nvidia-optimize"
    
    success "Optimization scripts created in ~/.local/bin/"
}

# Update Hyprland main config to include NVIDIA settings
update_hyprland_config() {
    log "Updating main Hyprland configuration..."
    
    HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
    
    # Create main config if it doesn't exist
    if [ ! -f "$HYPR_CONFIG" ]; then
        cat > "$HYPR_CONFIG" << 'EOF'
# Hyprland Configuration
# Generated by nvidia-integration.sh

# Source additional configs
source = ~/.config/hypr/nvidia.conf
source = ~/.config/hypr/scaling.conf

# Basic configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
        new_optimizations = true
    }
    drop_shadow = false  # Disabled for NVIDIA compatibility
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

gestures {
    workspace_swipe = false
}

# Key bindings
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Autostart
exec-once = waybar
exec-once = dunst
EOF
    else
        # Add source lines if they don't exist
        if ! grep -q "source = ~/.config/hypr/nvidia.conf" "$HYPR_CONFIG"; then
            echo "source = ~/.config/hypr/nvidia.conf" >> "$HYPR_CONFIG"
        fi
        if ! grep -q "source = ~/.config/hypr/scaling.conf" "$HYPR_CONFIG"; then
            echo "source = ~/.config/hypr/scaling.conf" >> "$HYPR_CONFIG"
        fi
    fi
    
    success "Hyprland configuration updated"
}

# Main execution
main() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      ███╗   ██╗██╗   ██╗██╗██████╗ ██╗ █████╗                   ║
║      ████╗  ██║██║   ██║██║██╔══██╗██║██╔══██╗                  ║
║      ██╔██╗ ██║██║   ██║██║██║  ██║██║███████║                  ║
║      ██║╚██╗██║╚██╗ ██╔╝██║██║  ██║██║██╔══██║                  ║
║      ██║ ╚████║ ╚████╔╝ ██║██████╔╝██║██║  ██║                  ║
║      ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝                  ║
║                                                                  ║
║        🚀 NVIDIA INTEGRATION & DISPLAY SCALING 🚀               ║
║                                                                  ║
║  • NVIDIA Driver Installation     • Display Scaling (FHD/2K/4K) ║
║  • Wayland Optimization          • Performance Tuning          ║
║  • Multi-Resolution Support      • Hyprland Integration        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    detect_nvidia
    detect_display_config
    install_nvidia_drivers
    configure_nvidia
    install_nvidia_utilities
    create_hyprland_nvidia_config
    create_scaling_configs
    create_optimization_scripts
    update_hyprland_config
    
    echo -e "\n${GREEN}╭─────────────────────────────────────────╮${NC}"
    echo -e "${GREEN}│            🎉 SETUP COMPLETE!           │${NC}"
    echo -e "${GREEN}╰─────────────────────────────────────────╯${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Reboot your system to load NVIDIA drivers"
    echo "  2. Log into Hyprland session"
    echo "  3. Run 'gpu-monitor' to check GPU status"
    echo "  4. Run 'nvidia-optimize' for performance tuning"
    echo
    echo -e "${YELLOW}Configuration files created:${NC}"
    echo "  • ~/.config/hypr/nvidia.conf"
    echo "  • ~/.config/hypr/scaling.conf"
    echo "  • ~/.config/gtk-3.0/settings.ini"
    echo "  • ~/.config/waybar/scaling.css"
    echo "  • ~/.local/bin/gpu-monitor"
    echo "  • ~/.local/bin/nvidia-optimize"
    echo
}

# Run main function
main "$@"
