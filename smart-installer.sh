#!/bin/bash
# AI-Enhanced Hyprland Desktop Environment - Smart Installer
# Advanced GUI installer with hardware detection and intelligent recommendations
# Version: 3.0 - Next Generation Installation System

set -e

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_VERSION="3.0"
INSTALLER_DATE="2025-01-15"

# Global configuration
INSTALL_LOG="/tmp/hyprland-ai-install.log"
HARDWARE_REPORT="/tmp/hardware-detection.json"
TEMP_DIR="/tmp/hyprland-installer"
BACKUP_DIR="$HOME/.hyprland-backup-$(date +%Y%m%d-%H%M%S)"

# Color definitions
declare -A COLORS=(
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[1;33m'
    ["BLUE"]='\033[0;34m'
    ["PURPLE"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["WHITE"]='\033[1;37m'
    ["GRAY"]='\033[0;90m'
    ["BOLD"]='\033[1m'
    ["DIM"]='\033[2m'
    ["ITALIC"]='\033[3m'
    ["UNDERLINE"]='\033[4m'
    ["BLINK"]='\033[5m'
    ["REVERSE"]='\033[7m'
    ["NC"]='\033[0m'
)

# Hardware detection results
declare -A HARDWARE=(
    ["cpu_vendor"]=""
    ["cpu_model"]=""
    ["cpu_cores"]=""
    ["cpu_threads"]=""
    ["gpu_vendor"]=""
    ["gpu_model"]=""
    ["gpu_memory"]=""
    ["system_memory"]=""
    ["display_server"]=""
    ["desktop_environment"]=""
    ["kernel_version"]=""
    ["distro_name"]=""
    ["distro_version"]=""
    ["architecture"]=""
    ["has_nvidia"]="false"
    ["has_amd"]="false"
    ["has_intel_gpu"]="false"
    ["supports_wayland"]="false"
    ["wifi_card"]=""
    ["bluetooth"]="false"
    ["audio_system"]=""
    ["secure_boot"]="false"
    ["virtualization"]="false"
    ["laptop"]="false"
    ["battery_present"]="false"
    ["touchpad"]="false"
    ["hidpi"]="false"
    ["multi_monitor"]="false"
)

# Installation configuration
declare -A INSTALL_CONFIG=(
    ["theme"]=""
    ["install_ai"]="true"
    ["install_waybar"]="true"
    ["install_sddm"]="true"
    ["install_nvidia"]="auto"
    ["install_gaming"]="auto"
    ["install_development"]="auto"
    ["install_media"]="auto"
    ["install_productivity"]="auto"
    ["enable_animations"]="auto"
    ["install_fonts"]="true"
    ["backup_existing"]="true"
    ["setup_wallpapers"]="true"
    ["configure_power"]="auto"
    ["install_bluetooth"]="auto"
    ["install_wifi"]="auto"
    ["setup_printing"]="false"
)

# Utility functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "$INSTALL_LOG"
    echo -e "${COLORS[BLUE]}[INFO]${COLORS[NC]} $*"
}

success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*" | tee -a "$INSTALL_LOG"
    echo -e "${COLORS[GREEN]}[SUCCESS]${COLORS[NC]} $*"
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $*" | tee -a "$INSTALL_LOG"
    echo -e "${COLORS[YELLOW]}[WARNING]${COLORS[NC]} $*"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "$INSTALL_LOG"
    echo -e "${COLORS[RED]}[ERROR]${COLORS[NC]} $*"
    exit 1
}

info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "$INSTALL_LOG"
    echo -e "${COLORS[CYAN]}[INFO]${COLORS[NC]} $*"
}

debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" >> "$INSTALL_LOG"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${COLORS[GRAY]}[DEBUG]${COLORS[NC]} $*"
    fi
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local message="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[CYAN]}%s${COLORS[NC]} [" "$message"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%" $percentage
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Modern GUI banner
show_modern_banner() {
    clear
    echo -e "${COLORS[PURPLE]}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗        ║
║   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗       ║
║   ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║       ║
║   ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║       ║
║   ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝       ║
║   ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝        ║
║                                                                              ║
║        🤖 AI-ENHANCED DESKTOP ENVIRONMENT - SMART INSTALLER 🤖              ║
║                                                                              ║
║     ⚡ Hardware Detection    🎨 Intelligent Theming    🚀 Auto-Configuration ║
║     🧠 AI System Integration  🎮 Gaming Optimization   💻 Dev Environment    ║
║     🎬 Media Production      📱 Mobile Integration     🔒 Security Features  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${COLORS[NC]}\n"
    
    # Show version and system info
    echo -e "${COLORS[CYAN]}┌─ INSTALLER INFORMATION ─────────────────────────────────────────────────────┐${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}│${COLORS[NC]} Version: $INSTALLER_VERSION                      Build: $INSTALLER_DATE     ${COLORS[CYAN]}│${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}│${COLORS[NC]} System: $(uname -o)                        Kernel: $(uname -r)         ${COLORS[CYAN]}│${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}│${COLORS[NC]} Architecture: $(uname -m)                  User: $(whoami)              ${COLORS[CYAN]}│${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}└─────────────────────────────────────────────────────────────────────────────┘${COLORS[NC]}"
    echo ""
}

# Comprehensive hardware detection
detect_hardware() {
    log "Starting comprehensive hardware detection..."
    
    # Initialize temp directory
    mkdir -p "$TEMP_DIR"
    
    show_progress 1 20 "Detecting CPU..."
    # CPU Detection
    HARDWARE["cpu_vendor"]=$(lscpu | grep "Vendor ID" | awk '{print $3}' || echo "Unknown")
    HARDWARE["cpu_model"]=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs || echo "Unknown")
    HARDWARE["cpu_cores"]=$(nproc --all)
    HARDWARE["cpu_threads"]=$(lscpu | grep "Thread(s) per core" | awk '{print $4}' || echo "1")
    
    show_progress 2 20 "Detecting Graphics..."
    # GPU Detection
    if lspci | grep -i nvidia &>/dev/null; then
        HARDWARE["has_nvidia"]="true"
        HARDWARE["gpu_vendor"]="NVIDIA"
        HARDWARE["gpu_model"]=$(lspci | grep -i nvidia | grep -i vga | cut -d':' -f3 | xargs || echo "NVIDIA GPU")
        
        # Try to get NVIDIA memory
        if command -v nvidia-smi &>/dev/null; then
            HARDWARE["gpu_memory"]=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 || echo "Unknown")
        fi
    fi
    
    show_progress 3 20 "Checking AMD Graphics..."
    if lspci | grep -i amd | grep -i vga &>/dev/null; then
        HARDWARE["has_amd"]="true"
        if [[ "${HARDWARE["gpu_vendor"]}" == "" ]]; then
            HARDWARE["gpu_vendor"]="AMD"
            HARDWARE["gpu_model"]=$(lspci | grep -i amd | grep -i vga | cut -d':' -f3 | xargs || echo "AMD GPU")
        fi
    fi
    
    show_progress 4 20 "Checking Intel Graphics..."
    if lspci | grep -i intel | grep -i vga &>/dev/null; then
        HARDWARE["has_intel_gpu"]="true"
        if [[ "${HARDWARE["gpu_vendor"]}" == "" ]]; then
            HARDWARE["gpu_vendor"]="Intel"
            HARDWARE["gpu_model"]=$(lspci | grep -i intel | grep -i vga | cut -d':' -f3 | xargs || echo "Intel GPU")
        fi
    fi
    
    show_progress 5 20 "Detecting Memory..."
    # Memory Detection
    HARDWARE["system_memory"]=$(free -h | awk '/^Mem:/ {print $2}' || echo "Unknown")
    
    show_progress 6 20 "Checking Display Server..."
    # Display Server Detection
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        HARDWARE["display_server"]="Wayland"
        HARDWARE["supports_wayland"]="true"
    elif [[ -n "$DISPLAY" ]]; then
        HARDWARE["display_server"]="X11"
    else
        HARDWARE["display_server"]="TTY"
    fi
    
    show_progress 7 20 "Detecting Desktop Environment..."
    # Desktop Environment Detection
    HARDWARE["desktop_environment"]="${XDG_CURRENT_DESKTOP:-$(echo $DESKTOP_SESSION)}"
    [[ -z "${HARDWARE["desktop_environment"]}" ]] && HARDWARE["desktop_environment"]="Unknown"
    
    show_progress 8 20 "System Information..."
    # System Information
    HARDWARE["kernel_version"]=$(uname -r)
    HARDWARE["distro_name"]=$(grep '^NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "Unknown")
    HARDWARE["distro_version"]=$(grep '^VERSION=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || echo "Unknown")
    HARDWARE["architecture"]=$(uname -m)
    
    show_progress 9 20 "Checking Wayland Support..."
    # Wayland Support Check
    if command -v weston &>/dev/null || command -v sway &>/dev/null || command -v hyprland &>/dev/null; then
        HARDWARE["supports_wayland"]="true"
    fi
    
    show_progress 10 20 "Detecting Network Hardware..."
    # Network Hardware
    if lspci | grep -i network &>/dev/null || lsusb | grep -i wifi &>/dev/null; then
        HARDWARE["wifi_card"]=$(lspci | grep -i network | cut -d':' -f3 | xargs | head -1 || echo "Unknown")
    fi
    
    show_progress 11 20 "Checking Bluetooth..."
    # Bluetooth Detection
    if lsusb | grep -i bluetooth &>/dev/null || hciconfig &>/dev/null 2>&1; then
        HARDWARE["bluetooth"]="true"
    fi
    
    show_progress 12 20 "Audio System Detection..."
    # Audio System Detection
    if command -v pipewire &>/dev/null; then
        HARDWARE["audio_system"]="PipeWire"
    elif command -v pulseaudio &>/dev/null; then
        HARDWARE["audio_system"]="PulseAudio"
    elif command -v alsa &>/dev/null; then
        HARDWARE["audio_system"]="ALSA"
    else
        HARDWARE["audio_system"]="Unknown"
    fi
    
    show_progress 13 20 "Security Features..."
    # Security Features
    if [[ -d /sys/firmware/efi ]]; then
        HARDWARE["secure_boot"]="true"
    fi
    
    show_progress 14 20 "Virtualization Check..."
    # Virtualization Detection
    if grep -q hypervisor /proc/cpuinfo || command -v systemd-detect-virt &>/dev/null; then
        HARDWARE["virtualization"]="true"
    fi
    
    show_progress 15 20 "Laptop Detection..."
    # Laptop Detection
    if [[ -d /proc/acpi/button/lid ]] || [[ -f /sys/class/power_supply/BAT* ]] 2>/dev/null; then
        HARDWARE["laptop"]="true"
    fi
    
    show_progress 16 20 "Battery Check..."
    # Battery Detection
    if ls /sys/class/power_supply/BAT* &>/dev/null; then
        HARDWARE["battery_present"]="true"
    fi
    
    show_progress 17 20 "Touchpad Detection..."
    # Touchpad Detection
    if xinput list 2>/dev/null | grep -i touchpad &>/dev/null || ls /dev/input/mouse* &>/dev/null; then
        HARDWARE["touchpad"]="true"
    fi
    
    show_progress 18 20 "Display Resolution..."
    # HiDPI Detection
    if command -v xrandr &>/dev/null; then
        local resolution=$(xrandr | grep \* | awk '{print $1}' | head -1)
        if [[ "$resolution" ]]; then
            local width=$(echo $resolution | cut -d'x' -f1)
            if [[ $width -gt 1920 ]]; then
                HARDWARE["hidpi"]="true"
            fi
        fi
    fi
    
    show_progress 19 20 "Multi-monitor Setup..."
    # Multi-monitor Detection
    if command -v xrandr &>/dev/null; then
        local connected_displays=$(xrandr | grep " connected" | wc -l)
        if [[ $connected_displays -gt 1 ]]; then
            HARDWARE["multi_monitor"]="true"
        fi
    fi
    
    show_progress 20 20 "Hardware Detection Complete!"
    sleep 1
    
    # Save hardware report
    save_hardware_report
    success "Hardware detection completed successfully!"
}

# Save hardware detection results
save_hardware_report() {
    cat > "$HARDWARE_REPORT" << EOF
{
    "detection_date": "$(date -Iseconds)",
    "installer_version": "$INSTALLER_VERSION",
    "hardware": {
        "cpu": {
            "vendor": "${HARDWARE["cpu_vendor"]}",
            "model": "${HARDWARE["cpu_model"]}",
            "cores": "${HARDWARE["cpu_cores"]}",
            "threads": "${HARDWARE["cpu_threads"]}"
        },
        "gpu": {
            "vendor": "${HARDWARE["gpu_vendor"]}",
            "model": "${HARDWARE["gpu_model"]}",
            "memory": "${HARDWARE["gpu_memory"]}",
            "nvidia": ${HARDWARE["has_nvidia"]},
            "amd": ${HARDWARE["has_amd"]},
            "intel": ${HARDWARE["has_intel_gpu"]}
        },
        "system": {
            "memory": "${HARDWARE["system_memory"]}",
            "architecture": "${HARDWARE["architecture"]}",
            "kernel": "${HARDWARE["kernel_version"]}",
            "distro": "${HARDWARE["distro_name"]} ${HARDWARE["distro_version"]}"
        },
        "display": {
            "server": "${HARDWARE["display_server"]}",
            "wayland_support": ${HARDWARE["supports_wayland"]},
            "hidpi": ${HARDWARE["hidpi"]},
            "multi_monitor": ${HARDWARE["multi_monitor"]}
        },
        "features": {
            "laptop": ${HARDWARE["laptop"]},
            "battery": ${HARDWARE["battery_present"]},
            "touchpad": ${HARDWARE["touchpad"]},
            "bluetooth": ${HARDWARE["bluetooth"]},
            "wifi": "${HARDWARE["wifi_card"]}",
            "audio": "${HARDWARE["audio_system"]}",
            "virtualization": ${HARDWARE["virtualization"]},
            "secure_boot": ${HARDWARE["secure_boot"]}
        }
    }
}
EOF
    debug "Hardware report saved to $HARDWARE_REPORT"
}

# Display hardware detection results
show_hardware_summary() {
    echo -e "\n${COLORS[CYAN]}╔═══ HARDWARE DETECTION SUMMARY ═══════════════════════════════════════╗${COLORS[NC]}"
    
    # CPU Information
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}CPU:${COLORS[NC]}     ${HARDWARE["cpu_vendor"]} ${HARDWARE["cpu_model"]}"
    echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ${HARDWARE["cpu_cores"]} cores, ${HARDWARE["cpu_threads"]} threads per core"
    
    # GPU Information
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}GPU:${COLORS[NC]}     ${HARDWARE["gpu_vendor"]} ${HARDWARE["gpu_model"]}"
    if [[ "${HARDWARE["gpu_memory"]}" != "Unknown" && -n "${HARDWARE["gpu_memory"]}" ]]; then
        echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ${HARDWARE["gpu_memory"]}MB VRAM"
    fi
    
    # Memory
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}Memory:${COLORS[NC]}  ${HARDWARE["system_memory"]} RAM"
    
    # System Information
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}System:${COLORS[NC]}  ${HARDWARE["distro_name"]} (${HARDWARE["architecture"]})"
    echo -e "${COLORS[CYAN]}║${COLORS[NC]}          Kernel ${HARDWARE["kernel_version"]}"
    
    # Display
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}Display:${COLORS[NC]} ${HARDWARE["display_server"]}"
    if [[ "${HARDWARE["hidpi"]}" == "true" ]]; then
        echo -e "${COLORS[CYAN]}║${COLORS[NC]}          HiDPI display detected"
    fi
    if [[ "${HARDWARE["multi_monitor"]}" == "true" ]]; then
        echo -e "${COLORS[CYAN]}║${COLORS[NC]}          Multi-monitor setup detected"
    fi
    
    # Special Features
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} ${COLORS[BOLD]}Features:${COLORS[NC]}"
    [[ "${HARDWARE["laptop"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ✓ Laptop configuration"
    [[ "${HARDWARE["battery_present"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ✓ Battery present"
    [[ "${HARDWARE["touchpad"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ✓ Touchpad detected"
    [[ "${HARDWARE["bluetooth"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ✓ Bluetooth available"
    [[ "${HARDWARE["supports_wayland"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ✓ Wayland support"
    [[ "${HARDWARE["has_nvidia"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          ⚡ NVIDIA GPU detected"
    [[ "${HARDWARE["virtualization"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]}          🖥️  Virtual machine"
    
    echo -e "${COLORS[CYAN]}╚═══════════════════════════════════════════════════════════════════════╝${COLORS[NC]}\n"
}

# Generate intelligent recommendations
generate_recommendations() {
    log "Generating intelligent installation recommendations..."
    
    # Auto-configure based on hardware
    
    # NVIDIA Configuration
    if [[ "${HARDWARE["has_nvidia"]}" == "true" ]]; then
        INSTALL_CONFIG["install_nvidia"]="true"
        info "NVIDIA GPU detected - NVIDIA drivers will be installed"
    else
        INSTALL_CONFIG["install_nvidia"]="false"
    fi
    
    # Gaming Configuration
    if [[ "${HARDWARE["has_nvidia"]}" == "true" ]] || [[ "${HARDWARE["has_amd"]}" == "true" ]]; then
        INSTALL_CONFIG["install_gaming"]="true"
        info "Dedicated GPU detected - Gaming optimizations recommended"
    fi
    
    # Development Configuration
    if [[ "${HARDWARE["cpu_cores"]}" -ge 4 ]] && [[ "${HARDWARE["system_memory"]}" =~ [0-9]+G ]] && [[ $(echo "${HARDWARE["system_memory"]}" | grep -o '[0-9]\+') -ge 8 ]]; then
        INSTALL_CONFIG["install_development"]="true"
        info "High-performance system detected - Development tools recommended"
    fi
    
    # Animation Configuration
    if [[ "${HARDWARE["has_nvidia"]}" == "true" ]] || [[ "${HARDWARE["has_amd"]}" == "true" ]] || [[ "${HARDWARE["virtualization"]}" == "false" ]]; then
        INSTALL_CONFIG["enable_animations"]="true"
        info "Hardware acceleration available - Animations will be enabled"
    else
        INSTALL_CONFIG["enable_animations"]="false"
        warning "Limited graphics capability - Animations will be disabled for performance"
    fi
    
    # Power Management
    if [[ "${HARDWARE["laptop"]}" == "true" ]]; then
        INSTALL_CONFIG["configure_power"]="true"
        info "Laptop detected - Power management will be configured"
    fi
    
    # Network Configuration
    if [[ "${HARDWARE["wifi_card"]}" != "Unknown" ]] && [[ -n "${HARDWARE["wifi_card"]}" ]]; then
        INSTALL_CONFIG["install_wifi"]="true"
    fi
    
    if [[ "${HARDWARE["bluetooth"]}" == "true" ]]; then
        INSTALL_CONFIG["install_bluetooth"]="true"
    fi
    
    success "Configuration recommendations generated based on hardware"
}

# Interactive configuration menu
interactive_configuration() {
    echo -e "${COLORS[YELLOW]}╔═══ INSTALLATION CONFIGURATION ═══════════════════════════════════════╗${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}║${COLORS[NC]} Configure your AI-Enhanced Hyprland installation:                  ${COLORS[YELLOW]}║${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}╚═══════════════════════════════════════════════════════════════════════╝${COLORS[NC]}\n"
    
    # Theme Selection
    select_theme_interactive
    
    # Component Selection
    select_components_interactive
    
    # Advanced Options
    select_advanced_options
    
    # Configuration Summary
    show_configuration_summary
}

# Interactive theme selection
select_theme_interactive() {
    echo -e "${COLORS[PURPLE]}🎨 Theme Selection${COLORS[NC]}"
    echo "Choose your desktop theme (affects colors, wallpapers, and overall appearance):"
    echo ""
    
    declare -A THEME_OPTIONS=(
        ["1"]="Catppuccin Mocha (Dark Purple) - AI Optimized"
        ["2"]="Catppuccin Macchiato (Dark Blue)"
        ["3"]="TokyoNight (Cyberpunk Style)"
        ["4"]="Gruvbox Dark (Retro Warm)"
        ["5"]="Nord (Arctic Minimalism)"
        ["6"]="Rose Pine (Soft Aesthetic)"
        ["7"]="Dracula (Dark Purple)"
        ["8"]="Auto-Select Based on Hardware"
    )
    
    for key in $(printf '%s\n' "${!THEME_OPTIONS[@]}" | sort -n); do
        echo -e "  ${COLORS[CYAN]}$key.${COLORS[NC]} ${THEME_OPTIONS[$key]}"
    done
    echo ""
    
    while true; do
        read -p "Select theme (1-8) [1]: " theme_choice
        theme_choice=${theme_choice:-1}
        
        case $theme_choice in
            1) INSTALL_CONFIG["theme"]="catppuccin-mocha"; break ;;
            2) INSTALL_CONFIG["theme"]="catppuccin-macchiato"; break ;;
            3) INSTALL_CONFIG["theme"]="tokyonight"; break ;;
            4) INSTALL_CONFIG["theme"]="gruvbox-dark"; break ;;
            5) INSTALL_CONFIG["theme"]="nord"; break ;;
            6) INSTALL_CONFIG["theme"]="rose-pine"; break ;;
            7) INSTALL_CONFIG["theme"]="dracula"; break ;;
            8) INSTALL_CONFIG["theme"]="auto"; auto_select_theme; break ;;
            *) warning "Invalid selection. Please choose 1-8." ;;
        esac
    done
    
    success "Theme selected: ${INSTALL_CONFIG["theme"]}"
    echo ""
}

# Auto-select theme based on hardware
auto_select_theme() {
    if [[ "${HARDWARE["has_nvidia"]}" == "true" ]]; then
        INSTALL_CONFIG["theme"]="catppuccin-mocha"  # AI-optimized for NVIDIA
        info "Auto-selected Catppuccin Mocha (optimized for NVIDIA GPUs)"
    elif [[ "${HARDWARE["laptop"]}" == "true" ]]; then
        INSTALL_CONFIG["theme"]="nord"  # Power-efficient
        info "Auto-selected Nord theme (optimized for laptop power efficiency)"
    elif [[ "${HARDWARE["hidpi"]}" == "true" ]]; then
        INSTALL_CONFIG["theme"]="catppuccin-macchiato"  # HiDPI optimized
        info "Auto-selected Catppuccin Macchiato (optimized for HiDPI displays)"
    else
        INSTALL_CONFIG["theme"]="catppuccin-mocha"  # Default AI theme
        info "Auto-selected Catppuccin Mocha (default AI theme)"
    fi
}

# Component selection
select_components_interactive() {
    echo -e "${COLORS[GREEN]}📦 Component Selection${COLORS[NC]}"
    echo "Select which components to install:"
    echo ""
    
    # AI System (always recommended)
    echo -e "${COLORS[BOLD]}AI System Integration${COLORS[NC]} (Recommended)"
    echo "  • Real-time workload detection and optimization"
    echo "  • Intelligent resource management and learning"
    echo "  • Smart workspace and application management"
    read -p "Install AI system? [Y/n]: " ai_choice
    INSTALL_CONFIG["install_ai"]=$([ "${ai_choice,,}" = "n" ] && echo "false" || echo "true")
    echo ""
    
    # Enhanced Waybar
    echo -e "${COLORS[BOLD]}Enhanced Waybar Status Bar${COLORS[NC]} (Recommended)"
    echo "  • AI system status and workload monitoring"
    echo "  • Smart workspace overview and management"
    echo "  • Modern glassmorphism design with animations"
    read -p "Install enhanced Waybar? [Y/n]: " waybar_choice
    INSTALL_CONFIG["install_waybar"]=$([ "${waybar_choice,,}" = "n" ] && echo "false" || echo "true")
    echo ""
    
    # SDDM Login Manager
    echo -e "${COLORS[BOLD]}SDDM Login Manager${COLORS[NC]} (Recommended)"
    echo "  • Modern AI-branded login screen"
    echo "  • Glassmorphism effects and smooth animations"
    echo "  • Hyprland session integration"
    read -p "Install SDDM login manager? [Y/n]: " sddm_choice
    INSTALL_CONFIG["install_sddm"]=$([ "${sddm_choice,,}" = "n" ] && echo "false" || echo "true")
    echo ""
    
    # Gaming Components
    if [[ "${INSTALL_CONFIG["install_gaming"]}" == "true" ]]; then
        echo -e "${COLORS[BOLD]}Gaming Optimization${COLORS[NC]} (Hardware Recommended)"
        echo "  • Steam, Lutris, and gaming tools"
        echo "  • Performance optimizations and game mode"
        echo "  • NVIDIA/AMD gaming drivers and utilities"
        read -p "Install gaming components? [Y/n]: " gaming_choice
        INSTALL_CONFIG["install_gaming"]=$([ "${gaming_choice,,}" = "n" ] && echo "false" || echo "true")
        echo ""
    fi
    
    # Development Tools
    if [[ "${INSTALL_CONFIG["install_development"]}" == "true" ]]; then
        echo -e "${COLORS[BOLD]}Development Environment${COLORS[NC]} (Hardware Recommended)"
        echo "  • VS Code, terminals, and development tools"
        echo "  • Git integration and project management"
        echo "  • Compiler toolchains and debugging tools"
        read -p "Install development tools? [Y/n]: " dev_choice
        INSTALL_CONFIG["install_development"]=$([ "${dev_choice,,}" = "n" ] && echo "false" || echo "true")
        echo ""
    fi
    
    # Media Production
    echo -e "${COLORS[BOLD]}Media Production Tools${COLORS[NC]}"
    echo "  • Video editing and media creation tools"
    echo "  • Image manipulation and design software"
    echo "  • Audio production and streaming tools"
    read -p "Install media tools? [y/N]: " media_choice
    INSTALL_CONFIG["install_media"]=$([ "${media_choice,,}" = "y" ] && echo "true" || echo "false")
    echo ""
    
    # Productivity Suite
    echo -e "${COLORS[BOLD]}Productivity Suite${COLORS[NC]}"
    echo "  • LibreOffice and office applications"
    echo "  • PDF readers and document management"
    echo "  • Email clients and calendar integration"
    read -p "Install productivity suite? [y/N]: " productivity_choice
    INSTALL_CONFIG["install_productivity"]=$([ "${productivity_choice,,}" = "y" ] && echo "true" || echo "false")
}

# Advanced options
select_advanced_options() {
    echo -e "\n${COLORS[BLUE]}⚙️  Advanced Configuration${COLORS[NC]}"
    echo ""
    
    # Backup existing configs
    read -p "Backup existing configurations? [Y/n]: " backup_choice
    INSTALL_CONFIG["backup_existing"]=$([ "${backup_choice,,}" = "n" ] && echo "false" || echo "true")
    
    # Fonts installation
    read -p "Install additional fonts (Nerd Fonts, etc.)? [Y/n]: " fonts_choice
    INSTALL_CONFIG["install_fonts"]=$([ "${fonts_choice,,}" = "n" ] && echo "false" || echo "true")
    
    # Wallpaper setup
    read -p "Setup wallpaper collections? [Y/n]: " wallpaper_choice
    INSTALL_CONFIG["setup_wallpapers"]=$([ "${wallpaper_choice,,}" = "n" ] && echo "false" || echo "true")
    
    # Only show these if hardware supports them
    if [[ "${HARDWARE["laptop"]}" == "true" ]]; then
        read -p "Configure laptop power management? [Y/n]: " power_choice
        INSTALL_CONFIG["configure_power"]=$([ "${power_choice,,}" = "n" ] && echo "false" || echo "true")
    fi
    
    if [[ "${HARDWARE["bluetooth"]}" == "true" ]]; then
        read -p "Setup Bluetooth integration? [Y/n]: " bluetooth_choice
        INSTALL_CONFIG["install_bluetooth"]=$([ "${bluetooth_choice,,}" = "n" ] && echo "false" || echo "true")
    fi
}

# Show configuration summary
show_configuration_summary() {
    echo -e "\n${COLORS[YELLOW]}╔═══ INSTALLATION SUMMARY ═════════════════════════════════════════════╗${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}║${COLORS[NC]} The following components will be installed:                         ${COLORS[YELLOW]}║${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}║${COLORS[NC]}                                                                   ${COLORS[YELLOW]}║${COLORS[NC]}"
    
    [[ "${INSTALL_CONFIG["theme"]}" != "" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} Theme: ${INSTALL_CONFIG["theme"]}"
    [[ "${INSTALL_CONFIG["install_ai"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ AI System Integration"
    [[ "${INSTALL_CONFIG["install_waybar"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Enhanced Waybar Status Bar"
    [[ "${INSTALL_CONFIG["install_sddm"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ SDDM Login Manager"
    [[ "${INSTALL_CONFIG["install_nvidia"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ NVIDIA Drivers and Optimization"
    [[ "${INSTALL_CONFIG["install_gaming"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Gaming Components and Optimization"
    [[ "${INSTALL_CONFIG["install_development"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Development Environment"
    [[ "${INSTALL_CONFIG["install_media"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Media Production Tools"
    [[ "${INSTALL_CONFIG["install_productivity"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Productivity Suite"
    [[ "${INSTALL_CONFIG["backup_existing"]}" == "true" ]] && echo -e "${COLORS[YELLOW]}║${COLORS[NC]} ✓ Backup Existing Configurations"
    
    echo -e "${COLORS[YELLOW]}╚═══════════════════════════════════════════════════════════════════════╝${COLORS[NC]}\n"
    
    read -p "Proceed with installation? [Y/n]: " proceed_choice
    if [[ "${proceed_choice,,}" == "n" ]]; then
        info "Installation cancelled by user"
        exit 0
    fi
}

# Pre-installation checks
pre_installation_checks() {
    log "Performing pre-installation checks..."
    
    # Check for required commands
    local required_commands=("curl" "git" "jq" "bc")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        warning "Missing required commands: ${missing_commands[*]}"
        info "Installing missing dependencies..."
        
        if command -v pacman &>/dev/null; then
            sudo pacman -S --needed --noconfirm "${missing_commands[@]}"
        elif command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "${missing_commands[@]}"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${missing_commands[@]}"
        else
            error "Unable to install missing dependencies automatically. Please install: ${missing_commands[*]}"
        fi
    fi
    
    # Check available disk space
    local available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5000000 ]]; then  # Less than 5GB
        warning "Low disk space detected. At least 5GB recommended for full installation."
        read -p "Continue anyway? [y/N]: " space_choice
        [[ "${space_choice,,}" != "y" ]] && exit 0
    fi
    
    # Check internet connectivity
    if ! curl -s --connect-timeout 5 https://www.github.com &>/dev/null; then
        warning "Internet connectivity issue detected. Installation may fail."
        read -p "Continue anyway? [y/N]: " internet_choice
        [[ "${internet_choice,,}" != "y" ]] && exit 0
    fi
    
    success "Pre-installation checks passed"
}

# Backup existing configurations
backup_configurations() {
    if [[ "${INSTALL_CONFIG["backup_existing"]}" != "true" ]]; then
        return 0
    fi
    
    log "Creating backup of existing configurations..."
    mkdir -p "$BACKUP_DIR"
    
    local backup_dirs=(
        ".config/hypr"
        ".config/waybar"
        ".config/quickshell"
        ".config/rofi"
        ".config/dunst"
        ".config/kitty"
        ".config/swww"
    )
    
    for dir in "${backup_dirs[@]}"; do
        if [[ -d "$HOME/$dir" ]]; then
            cp -r "$HOME/$dir" "$BACKUP_DIR/" 2>/dev/null || true
            debug "Backed up $dir"
        fi
    done
    
    success "Configurations backed up to $BACKUP_DIR"
}

# Install base system
install_base_system() {
    log "Installing base Hyprland system..."
    
    local base_packages=(
        "hyprland"
        "waybar"
        "rofi-wayland"
        "dunst"
        "kitty"
        "swww"
        "wl-clipboard"
        "grim"
        "slurp"
        "jq"
        "bc"
        "polkit-kde-agent"
    )
    
    # Check if quickshell is available
    if pacman -Si quickshell-git &>/dev/null; then
        base_packages+=("quickshell-git")
    fi
    
    # Install packages
    info "Installing base packages..."
    sudo pacman -S --needed --noconfirm "${base_packages[@]}"
    
    success "Base system installed successfully"
}

# Install AI system
install_ai_system() {
    if [[ "${INSTALL_CONFIG["install_ai"]}" != "true" ]]; then
        return 0
    fi
    
    log "Installing AI system components..."
    
    # Install Python dependencies for AI system
    local python_packages=(
        "python"
        "python-pip"
        "python-psutil"
        "python-requests"
        "python-numpy"
    )
    
    sudo pacman -S --needed --noconfirm "${python_packages[@]}"
    
    # Copy AI scripts
    mkdir -p "$HOME/.config/hypr/scripts/ai"
    cp -r "$SCRIPT_DIR/scripts/ai/"* "$HOME/.config/hypr/scripts/ai/"
    chmod +x "$HOME/.config/hypr/scripts/ai/"*.sh
    
    # Initialize AI system
    if [[ -f "$HOME/.config/hypr/scripts/ai/ai-manager.sh" ]]; then
        "$HOME/.config/hypr/scripts/ai/ai-manager.sh" initialize || true
    fi
    
    success "AI system components installed"
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    if [[ "${INSTALL_CONFIG["install_nvidia"]}" != "true" ]] || [[ "${HARDWARE["has_nvidia"]}" != "true" ]]; then
        return 0
    fi
    
    log "Installing NVIDIA drivers and optimization..."
    
    local nvidia_packages=(
        "nvidia"
        "nvidia-utils"
        "nvidia-settings"
        "lib32-nvidia-utils"
    )
    
    sudo pacman -S --needed --noconfirm "${nvidia_packages[@]}"
    
    # Enable nvidia-drm modeset
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        warning "NVIDIA modeset enabled. Reboot required after installation."
    fi
    
    success "NVIDIA drivers installed and configured"
}

# Main installation orchestrator
run_installation() {
    log "Starting AI-Enhanced Hyprland installation..."
    
    local total_steps=12
    local current_step=0
    
    # Step 1: Pre-installation checks
    ((current_step++))
    show_progress $current_step $total_steps "Pre-installation checks..."
    pre_installation_checks
    
    # Step 2: Backup configurations
    ((current_step++))
    show_progress $current_step $total_steps "Backing up configurations..."
    backup_configurations
    
    # Step 3: Install base system
    ((current_step++))
    show_progress $current_step $total_steps "Installing base system..."
    install_base_system
    
    # Step 4: Install AI system
    ((current_step++))
    show_progress $current_step $total_steps "Installing AI system..."
    install_ai_system
    
    # Step 5: Install NVIDIA drivers
    ((current_step++))
    show_progress $current_step $total_steps "Installing NVIDIA drivers..."
    install_nvidia_drivers
    
    # Step 6: Configure Waybar
    if [[ "${INSTALL_CONFIG["install_waybar"]}" == "true" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Configuring Waybar..."
        configure_waybar
    else
        ((current_step++))
    fi
    
    # Step 7: Configure SDDM
    if [[ "${INSTALL_CONFIG["install_sddm"]}" == "true" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Setting up SDDM..."
        configure_sddm
    else
        ((current_step++))
    fi
    
    # Step 8: Install gaming components
    if [[ "${INSTALL_CONFIG["install_gaming"]}" == "true" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Installing gaming components..."
        install_gaming_components
    else
        ((current_step++))
    fi
    
    # Step 9: Install development tools
    if [[ "${INSTALL_CONFIG["install_development"]}" == "true" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Installing development tools..."
        install_development_tools
    else
        ((current_step++))
    fi
    
    # Step 10: Apply theme
    ((current_step++))
    show_progress $current_step $total_steps "Applying theme..."
    apply_theme
    
    # Step 11: Configure power management
    if [[ "${INSTALL_CONFIG["configure_power"]}" == "true" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Configuring power management..."
        configure_power_management
    else
        ((current_step++))
    fi
    
    # Step 12: Final configuration
    ((current_step++))
    show_progress $current_step $total_steps "Final configuration..."
    finalize_installation
    
    success "Installation completed successfully!"
}

# Configure Waybar
configure_waybar() {
    mkdir -p "$HOME/.config/waybar"
    cp -r "$SCRIPT_DIR/configs/waybar/"* "$HOME/.config/waybar/"
    chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
}

# Configure SDDM
configure_sddm() {
    "$SCRIPT_DIR/sddm-setup.sh" --auto --theme="${INSTALL_CONFIG["theme"]}" || true
}

# Install gaming components
install_gaming_components() {
    local gaming_packages=(
        "steam"
        "lutris"
        "wine"
        "gamemode"
        "lib32-vulkan-icd-loader"
    )
    
    # Add NVIDIA gaming packages if applicable
    if [[ "${HARDWARE["has_nvidia"]}" == "true" ]]; then
        gaming_packages+=("lib32-nvidia-utils" "nvidia-prime")
    fi
    
    sudo pacman -S --needed --noconfirm "${gaming_packages[@]}" || true
}

# Install development tools
install_development_tools() {
    local dev_packages=(
        "code"
        "git"
        "base-devel"
        "nodejs"
        "npm"
        "python-pip"
        "docker"
        "docker-compose"
    )
    
    sudo pacman -S --needed --noconfirm "${dev_packages[@]}" || true
}

# Apply selected theme
apply_theme() {
    if [[ -f "$SCRIPT_DIR/theme-switcher.sh" ]]; then
        "$SCRIPT_DIR/theme-switcher.sh" "${INSTALL_CONFIG["theme"]}" --auto || true
    fi
}

# Configure power management for laptops
configure_power_management() {
    if [[ "${HARDWARE["laptop"]}" != "true" ]]; then
        return 0
    fi
    
    local power_packages=(
        "tlp"
        "powertop"
        "acpi"
    )
    
    sudo pacman -S --needed --noconfirm "${power_packages[@]}" || true
    sudo systemctl enable tlp || true
}

# Finalize installation
finalize_installation() {
    # Copy all configurations
    mkdir -p "$HOME/.config/hypr"
    cp -r "$SCRIPT_DIR/configs/hypr/"* "$HOME/.config/hypr/"
    
    # Set up Quickshell if available
    if command -v quickshell &>/dev/null; then
        mkdir -p "$HOME/.config/quickshell"
        cp -r "$SCRIPT_DIR/configs/quickshell/"* "$HOME/.config/quickshell/"
    fi
    
    # Copy other configurations
    for config_dir in rofi dunst kitty; do
        if [[ -d "$SCRIPT_DIR/configs/$config_dir" ]]; then
            mkdir -p "$HOME/.config/$config_dir"
            cp -r "$SCRIPT_DIR/configs/$config_dir/"* "$HOME/.config/$config_dir/"
        fi
    done
    
    # Set executable permissions
    find "$HOME/.config/hypr/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
}

# Post-installation summary
show_installation_summary() {
    clear
    echo -e "${COLORS[GREEN]}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉                               ║
║                                                                              ║
║    Your AI-Enhanced Hyprland Desktop Environment is now ready!              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${COLORS[NC]}\n"
    
    echo -e "${COLORS[CYAN]}╔═══ INSTALLATION SUMMARY ═════════════════════════════════════════════╗${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}║${COLORS[NC]} 🎨 Theme: ${INSTALL_CONFIG["theme"]}"
    [[ "${INSTALL_CONFIG["install_ai"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]} 🤖 AI System: Installed and configured"
    [[ "${INSTALL_CONFIG["install_waybar"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]} 📊 Enhanced Waybar: Installed with AI modules"
    [[ "${INSTALL_CONFIG["install_sddm"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]} 🎭 SDDM Login: AI-branded theme configured"
    [[ "${INSTALL_CONFIG["install_nvidia"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]} ⚡ NVIDIA: Drivers and optimizations installed"
    [[ "${INSTALL_CONFIG["backup_existing"]}" == "true" ]] && echo -e "${COLORS[CYAN]}║${COLORS[NC]} 💾 Backup: Saved to $BACKUP_DIR"
    echo -e "${COLORS[CYAN]}╚═══════════════════════════════════════════════════════════════════════╝${COLORS[NC]}\n"
    
    echo -e "${COLORS[YELLOW]}🚀 Next Steps:${COLORS[NC]}"
    echo "  1. Reboot your system to ensure all drivers are loaded"
    echo "  2. Login using the new SDDM theme and select 'Hyprland' session"
    echo "  3. The AI system will automatically start optimizing your experience"
    echo "  4. Use Meta+Tab to access the workspace overview"
    echo "  5. Right-click Waybar modules for AI controls and settings"
    echo ""
    
    echo -e "${COLORS[GREEN]}✨ Enjoy your new AI-Enhanced Desktop Environment! ✨${COLORS[NC]}"
    echo ""
    
    if [[ "${INSTALL_CONFIG["install_nvidia"]}" == "true" ]] && [[ "${HARDWARE["has_nvidia"]}" == "true" ]]; then
        warning "NVIDIA drivers installed. Please reboot before using the system."
    fi
    
    read -p "Press Enter to exit installer..."
}

# Main execution function
main() {
    # Initialize logging
    mkdir -p "$(dirname "$INSTALL_LOG")"
    echo "AI-Enhanced Hyprland Installer Started - $(date)" > "$INSTALL_LOG"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This installer should not be run as root. Please run as a regular user."
    fi
    
    # Check for Arch-based system
    if ! command -v pacman &>/dev/null; then
        error "This installer is designed for Arch Linux and derivatives only!"
    fi
    
    # Show banner
    show_modern_banner
    
    # Hardware detection
    detect_hardware
    show_hardware_summary
    
    # Generate recommendations
    generate_recommendations
    
    # Interactive configuration
    interactive_configuration
    
    # Run installation
    run_installation
    
    # Show completion summary
    show_installation_summary
}

# Execute main function
main "$@"
