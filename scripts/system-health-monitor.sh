#!/bin/bash
# AI-Enhanced Hyprland - System Health Monitor
# Real-time monitoring and optimization daemon
# Version: 1.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="/tmp/hyprland-health-monitor.pid"
LOG_FILE="$HOME/.config/hypr/logs/health-monitor.log"
CONFIG_FILE="$HOME/.config/hypr/health-monitor.conf"

# Default configuration
declare -A CONFIG=(
    ["cpu_threshold"]="80"
    ["memory_threshold"]="85"
    ["gpu_threshold"]="90"
    ["temperature_threshold"]="75"
    ["disk_threshold"]="90"
    ["check_interval"]="5"
    ["enable_notifications"]="true"
    ["enable_auto_optimization"]="true"
    ["enable_ai_learning"]="true"
    ["log_level"]="INFO"
)

# Performance metrics storage
declare -A METRICS=(
    ["cpu_usage"]="0"
    ["memory_usage"]="0"
    ["gpu_usage"]="0"
    ["temperature"]="0"
    ["disk_usage"]="0"
    ["load_average"]="0"
    ["uptime"]="0"
)

# AI learning data
declare -A AI_DATA=(
    ["workload_patterns"]=""
    ["optimization_results"]=""
    ["user_preferences"]=""
    ["performance_trends"]=""
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" >> "$LOG_FILE"
    if [[ "${CONFIG[log_level]}" == "DEBUG" ]]; then
        echo -e "${BLUE}[INFO]${NC} $*"
    fi
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

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log "Configuration loaded from $CONFIG_FILE"
    else
        create_default_config
    fi
}

# Create default configuration file
create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# AI-Enhanced Hyprland Health Monitor Configuration
# Modify these values to customize monitoring behavior

# Performance thresholds (percentage)
cpu_threshold=${CONFIG[cpu_threshold]}
memory_threshold=${CONFIG[memory_threshold]}
gpu_threshold=${CONFIG[gpu_threshold]}
temperature_threshold=${CONFIG[temperature_threshold]}
disk_threshold=${CONFIG[disk_threshold]}

# Monitoring settings
check_interval=${CONFIG[check_interval]}
enable_notifications=${CONFIG[enable_notifications]}
enable_auto_optimization=${CONFIG[enable_auto_optimization]}
enable_ai_learning=${CONFIG[enable_ai_learning]}
log_level=${CONFIG[log_level]}

# AI Learning settings
ai_learning_history_days=30
ai_optimization_aggressiveness=moderate  # conservative, moderate, aggressive
ai_user_pattern_tracking=true
EOF
    log "Default configuration created at $CONFIG_FILE"
}

# Collect system metrics
collect_metrics() {
    # CPU usage
    METRICS["cpu_usage"]=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | cut -d'%' -f1)
    
    # Memory usage
    local mem_info=$(free | grep Mem)
    local total_mem=$(echo $mem_info | awk '{print $2}')
    local used_mem=$(echo $mem_info | awk '{print $3}')
    METRICS["memory_usage"]=$(( (used_mem * 100) / total_mem ))
    
    # GPU usage (NVIDIA)
    if command -v nvidia-smi &>/dev/null; then
        METRICS["gpu_usage"]=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
    fi
    
    # Temperature (if available)
    if command -v sensors &>/dev/null; then
        METRICS["temperature"]=$(sensors | grep -E "(Core|temp)" | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d'.' -f1)
    fi
    
    # Disk usage
    METRICS["disk_usage"]=$(df "$HOME" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Load average
    METRICS["load_average"]=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # Uptime
    METRICS["uptime"]=$(uptime -p)
    
    log "Metrics collected: CPU=${METRICS[cpu_usage]}% MEM=${METRICS[memory_usage]}% GPU=${METRICS[gpu_usage]}% TEMP=${METRICS[temperature]}°C DISK=${METRICS[disk_usage]}%"
}

# Check thresholds and trigger alerts
check_thresholds() {
    local alerts_triggered=false
    
    # CPU threshold check
    if (( $(echo "${METRICS[cpu_usage]} > ${CONFIG[cpu_threshold]}" | bc -l) )); then
        warning "CPU usage high: ${METRICS[cpu_usage]}% (threshold: ${CONFIG[cpu_threshold]}%)"
        send_notification "🔥 High CPU Usage" "CPU usage is at ${METRICS[cpu_usage]}%" "critical"
        trigger_cpu_optimization
        alerts_triggered=true
    fi
    
    # Memory threshold check
    if (( METRICS[memory_usage] > CONFIG[memory_threshold] )); then
        warning "Memory usage high: ${METRICS[memory_usage]}% (threshold: ${CONFIG[memory_threshold]}%)"
        send_notification "💾 High Memory Usage" "Memory usage is at ${METRICS[memory_usage]}%" "critical"
        trigger_memory_optimization
        alerts_triggered=true
    fi
    
    # GPU threshold check
    if [[ -n "${METRICS[gpu_usage]}" ]] && (( METRICS[gpu_usage] > CONFIG[gpu_threshold] )); then
        warning "GPU usage high: ${METRICS[gpu_usage]}% (threshold: ${CONFIG[gpu_threshold]}%)"
        send_notification "🎮 High GPU Usage" "GPU usage is at ${METRICS[gpu_usage]}%" "normal"
        alerts_triggered=true
    fi
    
    # Temperature threshold check
    if [[ -n "${METRICS[temperature]}" ]] && (( METRICS[temperature] > CONFIG[temperature_threshold] )); then
        warning "Temperature high: ${METRICS[temperature]}°C (threshold: ${CONFIG[temperature_threshold]}°C)"
        send_notification "🌡️ High Temperature" "System temperature is at ${METRICS[temperature]}°C" "critical"
        trigger_thermal_optimization
        alerts_triggered=true
    fi
    
    # Disk threshold check
    if (( METRICS[disk_usage] > CONFIG[disk_threshold] )); then
        warning "Disk usage high: ${METRICS[disk_usage]}% (threshold: ${CONFIG[disk_threshold]}%)"
        send_notification "💽 Low Disk Space" "Disk usage is at ${METRICS[disk_usage]}%" "normal"
        alerts_triggered=true
    fi
    
    if [[ "$alerts_triggered" == "false" ]]; then
        log "All metrics within normal thresholds"
    fi
}

# Send desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    if [[ "${CONFIG[enable_notifications]}" == "true" ]] && command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -i "system-monitor" "$title" "$message"
        log "Notification sent: $title - $message"
    fi
}

# CPU optimization
trigger_cpu_optimization() {
    if [[ "${CONFIG[enable_auto_optimization]}" != "true" ]]; then
        return 0
    fi
    
    log "Triggering CPU optimization..."
    
    # Find and optimize high CPU processes
    local high_cpu_procs=$(ps aux --sort=-%cpu | head -6 | tail -5)
    echo "$high_cpu_procs" >> "$LOG_FILE"
    
    # Apply CPU governor optimization
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g performance 2>/dev/null || true
        log "CPU governor set to performance mode"
    fi
    
    # Reduce non-essential animations if in Hyprland
    if pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled false 2>/dev/null || true
        log "Temporarily disabled animations to reduce CPU load"
        
        # Re-enable animations after 30 seconds
        (sleep 30 && hyprctl keyword animations:enabled true 2>/dev/null) &
    fi
}

# Memory optimization
trigger_memory_optimization() {
    if [[ "${CONFIG[enable_auto_optimization]}" != "true" ]]; then
        return 0
    fi
    
    log "Triggering memory optimization..."
    
    # Clear system caches
    sudo sync
    echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    log "System caches cleared"
    
    # Find memory-hungry processes
    local high_mem_procs=$(ps aux --sort=-%mem | head -6 | tail -5)
    echo "$high_mem_procs" >> "$LOG_FILE"
}

# Thermal optimization
trigger_thermal_optimization() {
    if [[ "${CONFIG[enable_auto_optimization]}" != "true" ]]; then
        return 0
    fi
    
    log "Triggering thermal optimization..."
    
    # Reduce CPU frequency
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g powersave 2>/dev/null || true
        log "CPU governor set to powersave mode for thermal management"
    fi
    
    # Reduce GPU performance if NVIDIA
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi -pl 150 2>/dev/null || true  # Limit power to 150W
        log "NVIDIA GPU power limit applied"
    fi
    
    # Disable animations and effects
    if pgrep -x "Hyprland" &>/dev/null; then
        hyprctl keyword animations:enabled false 2>/dev/null || true
        hyprctl keyword decoration:blur:enabled false 2>/dev/null || true
        log "Disabled visual effects for thermal management"
    fi
}

# AI learning and pattern recognition
ai_learning_cycle() {
    if [[ "${CONFIG[enable_ai_learning]}" != "true" ]]; then
        return 0
    fi
    
    local timestamp=$(date +%s)
    local data_point="${timestamp},${METRICS[cpu_usage]},${METRICS[memory_usage]},${METRICS[gpu_usage]},${METRICS[temperature]}"
    
    # Store performance data
    echo "$data_point" >> "$HOME/.config/hypr/logs/ai-learning-data.csv"
    
    # Analyze patterns every hour
    if (( timestamp % 3600 == 0 )); then
        analyze_performance_patterns
    fi
    
    log "AI learning data point recorded"
}

# Analyze performance patterns
analyze_performance_patterns() {
    local data_file="$HOME/.config/hypr/logs/ai-learning-data.csv"
    
    if [[ ! -f "$data_file" ]]; then
        return 0
    fi
    
    log "Analyzing performance patterns..."
    
    # Basic pattern analysis (could be enhanced with Python/machine learning)
    local avg_cpu=$(awk -F',' '{sum+=$2; count++} END {print sum/count}' "$data_file")
    local avg_mem=$(awk -F',' '{sum+=$3; count++} END {print sum/count}' "$data_file")
    
    log "Performance analysis: Average CPU: ${avg_cpu}%, Average Memory: ${avg_mem}%"
    
    # Adjust thresholds based on patterns
    if (( $(echo "$avg_cpu < 50" | bc -l) )); then
        CONFIG["cpu_threshold"]="75"  # Lower threshold if system typically runs cool
    elif (( $(echo "$avg_cpu > 70" | bc -l) )); then
        CONFIG["cpu_threshold"]="85"  # Higher threshold for high-performance systems
    fi
}

# Generate health report
generate_health_report() {
    local report_file="$HOME/.config/hypr/logs/health-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system_info": {
        "hostname": "$(hostname)",
        "uptime": "${METRICS[uptime]}",
        "load_average": "${METRICS[load_average]}"
    },
    "performance_metrics": {
        "cpu_usage": "${METRICS[cpu_usage]}",
        "memory_usage": "${METRICS[memory_usage]}",
        "gpu_usage": "${METRICS[gpu_usage]}",
        "temperature": "${METRICS[temperature]}",
        "disk_usage": "${METRICS[disk_usage]}"
    },
    "thresholds": {
        "cpu_threshold": "${CONFIG[cpu_threshold]}",
        "memory_threshold": "${CONFIG[memory_threshold]}",
        "gpu_threshold": "${CONFIG[gpu_threshold]}",
        "temperature_threshold": "${CONFIG[temperature_threshold]}",
        "disk_threshold": "${CONFIG[disk_threshold]}"
    },
    "health_status": "$(get_health_status)",
    "recommendations": $(get_recommendations_json)
}
EOF
    
    log "Health report generated: $report_file"
    echo "$report_file"
}

# Get overall health status
get_health_status() {
    local critical_issues=0
    local warnings=0
    
    (( METRICS[cpu_usage] > CONFIG[cpu_threshold] )) && ((critical_issues++))
    (( METRICS[memory_usage] > CONFIG[memory_threshold] )) && ((critical_issues++))
    [[ -n "${METRICS[temperature]}" ]] && (( METRICS[temperature] > CONFIG[temperature_threshold] )) && ((critical_issues++))
    
    (( METRICS[disk_usage] > CONFIG[disk_threshold] )) && ((warnings++))
    [[ -n "${METRICS[gpu_usage]}" ]] && (( METRICS[gpu_usage] > CONFIG[gpu_threshold] )) && ((warnings++))
    
    if (( critical_issues > 0 )); then
        echo "CRITICAL"
    elif (( warnings > 0 )); then
        echo "WARNING"
    else
        echo "HEALTHY"
    fi
}

# Get recommendations in JSON format
get_recommendations_json() {
    local recommendations="[]"
    
    if (( METRICS[cpu_usage] > CONFIG[cpu_threshold] )); then
        recommendations=$(echo "$recommendations" | jq '. += ["Consider closing resource-intensive applications"]')
    fi
    
    if (( METRICS[memory_usage] > CONFIG[memory_threshold] )); then
        recommendations=$(echo "$recommendations" | jq '. += ["Clear system caches or close memory-heavy applications"]')
    fi
    
    if (( METRICS[disk_usage] > CONFIG[disk_threshold] )); then
        recommendations=$(echo "$recommendations" | jq '. += ["Clean up disk space or move files to external storage"]')
    fi
    
    echo "$recommendations"
}

# Main monitoring loop
monitoring_loop() {
    log "Health monitoring started (PID: $$)"
    echo $$ > "$PID_FILE"
    
    while true; do
        collect_metrics
        check_thresholds
        ai_learning_cycle
        
        sleep "${CONFIG[check_interval]}"
    done
}

# Signal handlers
cleanup() {
    log "Health monitor shutting down..."
    rm -f "$PID_FILE"
    exit 0
}

# Handle signals
trap cleanup SIGINT SIGTERM

# Command-line interface
case "${1:-start}" in
    start)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            error "Health monitor is already running (PID: $(cat "$PID_FILE"))"
            exit 1
        fi
        
        mkdir -p "$(dirname "$LOG_FILE")"
        load_config
        
        echo "Starting AI-Enhanced Hyprland Health Monitor..."
        echo "Monitoring interval: ${CONFIG[check_interval]} seconds"
        echo "Log file: $LOG_FILE"
        echo "Configuration: $CONFIG_FILE"
        
        if [[ "${2:-}" == "--daemon" ]]; then
            nohup "$0" monitor > /dev/null 2>&1 &
            success "Health monitor started in daemon mode (PID: $!)"
        else
            monitoring_loop
        fi
        ;;
    
    monitor)
        load_config
        monitoring_loop
        ;;
    
    stop)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            kill "$(cat "$PID_FILE")"
            rm -f "$PID_FILE"
            success "Health monitor stopped"
        else
            warning "Health monitor is not running"
        fi
        ;;
    
    status)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo -e "${GREEN}Health monitor is running${NC} (PID: $(cat "$PID_FILE"))"
            
            # Show current metrics
            collect_metrics
            echo ""
            echo "Current System Metrics:"
            echo "  CPU Usage: ${METRICS[cpu_usage]}%"
            echo "  Memory Usage: ${METRICS[memory_usage]}%"
            [[ -n "${METRICS[gpu_usage]}" ]] && echo "  GPU Usage: ${METRICS[gpu_usage]}%"
            [[ -n "${METRICS[temperature]}" ]] && echo "  Temperature: ${METRICS[temperature]}°C"
            echo "  Disk Usage: ${METRICS[disk_usage]}%"
            echo "  Load Average: ${METRICS[load_average]}"
            echo ""
            echo "Health Status: $(get_health_status)"
        else
            echo -e "${RED}Health monitor is not running${NC}"
            exit 1
        fi
        ;;
    
    report)
        load_config
        collect_metrics
        report_file=$(generate_health_report)
        success "Health report generated: $report_file"
        
        if command -v jq &>/dev/null; then
            echo ""
            echo "Health Report Summary:"
            jq . "$report_file"
        fi
        ;;
    
    config)
        if [[ ! -f "$CONFIG_FILE" ]]; then
            create_default_config
        fi
        
        echo "Opening configuration file: $CONFIG_FILE"
        "${EDITOR:-nano}" "$CONFIG_FILE"
        ;;
    
    *)
        echo "AI-Enhanced Hyprland Health Monitor"
        echo ""
        echo "Usage: $0 {start|stop|status|report|config}"
        echo ""
        echo "Commands:"
        echo "  start [--daemon]  Start health monitoring"
        echo "  stop              Stop health monitoring"
        echo "  status            Show current status and metrics"
        echo "  report            Generate detailed health report"
        echo "  config            Edit configuration file"
        echo ""
        echo "Examples:"
        echo "  $0 start --daemon    # Start as background daemon"
        echo "  $0 status           # Check current system health"
        echo "  $0 report           # Generate health report"
        ;;
esac
