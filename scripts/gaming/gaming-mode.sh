#!/bin/bash
# Gaming Mode Manager
# Performance optimization and gaming enhancements for Hyprland

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hypr/gaming"
PROFILES_DIR="$CONFIG_DIR/profiles"
GAMING_CONFIG="$CONFIG_DIR/gaming.conf"
STATE_FILE="$CONFIG_DIR/gaming_state"

# Gaming settings
GAMING_CPU_GOVERNOR="performance"
NORMAL_CPU_GOVERNOR="powersave"
GAMING_PRIORITY="nice -n -10"
COMPOSITING_DISABLED=false

# Logging
log() { echo -e "${BLUE}[GAMING]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR"
    touch "$STATE_FILE"
}

# Check if gaming mode is active
is_gaming_active() {
    [ -f "$STATE_FILE" ] && grep -q "ACTIVE" "$STATE_FILE"
}

# Get current CPU governor
get_cpu_governor() {
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    else
        echo "unknown"
    fi
}

# Set CPU governor
set_cpu_governor() {
    local governor="$1"
    
    if [ "$(id -u)" -eq 0 ]; then
        echo "$governor" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
        success "CPU governor set to: $governor"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec sh -c "echo '$governor' | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null"
        success "CPU governor set to: $governor"
    else
        warning "Root access required to change CPU governor"
    fi
}

# Optimize system for gaming
optimize_system() {
    log "Optimizing system for gaming..."
    
    # Set CPU governor to performance
    set_cpu_governor "$GAMING_CPU_GOVERNOR"
    
    # Disable swap to reduce stuttering
    if command -v swapoff >/dev/null 2>&1 && [ "$(swapon --show | wc -l)" -gt 0 ]; then
        sudo swapoff -a 2>/dev/null || warning "Could not disable swap"
        log "Swap disabled for better performance"
    fi
    
    # Set I/O scheduler to deadline for SSDs or mq-deadline
    for disk in /sys/block/sd* /sys/block/nvme*; do
        if [ -d "$disk" ]; then
            local disk_name=$(basename "$disk")
            if [ -f "$disk/queue/scheduler" ]; then
                if grep -q "mq-deadline" "$disk/queue/scheduler"; then
                    echo "mq-deadline" | sudo tee "$disk/queue/scheduler" >/dev/null 2>&1
                elif grep -q "deadline" "$disk/queue/scheduler"; then
                    echo "deadline" | sudo tee "$disk/queue/scheduler" >/dev/null 2>&1
                fi
                log "I/O scheduler optimized for $disk_name"
            fi
        fi
    done
    
    # Increase file descriptor limit
    ulimit -n 65536 2>/dev/null || warning "Could not increase file descriptor limit"
    
    # Set process priority for gaming
    log "System optimization complete"
}

# Restore normal system settings
restore_system() {
    log "Restoring normal system settings..."
    
    # Restore CPU governor
    set_cpu_governor "$NORMAL_CPU_GOVERNOR"
    
    # Re-enable swap
    if command -v swapon >/dev/null 2>&1; then
        sudo swapon -a 2>/dev/null || warning "Could not re-enable swap"
        log "Swap re-enabled"
    fi
    
    log "System settings restored"
}

# Configure Hyprland for gaming
configure_hyprland_gaming() {
    log "Configuring Hyprland for gaming..."
    
    # Create gaming-specific Hyprland config
    cat > "$GAMING_CONFIG" << 'EOF'
# Gaming Mode Configuration
# Optimized settings for gaming performance

# Disable animations for better performance
animations {
    enabled = false
}

# Reduce decorations
decoration {
    drop_shadow = false
    blur {
        enabled = false
    }
}

# Optimize rendering
misc {
    vrr = 1
    vfr = false
    no_direct_scanout = false
    force_default_wallpaper = 2
}

# Gaming-specific window rules
windowrulev2 = immediate, class:^(steam_app_.*)$
windowrulev2 = immediate, class:^(lutris)$
windowrulev2 = immediate, class:^(minecraft.*)$
windowrulev2 = immediate, class:^(steam)$
windowrulev2 = immediate, title:^(.*Steam.*)$

# Full-screen gaming optimizations
windowrulev2 = fullscreen, class:^(steam_app_.*)$
windowrulev2 = noborder, class:^(steam_app_.*)$
windowrulev2 = noshadow, class:^(steam_app_.*)$

# Gaming workspace
workspace = 10, monitor:DP-1, default:true, persistent:true
EOF
    
    # Apply gaming config to Hyprland
    hyprctl keyword source "$GAMING_CONFIG"
    
    success "Hyprland configured for gaming"
}

# Restore normal Hyprland settings
restore_hyprland() {
    log "Restoring normal Hyprland settings..."
    
    # Re-enable animations and effects
    hyprctl keyword animations:enabled true
    hyprctl keyword decoration:drop_shadow true
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword misc:vfr true
    
    success "Hyprland settings restored"
}

# Launch game with optimizations
launch_game() {
    local game_command="$1"
    local game_name="${2:-Game}"
    
    if [ -z "$game_command" ]; then
        error "Game command required"
        return 1
    fi
    
    log "Launching $game_name with optimizations..."
    
    # Enable gaming mode if not already active
    if ! is_gaming_active; then
        enable_gaming_mode
    fi
    
    # Set process priority and launch
    notify-send "🎮 Gaming Mode" "Launching $game_name with optimizations" -t 3000 2>/dev/null || true
    
    # Launch with high priority and optimizations
    env PULSE_LATENCY_MSEC=30 \
        __GL_THREADED_OPTIMIZATIONS=1 \
        __GL_SHADER_DISK_CACHE=1 \
        DXVK_HUD=fps \
        $GAMING_PRIORITY $game_command &
    
    local game_pid=$!
    echo "GAME_PID=$game_pid" >> "$STATE_FILE"
    
    success "$game_name launched with PID: $game_pid"
    
    # Monitor game process
    monitor_game_process "$game_pid" "$game_name"
}

# Monitor game process and auto-disable gaming mode when finished
monitor_game_process() {
    local game_pid="$1"
    local game_name="$2"
    
    (
        while kill -0 "$game_pid" 2>/dev/null; do
            sleep 5
        done
        
        log "$game_name has exited, keeping gaming mode active"
        notify-send "🎮 Gaming Mode" "$game_name finished. Gaming mode still active." -t 3000 2>/dev/null || true
        
        # Remove game PID from state
        sed -i "/GAME_PID=/d" "$STATE_FILE"
    ) &
}

# Enable gaming mode
enable_gaming_mode() {
    if is_gaming_active; then
        warning "Gaming mode already active"
        return 0
    fi
    
    log "Enabling gaming mode..."
    
    # Store current state
    echo "ACTIVE=true" > "$STATE_FILE"
    echo "TIMESTAMP=$(date)" >> "$STATE_FILE"
    echo "ORIGINAL_GOVERNOR=$(get_cpu_governor)" >> "$STATE_FILE"
    
    # Apply optimizations
    optimize_system
    configure_hyprland_gaming
    
    # Kill unnecessary processes
    killall -STOP evolution-data-server 2>/dev/null || true
    killall -STOP goa-daemon 2>/dev/null || true
    killall -STOP tracker-miner-fs 2>/dev/null || true
    
    # Show gaming mode notification
    notify-send "🎮 Gaming Mode Enabled" "System optimized for gaming performance" \
        -i applications-games -t 5000 2>/dev/null || true
    
    success "Gaming mode enabled"
}

# Disable gaming mode
disable_gaming_mode() {
    if ! is_gaming_active; then
        warning "Gaming mode not active"
        return 0
    fi
    
    log "Disabling gaming mode..."
    
    # Stop any running games
    if grep -q "GAME_PID=" "$STATE_FILE"; then
        local game_pid=$(grep "GAME_PID=" "$STATE_FILE" | cut -d'=' -f2)
        if kill -0 "$game_pid" 2>/dev/null; then
            warning "Game still running (PID: $game_pid). Force disable? (y/N)"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                kill "$game_pid" 2>/dev/null || true
                log "Game process terminated"
            else
                warning "Gaming mode kept active due to running game"
                return 1
            fi
        fi
    fi
    
    # Restore system settings
    restore_system
    restore_hyprland
    
    # Resume stopped processes
    killall -CONT evolution-data-server 2>/dev/null || true
    killall -CONT goa-daemon 2>/dev/null || true
    killall -CONT tracker-miner-fs 2>/dev/null || true
    
    # Clear state
    rm -f "$STATE_FILE"
    
    # Show notification
    notify-send "🎮 Gaming Mode Disabled" "System restored to normal operation" \
        -i applications-games -t 3000 2>/dev/null || true
    
    success "Gaming mode disabled"
}

# Toggle gaming mode
toggle_gaming_mode() {
    if is_gaming_active; then
        disable_gaming_mode
    else
        enable_gaming_mode
    fi
}

# Show gaming mode status
show_status() {
    echo -e "${CYAN}=== Gaming Mode Status ===${NC}"
    
    if is_gaming_active; then
        echo -e "${GREEN}Status: ACTIVE${NC}"
        
        if [ -f "$STATE_FILE" ]; then
            local timestamp=$(grep "TIMESTAMP=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2-)
            local original_gov=$(grep "ORIGINAL_GOVERNOR=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2)
            local game_pid=$(grep "GAME_PID=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2)
            
            echo -e "${GREEN}Enabled since:${NC} $timestamp"
            echo -e "${GREEN}Original CPU governor:${NC} $original_gov"
            
            if [ -n "$game_pid" ] && kill -0 "$game_pid" 2>/dev/null; then
                echo -e "${GREEN}Running game PID:${NC} $game_pid"
            fi
        fi
    else
        echo -e "${YELLOW}Status: INACTIVE${NC}"
    fi
    
    echo -e "${GREEN}Current CPU governor:${NC} $(get_cpu_governor)"
    echo -e "${GREEN}Current CPU frequency:${NC} $(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')MHz"
    
    # Show GPU info if NVIDIA
    if command -v nvidia-smi >/dev/null 2>&1; then
        local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        local gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        echo -e "${GREEN}GPU Temperature:${NC} ${gpu_temp}°C"
        echo -e "${GREEN}GPU Utilization:${NC} ${gpu_util}%"
    fi
}

# Steam integration
launch_steam_game() {
    local game_id="$1"
    local game_name="${2:-Steam Game}"
    
    if [ -z "$game_id" ]; then
        error "Steam game ID required"
        return 1
    fi
    
    local steam_command="steam steam://rungameid/$game_id"
    launch_game "$steam_command" "$game_name"
}

# Create gaming profile
create_profile() {
    local profile_name="$1"
    local cpu_governor="${2:-performance}"
    local disable_compositing="${3:-false}"
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    cat > "$profile_file" << EOF
# Gaming Profile: $profile_name
# Created: $(date)

CPU_GOVERNOR="$cpu_governor"
DISABLE_COMPOSITING="$disable_compositing"
PRIORITY_BOOST="true"
KILL_BACKGROUND_APPS="true"
OPTIMIZE_IO="true"
DISABLE_SWAP="true"

# Custom game-specific settings
PULSE_LATENCY_MSEC=30
__GL_THREADED_OPTIMIZATIONS=1
__GL_SHADER_DISK_CACHE=1
DXVK_HUD=fps
MANGOHUD=1
EOF
    
    success "Gaming profile '$profile_name' created"
}

# Load gaming profile
load_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    if [ ! -f "$profile_file" ]; then
        error "Profile '$profile_name' not found"
        return 1
    fi
    
    # Source the profile
    source "$profile_file"
    
    # Apply profile settings
    GAMING_CPU_GOVERNOR="${CPU_GOVERNOR:-performance}"
    COMPOSITING_DISABLED="${DISABLE_COMPOSITING:-false}"
    
    log "Gaming profile '$profile_name' loaded"
    
    # Enable gaming mode with profile settings
    enable_gaming_mode
}

# List gaming profiles
list_profiles() {
    echo -e "${CYAN}=== Gaming Profiles ===${NC}"
    
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR")" ]; then
        echo "No profiles found"
        return
    fi
    
    for profile in "$PROFILES_DIR"/*.conf; do
        local name=$(basename "$profile" .conf)
        local created=$(stat -c %y "$profile" | cut -d' ' -f1)
        echo -e "${GREEN}$name${NC} (created: $created)"
        
        # Show brief profile info
        local cpu_gov=$(grep "CPU_GOVERNOR=" "$profile" | cut -d'"' -f2)
        local compositing=$(grep "DISABLE_COMPOSITING=" "$profile" | cut -d'"' -f2)
        echo "  CPU Governor: $cpu_gov"
        echo "  Disable Compositing: $compositing"
        echo
    done
}

# Show help
show_help() {
    echo "Usage: gaming-mode [command] [options]"
    echo
    echo "Gaming Mode Commands:"
    echo "  enable                   Enable gaming mode optimizations"
    echo "  disable                  Disable gaming mode and restore normal settings"
    echo "  toggle                   Toggle gaming mode on/off"
    echo "  status                   Show current gaming mode status"
    echo
    echo "Game Launch Commands:"
    echo "  launch [command] [name]  Launch game with optimizations"
    echo "  steam [game_id] [name]   Launch Steam game by ID"
    echo
    echo "Profile Commands:"
    echo "  create [name] [governor] Create gaming profile"
    echo "  load [name]              Load gaming profile"
    echo "  list-profiles            List available profiles"
    echo
    echo "Examples:"
    echo "  gaming-mode enable"
    echo "  gaming-mode launch 'lutris -d wow' 'World of Warcraft'"
    echo "  gaming-mode steam 570 'Dota 2'"
    echo "  gaming-mode create fps-games performance true"
    echo
    echo "Key Features:"
    echo "  • CPU governor optimization"
    echo "  • Background process management"
    echo "  • Hyprland gaming optimizations"
    echo "  • Automatic game process monitoring"
    echo "  • Profile-based configurations"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    enable) enable_gaming_mode ;;
    disable) disable_gaming_mode ;;
    toggle) toggle_gaming_mode ;;
    status) show_status ;;
    launch) launch_game "$2" "$3" ;;
    steam) launch_steam_game "$2" "$3" ;;
    create) create_profile "$2" "$3" "$4" ;;
    load) load_profile "$2" ;;
    list-profiles) list_profiles ;;
    help|*) show_help ;;
esac
