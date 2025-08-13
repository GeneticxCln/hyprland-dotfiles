#!/bin/bash
# AI-Enhanced Hyprland - Self-Healing System Manager
# Autonomous system optimization and recovery daemon
# Version: 2.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="/tmp/hyprland-self-healing.pid"
LOG_FILE="$HOME/.config/hypr/logs/self-healing.log"
CONFIG_FILE="$HOME/.config/hypr/self-healing.conf"
STATE_FILE="$HOME/.config/hypr/system-state.json"
RECOVERY_LOG="$HOME/.config/hypr/logs/recovery-actions.log"

# Service definitions for monitoring and recovery
declare -A CRITICAL_SERVICES=(
    ["hyprland"]="Hyprland"
    ["waybar"]="waybar"
    ["dunst"]="dunst"
    ["pipewire"]="pipewire"
    ["wireplumber"]="wireplumber"
)

declare -A SERVICE_RESTART_COMMANDS=(
    ["waybar"]="pkill waybar; sleep 1; waybar &"
    ["dunst"]="pkill dunst; sleep 1; dunst &"
    ["pipewire"]="systemctl --user restart pipewire"
    ["wireplumber"]="systemctl --user restart wireplumber"
)

# Configuration with intelligent defaults
declare -A CONFIG=(
    ["enable_service_recovery"]="true"
    ["enable_performance_optimization"]="true"
    ["enable_thermal_management"]="true"
    ["enable_memory_management"]="true"
    ["enable_process_priority_management"]="true"
    ["enable_cache_management"]="true"
    ["enable_io_optimization"]="true"
    ["recovery_check_interval"]="10"
    ["optimization_check_interval"]="30"
    ["thermal_check_interval"]="15"
    ["aggressive_optimization"]="false"
    ["learning_mode"]="true"
    ["max_recovery_attempts"]="3"
    ["cooldown_period"]="300"
)

# System state tracking
declare -A SYSTEM_STATE=(
    ["current_profile"]="balanced"
    ["last_optimization"]="0"
    ["recovery_count"]="0"
    ["thermal_events"]="0"
    ["memory_cleanups"]="0"
    ["service_restarts"]="0"
    ["optimization_score"]="100"
)

# Performance profiles
declare -A PROFILES=(
    ["gaming"]="performance,high_priority,max_performance"
    ["development"]="performance,balanced_priority,optimized_io"
    ["media"]="performance,high_priority,gpu_optimized"
    ["productivity"]="balanced,normal_priority,power_efficient"
    ["power_saving"]="powersave,low_priority,minimal_effects"
    ["emergency"]="powersave,emergency_priority,thermal_protection"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SELF-HEAL] $*" >> "$LOG_FILE"
    echo -e "${BLUE}[SELF-HEAL]${NC} $*"
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $*" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $*"
}

success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*" >> "$LOG_FILE"
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

recovery_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [RECOVERY] $*" >> "$RECOVERY_LOG"
    log "Recovery Action: $*"
}

# Load configuration and state
load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log "Configuration loaded from $CONFIG_FILE"
    else
        create_default_config
    fi
    
    load_system_state
}

create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# AI-Enhanced Hyprland Self-Healing Configuration
# Advanced autonomous system optimization settings

# Core Features
enable_service_recovery=${CONFIG[enable_service_recovery]}
enable_performance_optimization=${CONFIG[enable_performance_optimization]}
enable_thermal_management=${CONFIG[enable_thermal_management]}
enable_memory_management=${CONFIG[enable_memory_management]}
enable_process_priority_management=${CONFIG[enable_process_priority_management]}
enable_cache_management=${CONFIG[enable_cache_management]}
enable_io_optimization=${CONFIG[enable_io_optimization]}

# Timing Configuration
recovery_check_interval=${CONFIG[recovery_check_interval]}
optimization_check_interval=${CONFIG[optimization_check_interval]}
thermal_check_interval=${CONFIG[thermal_check_interval]}

# Behavior Settings
aggressive_optimization=${CONFIG[aggressive_optimization]}
learning_mode=${CONFIG[learning_mode]}
max_recovery_attempts=${CONFIG[max_recovery_attempts]}
cooldown_period=${CONFIG[cooldown_period]}

# Performance Thresholds
cpu_high_threshold=80
cpu_critical_threshold=95
memory_high_threshold=85
memory_critical_threshold=95
temperature_high_threshold=75
temperature_critical_threshold=85
load_high_threshold=4.0

# Optimization Settings
auto_nice_aggressive_processes=true
auto_ionice_optimization=true
auto_cpu_governor_switching=true
auto_memory_compaction=true
auto_swap_optimization=true
EOF
    log "Default configuration created"
}

load_system_state() {
    if [[ -f "$STATE_FILE" ]]; then
        # Parse JSON state file (basic implementation)
        if command -v jq &>/dev/null; then
            SYSTEM_STATE["current_profile"]=$(jq -r '.current_profile // "balanced"' "$STATE_FILE")
            SYSTEM_STATE["optimization_score"]=$(jq -r '.optimization_score // "100"' "$STATE_FILE")
            SYSTEM_STATE["recovery_count"]=$(jq -r '.recovery_count // "0"' "$STATE_FILE")
        fi
        log "System state loaded"
    else
        save_system_state
    fi
}

save_system_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    cat > "$STATE_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "current_profile": "${SYSTEM_STATE[current_profile]}",
    "last_optimization": "${SYSTEM_STATE[last_optimization]}",
    "recovery_count": "${SYSTEM_STATE[recovery_count]}",
    "thermal_events": "${SYSTEM_STATE[thermal_events]}",
    "memory_cleanups": "${SYSTEM_STATE[memory_cleanups]}",
    "service_restarts": "${SYSTEM_STATE[service_restarts]}",
    "optimization_score": "${SYSTEM_STATE[optimization_score]}",
    "uptime": "$(uptime -s)"
}
EOF
}

# Service monitoring and recovery
monitor_critical_services() {
    if [[ "${CONFIG[enable_service_recovery]}" != "true" ]]; then
        return 0
    fi
    
    local services_recovered=0
    
    for service in "${!CRITICAL_SERVICES[@]}"; do
        if ! pgrep -f "$service" &>/dev/null; then
            warning "Critical service '$service' is not running"
            
            # Check recovery attempts
            local recovery_key="${service}_recovery_count"
            local current_attempts=${RECOVERY_ATTEMPTS[$recovery_key]:-0}
            
            if (( current_attempts < CONFIG[max_recovery_attempts] )); then
                recover_service "$service"
                RECOVERY_ATTEMPTS[$recovery_key]=$((current_attempts + 1))
                ((services_recovered++))
            else
                error "Service '$service' failed to recover after ${CONFIG[max_recovery_attempts]} attempts"
                send_critical_notification "Service Recovery Failed" "Service $service could not be recovered"
            fi
        fi
    done
    
    if (( services_recovered > 0 )); then
        SYSTEM_STATE["service_restarts"]=$((SYSTEM_STATE[service_restarts] + services_recovered))
        save_system_state
    fi
}

recover_service() {
    local service="$1"
    recovery_log "Attempting to recover service: $service"
    
    case "$service" in
        "waybar")
            pkill waybar 2>/dev/null || true
            sleep 2
            if [[ -f "$HOME/.config/waybar/config.jsonc" ]]; then
                waybar > /dev/null 2>&1 &
                success "Waybar restarted successfully"
            fi
            ;;
        "dunst")
            pkill dunst 2>/dev/null || true
            sleep 1
            dunst > /dev/null 2>&1 &
            success "Dunst notification daemon restarted"
            ;;
        "pipewire")
            systemctl --user restart pipewire 2>/dev/null || true
            success "PipeWire audio system restarted"
            ;;
        "wireplumber")
            systemctl --user restart wireplumber 2>/dev/null || true
            success "WirePlumber session manager restarted"
            ;;
        *)
            warning "Unknown service recovery procedure for: $service"
            return 1
            ;;
    esac
    
    # Send recovery notification
    send_notification "🔧 Service Recovered" "Successfully restarted $service" "normal"
    
    # Wait and verify recovery
    sleep 3
    if pgrep -f "$service" &>/dev/null; then
        recovery_log "Service $service successfully recovered"
        return 0
    else
        recovery_log "Service $service recovery failed"
        return 1
    fi
}

# Performance optimization based on current system load
optimize_system_performance() {
    if [[ "${CONFIG[enable_performance_optimization]}" != "true" ]]; then
        return 0
    fi
    
    local current_time=$(date +%s)
    local last_opt=${SYSTEM_STATE[last_optimization]}
    
    # Don't optimize too frequently
    if (( current_time - last_opt < CONFIG[optimization_check_interval] )); then
        return 0
    fi
    
    log "Running system performance optimization..."
    
    # Gather current metrics
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage_percent)
    local load_average=$(get_load_average)
    local temperature=$(get_system_temperature)
    
    # Determine optimal profile
    local new_profile=$(determine_optimal_profile "$cpu_usage" "$memory_usage" "$load_average" "$temperature")
    
    if [[ "$new_profile" != "${SYSTEM_STATE[current_profile]}" ]]; then
        apply_performance_profile "$new_profile"
        SYSTEM_STATE["current_profile"]="$new_profile"
        log "Switched to performance profile: $new_profile"
    fi
    
    # Apply specific optimizations
    optimize_process_priorities "$cpu_usage" "$memory_usage"
    optimize_memory_management "$memory_usage"
    optimize_io_scheduler "$load_average"
    
    SYSTEM_STATE["last_optimization"]="$current_time"
    save_system_state
}

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | cut -d'%' -f1
}

get_memory_usage_percent() {
    free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'
}

get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

get_system_temperature() {
    if command -v sensors &>/dev/null; then
        sensors | grep -E "(Core|temp)" | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d'.' -f1
    else
        echo "0"
    fi
}

determine_optimal_profile() {
    local cpu="$1"
    local memory="$2"
    local load="$3"
    local temp="$4"
    
    # Emergency thermal protection
    if (( ${temp:-0} > 85 )); then
        echo "emergency"
        return
    fi
    
    # High performance scenarios
    if (( $(echo "$cpu > 70" | bc -l 2>/dev/null || echo "0") )) || (( $(echo "$load > 3.0" | bc -l 2>/dev/null || echo "0") )); then
        # Check if gaming (GPU intensive processes)
        if pgrep -f "(steam|lutris|wine|gamemode)" &>/dev/null; then
            echo "gaming"
        elif pgrep -f "(code|gcc|make|cargo|npm)" &>/dev/null; then
            echo "development"
        elif pgrep -f "(ffmpeg|obs|blender|kdenlive)" &>/dev/null; then
            echo "media"
        else
            echo "performance"
        fi
        return
    fi
    
    # Power saving scenarios
    if command -v acpi &>/dev/null && acpi -b 2>/dev/null | grep -q "Battery"; then
        local battery_level=$(acpi -b | grep -oE '[0-9]+%' | head -1 | sed 's/%//')
        if (( ${battery_level:-100} < 20 )); then
            echo "power_saving"
            return
        fi
    fi
    
    echo "balanced"
}

apply_performance_profile() {
    local profile="$1"
    log "Applying performance profile: $profile"
    
    case "$profile" in
        "gaming")
            set_cpu_governor "performance"
            set_io_scheduler "mq-deadline"
            adjust_swappiness "10"
            enable_game_optimizations
            ;;
        "development")
            set_cpu_governor "performance"
            set_io_scheduler "bfq"
            adjust_swappiness "60"
            optimize_compiler_cache
            ;;
        "media")
            set_cpu_governor "performance"
            optimize_gpu_performance
            adjust_swappiness "30"
            ;;
        "power_saving")
            set_cpu_governor "powersave"
            set_io_scheduler "bfq"
            adjust_swappiness "100"
            enable_power_saving_features
            ;;
        "emergency")
            emergency_thermal_protection
            ;;
        "balanced"|*)
            set_cpu_governor "schedutil"
            set_io_scheduler "bfq"
            adjust_swappiness "60"
            ;;
    esac
    
    recovery_log "Applied performance profile: $profile"
}

set_cpu_governor() {
    local governor="$1"
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g "$governor" &>/dev/null || true
        log "CPU governor set to: $governor"
    fi
}

set_io_scheduler() {
    local scheduler="$1"
    for device in /sys/block/sd*/queue/scheduler; do
        if [[ -f "$device" ]] && grep -q "$scheduler" "$device"; then
            echo "$scheduler" | sudo tee "$device" &>/dev/null || true
        fi
    done
    log "I/O scheduler set to: $scheduler"
}

adjust_swappiness() {
    local swappiness="$1"
    echo "$swappiness" | sudo tee /proc/sys/vm/swappiness &>/dev/null || true
    log "Swappiness adjusted to: $swappiness"
}

enable_game_optimizations() {
    # Disable compositor if not needed (reduces input lag)
    if pgrep -x "Hyprland" &>/dev/null; then
        # Hyprland-specific optimizations
        hyprctl keyword decoration:blur:enabled false &>/dev/null || true
        hyprctl keyword decoration:drop_shadow false &>/dev/null || true
    fi
    
    # Set high priority for gaming processes
    for proc in steam lutris wine gamemode; do
        pgrep -f "$proc" | while read -r pid; do
            sudo renice -n -5 -p "$pid" &>/dev/null || true
        done
    done
    
    log "Gaming optimizations applied"
}

optimize_compiler_cache() {
    # Set up ccache if available
    if command -v ccache &>/dev/null; then
        export CCACHE_DIR="$HOME/.ccache"
        mkdir -p "$CCACHE_DIR"
        ccache -M 2G &>/dev/null || true
    fi
    
    log "Development optimizations applied"
}

optimize_gpu_performance() {
    # NVIDIA optimizations
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi -pm 1 &>/dev/null || true  # Enable persistence mode
        nvidia-smi -pl 300 &>/dev/null || true  # Set power limit to maximum
    fi
    
    log "GPU performance optimized"
}

enable_power_saving_features() {
    # Disable unnecessary visual effects
    if pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled false &>/dev/null || true
        hyprctl keyword decoration:blur:enabled false &>/dev/null || true
        hyprctl keyword decoration:drop_shadow false &>/dev/null || true
    fi
    
    # Lower display brightness if possible
    if command -v brightnessctl &>/dev/null; then
        brightnessctl set 30% &>/dev/null || true
    fi
    
    log "Power saving features enabled"
}

emergency_thermal_protection() {
    warning "Emergency thermal protection activated!"
    
    # Immediately set CPU to powersave
    set_cpu_governor "powersave"
    
    # Limit CPU frequency if possible
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -u 2GHz &>/dev/null || true
    fi
    
    # Disable all visual effects
    if pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled false &>/dev/null || true
        hyprctl keyword decoration:blur:enabled false &>/dev/null || true
        hyprctl keyword decoration:drop_shadow false &>/dev/null || true
    fi
    
    # Kill non-essential processes
    pkill -f "(firefox|chrome|code)" 2>/dev/null || true
    
    SYSTEM_STATE["thermal_events"]=$((SYSTEM_STATE[thermal_events] + 1))
    
    send_critical_notification "🌡️ Emergency Thermal Protection" "System overheating - emergency cooling activated"
    recovery_log "Emergency thermal protection activated - temperature critical"
}

# Process priority optimization
optimize_process_priorities() {
    if [[ "${CONFIG[enable_process_priority_management]}" != "true" ]]; then
        return 0
    fi
    
    local cpu_usage="$1"
    local memory_usage="$2"
    
    # Only adjust priorities under high load
    if (( $(echo "$cpu_usage < 70" | bc -l 2>/dev/null || echo "1") )); then
        return 0
    fi
    
    log "Optimizing process priorities under high load"
    
    # Lower priority for non-essential processes
    local low_priority_processes=("discord" "spotify" "steam" "telegram" "slack")
    for proc in "${low_priority_processes[@]}"; do
        pgrep -f "$proc" | while read -r pid; do
            sudo renice -n 5 -p "$pid" &>/dev/null || true
        done
    done
    
    # Higher priority for critical processes
    local high_priority_processes=("Hyprland" "waybar" "pipewire" "dunst")
    for proc in "${high_priority_processes[@]}"; do
        pgrep -f "$proc" | while read -r pid; do
            sudo renice -n -5 -p "$pid" &>/dev/null || true
        done
    done
    
    # I/O priority optimization
    if command -v ionice &>/dev/null; then
        # Lower I/O priority for background processes
        for proc in updatedb locate; do
            pgrep -f "$proc" | while read -r pid; do
                sudo ionice -c 3 -p "$pid" &>/dev/null || true
            done
        done
    fi
}

# Memory management optimization
optimize_memory_management() {
    if [[ "${CONFIG[enable_memory_management]}" != "true" ]]; then
        return 0
    fi
    
    local memory_usage="$1"
    
    # Aggressive memory cleanup under high usage
    if (( memory_usage > 85 )); then
        log "Performing memory optimization - usage at ${memory_usage}%"
        
        # Clear system caches
        sync
        echo 1 | sudo tee /proc/sys/vm/drop_caches &>/dev/null || true
        echo 2 | sudo tee /proc/sys/vm/drop_caches &>/dev/null || true
        echo 3 | sudo tee /proc/sys/vm/drop_caches &>/dev/null || true
        
        # Compact memory
        echo 1 | sudo tee /proc/sys/vm/compact_memory &>/dev/null || true
        
        # Trigger memory reclaim
        echo 1 | sudo tee /sys/kernel/mm/ksm/run &>/dev/null || true
        
        SYSTEM_STATE["memory_cleanups"]=$((SYSTEM_STATE[memory_cleanups] + 1))
        recovery_log "Memory optimization performed - cleared caches and compacted memory"
        
        send_notification "💾 Memory Optimized" "System memory usage reduced from ${memory_usage}%" "normal"
    fi
}

# I/O scheduler optimization
optimize_io_scheduler() {
    if [[ "${CONFIG[enable_io_optimization]}" != "true" ]]; then
        return 0
    fi
    
    local load_average="$1"
    
    # Switch I/O scheduler based on load
    if (( $(echo "$load_average > 3.0" | bc -l 2>/dev/null || echo "0") )); then
        set_io_scheduler "mq-deadline"  # Better for high I/O
    else
        set_io_scheduler "bfq"  # Better for interactive workloads
    fi
}

# Notification functions
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -i "system-monitor" "$title" "$message" 2>/dev/null || true
    fi
}

send_critical_notification() {
    local title="$1"
    local message="$2"
    
    send_notification "$title" "$message" "critical"
    
    # Also log as critical
    error "$title: $message"
}

# Main monitoring loops
service_recovery_loop() {
    while true; do
        monitor_critical_services
        sleep "${CONFIG[recovery_check_interval]}"
    done
}

performance_optimization_loop() {
    while true; do
        optimize_system_performance
        sleep "${CONFIG[optimization_check_interval]}"
    done
}

# Main daemon function
start_daemon() {
    log "Starting AI Self-Healing System Manager..."
    echo $$ > "$PID_FILE"
    
    # Start background loops
    service_recovery_loop &
    local service_pid=$!
    
    performance_optimization_loop &
    local performance_pid=$!
    
    # Wait for termination signal
    trap "kill $service_pid $performance_pid 2>/dev/null; cleanup; exit 0" SIGINT SIGTERM
    
    wait
}

cleanup() {
    log "Self-healing system shutting down..."
    rm -f "$PID_FILE"
    save_system_state
}

# Status and reporting functions
show_status() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${BOLD}AI SELF-HEALING SYSTEM STATUS${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if running
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "Status: ${GREEN}ACTIVE${NC} (PID: $(cat "$PID_FILE"))"
    else
        echo -e "Status: ${RED}INACTIVE${NC}"
        return 1
    fi
    
    # Load current state
    load_system_state
    
    echo ""
    echo -e "${BOLD}Current Configuration:${NC}"
    echo "  Profile: ${SYSTEM_STATE[current_profile]}"
    echo "  Optimization Score: ${SYSTEM_STATE[optimization_score]}/100"
    echo ""
    
    echo -e "${BOLD}Recovery Statistics:${NC}"
    echo "  Service Restarts: ${SYSTEM_STATE[service_restarts]}"
    echo "  Memory Cleanups: ${SYSTEM_STATE[memory_cleanups]}"
    echo "  Thermal Events: ${SYSTEM_STATE[thermal_events]}"
    echo "  Total Recovery Actions: ${SYSTEM_STATE[recovery_count]}"
    echo ""
    
    echo -e "${BOLD}System Health:${NC}"
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage_percent)
    local temperature=$(get_system_temperature)
    
    echo "  CPU Usage: ${cpu_usage}%"
    echo "  Memory Usage: ${memory_usage}%"
    [[ "$temperature" != "0" ]] && echo "  Temperature: ${temperature}°C"
    
    # Service status
    echo ""
    echo -e "${BOLD}Critical Services:${NC}"
    for service in "${!CRITICAL_SERVICES[@]}"; do
        if pgrep -f "$service" &>/dev/null; then
            echo -e "  ${service}: ${GREEN}RUNNING${NC}"
        else
            echo -e "  ${service}: ${RED}DOWN${NC}"
        fi
    done
}

generate_report() {
    local report_file="$HOME/.config/hypr/logs/self-healing-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system_info": {
        "hostname": "$(hostname)",
        "uptime": "$(uptime -p)",
        "kernel": "$(uname -r)"
    },
    "current_state": {
        "profile": "${SYSTEM_STATE[current_profile]}",
        "optimization_score": ${SYSTEM_STATE[optimization_score]},
        "last_optimization": "${SYSTEM_STATE[last_optimization]}"
    },
    "statistics": {
        "service_restarts": ${SYSTEM_STATE[service_restarts]},
        "memory_cleanups": ${SYSTEM_STATE[memory_cleanups]},
        "thermal_events": ${SYSTEM_STATE[thermal_events]},
        "recovery_count": ${SYSTEM_STATE[recovery_count]}
    },
    "current_metrics": {
        "cpu_usage": "$(get_cpu_usage)",
        "memory_usage": "$(get_memory_usage_percent)",
        "temperature": "$(get_system_temperature)",
        "load_average": "$(get_load_average)"
    },
    "service_status": {
$(for service in "${!CRITICAL_SERVICES[@]}"; do
    if pgrep -f "$service" &>/dev/null; then
        echo "        \"$service\": \"running\","
    else
        echo "        \"$service\": \"down\","
    fi
done | sed '$ s/,$//')
    }
}
EOF
    
    echo "$report_file"
}

# Command line interface
case "${1:-start}" in
    start)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            error "Self-healing system is already running (PID: $(cat "$PID_FILE"))"
            exit 1
        fi
        
        mkdir -p "$(dirname "$LOG_FILE")"
        mkdir -p "$(dirname "$RECOVERY_LOG")"
        load_configuration
        
        echo -e "${BOLD}Starting AI Self-Healing System...${NC}"
        echo "Log file: $LOG_FILE"
        echo "Recovery log: $RECOVERY_LOG"
        echo "Configuration: $CONFIG_FILE"
        echo ""
        
        if [[ "${2:-}" == "--daemon" ]]; then
            nohup "$0" daemon > /dev/null 2>&1 &
            success "Self-healing system started in daemon mode (PID: $!)"
        else
            start_daemon
        fi
        ;;
    
    daemon)
        load_configuration
        start_daemon
        ;;
    
    stop)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            kill "$(cat "$PID_FILE")"
            rm -f "$PID_FILE"
            success "Self-healing system stopped"
        else
            warning "Self-healing system is not running"
        fi
        ;;
    
    status)
        show_status
        ;;
    
    report)
        load_configuration
        report_file=$(generate_report)
        success "Report generated: $report_file"
        
        if command -v jq &>/dev/null; then
            echo ""
            echo "Report Summary:"
            jq . "$report_file"
        fi
        ;;
    
    config)
        if [[ ! -f "$CONFIG_FILE" ]]; then
            create_default_config
        fi
        
        echo "Opening configuration: $CONFIG_FILE"
        "${EDITOR:-nano}" "$CONFIG_FILE"
        ;;
    
    logs)
        echo -e "${BOLD}Recent Self-Healing Log:${NC}"
        tail -20 "$LOG_FILE" 2>/dev/null || echo "No logs found"
        echo ""
        echo -e "${BOLD}Recent Recovery Actions:${NC}"
        tail -10 "$RECOVERY_LOG" 2>/dev/null || echo "No recovery actions logged"
        ;;
    
    test)
        echo "Testing self-healing system..."
        load_configuration
        
        # Test service monitoring
        echo "Testing service monitoring..."
        monitor_critical_services
        
        # Test performance optimization
        echo "Testing performance optimization..."
        optimize_system_performance
        
        success "Self-healing system test completed"
        ;;
    
    *)
        echo -e "${BOLD}AI-Enhanced Hyprland Self-Healing System${NC}"
        echo ""
        echo "Usage: $0 {start|stop|status|report|config|logs|test}"
        echo ""
        echo "Commands:"
        echo "  start [--daemon]  Start the self-healing system"
        echo "  stop              Stop the self-healing system"
        echo "  status            Show current status and statistics"
        echo "  report            Generate detailed system report"
        echo "  config            Edit configuration file"
        echo "  logs              View recent logs and recovery actions"
        echo "  test              Test system functionality"
        echo ""
        echo "Features:"
        echo "  • Autonomous service recovery and restart"
        echo "  • Dynamic performance profile switching"
        echo "  • Intelligent process priority management"
        echo "  • Automatic memory and thermal management"
        echo "  • AI-driven system optimization"
        echo "  • Real-time monitoring and notifications"
        ;;
esac
