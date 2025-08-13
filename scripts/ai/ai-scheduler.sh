#!/bin/bash

# AI System Scheduler
# Automated background AI operations and monitoring

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hypr/ai-enhancements"
SCRIPTS_DIR="$HOME/.config/hypr/scripts/ai"
LOG_FILE="$CONFIG_DIR/scheduler.log"

log() { 
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "${BLUE}[AI-SCHED]${NC} $msg"
    echo "$msg" >> "$LOG_FILE"
}
success() { 
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "${GREEN}[SUCCESS]${NC} $msg"
    echo "SUCCESS: $msg" >> "$LOG_FILE"
}
warning() { 
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "${YELLOW}[WARNING]${NC} $msg"
    echo "WARNING: $msg" >> "$LOG_FILE"
}
error() { 
    local msg="[$(date '+%H:%M:%S')] $1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "ERROR: $msg" >> "$LOG_FILE"
}

# Setup
setup_scheduler() {
    log "Setting up AI scheduler..."
    mkdir -p "$CONFIG_DIR"
    
    # Create systemd user service
    local service_file="$HOME/.config/systemd/user/ai-scheduler.service"
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=AI System Scheduler
After=graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPTS_DIR/ai-scheduler.sh daemon
Restart=always
RestartSec=30
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF
    
    # Create systemd timer for periodic tasks
    local timer_file="$HOME/.config/systemd/user/ai-scheduler.timer"
    cat > "$timer_file" << EOF
[Unit]
Description=AI System Scheduler Timer
Requires=ai-scheduler.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable and start services
    systemctl --user daemon-reload
    systemctl --user enable ai-scheduler.timer
    systemctl --user start ai-scheduler.timer
    
    success "AI scheduler service installed and started"
}

# Daemon mode - continuous monitoring
run_daemon() {
    log "Starting AI scheduler daemon..."
    
    local last_data_collection=$(date +%s)
    local last_optimization=0
    local last_cleanup=0
    local last_notification=0
    
    while true; do
        local current_time=$(date +%s)
        local hour=$(date +%H)
        
        # Data collection every 5 minutes
        if [ $((current_time - last_data_collection)) -gt 300 ]; then
            collect_data_background
            last_data_collection=$current_time
        fi
        
        # Performance optimization every 30 minutes
        if [ $((current_time - last_optimization)) -gt 1800 ]; then
            optimize_performance_background
            last_optimization=$current_time
        fi
        
        # System cleanup every 2 hours
        if [ $((current_time - last_cleanup)) -gt 7200 ]; then
            cleanup_system_background
            last_cleanup=$current_time
        fi
        
        # Smart notifications every 15 minutes
        if [ $((current_time - last_notification)) -gt 900 ]; then
            send_smart_notifications
            last_notification=$current_time
        fi
        
        # Theme switching at specific times
        if [ "$hour" = "06" ] || [ "$hour" = "12" ] || [ "$hour" = "18" ] || [ "$hour" = "21" ]; then
            local last_theme_switch_file="$CONFIG_DIR/last_theme_switch"
            local current_day=$(date +%j)  # Day of year
            
            if [ ! -f "$last_theme_switch_file" ] || [ "$(cat "$last_theme_switch_file" 2>/dev/null)" != "${current_day}_${hour}" ]; then
                switch_theme_background
                echo "${current_day}_${hour}" > "$last_theme_switch_file"
            fi
        fi
        
        sleep 60  # Check every minute
    done
}

# Background data collection
collect_data_background() {
    log "Running background data collection..."
    
    if command -v python3 >/dev/null 2>&1 && [ -f "$SCRIPTS_DIR/learning-system.py" ]; then
        python3 "$SCRIPTS_DIR/learning-system.py" collect 2>/dev/null || warning "Data collection failed"
    else
        warning "Learning system not available"
    fi
}

# Background performance optimization
optimize_performance_background() {
    log "Running background performance optimization..."
    
    # Check if user is actively using the system
    local idle_time=0
    if command -v xprintidle >/dev/null 2>&1; then
        idle_time=$(($(xprintidle) / 1000))  # Convert to seconds
    fi
    
    # Only optimize if user is not idle (less than 5 minutes idle)
    if [ "$idle_time" -lt 300 ]; then
        if [ -f "$SCRIPTS_DIR/ai-enhancements.sh" ]; then
            "$SCRIPTS_DIR/ai-enhancements.sh" optimize >/dev/null 2>&1 || warning "Optimization failed"
        fi
    else
        log "User idle for ${idle_time}s - skipping optimization"
    fi
}

# Background system cleanup
cleanup_system_background() {
    log "Running background system cleanup..."
    
    # Check system load
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^ *//')
    local load_int=$(echo "$load_avg" | cut -d. -f1)
    
    # Only run cleanup if system load is low
    if [ "${load_int:-0}" -lt 2 ]; then
        if [ -f "$SCRIPTS_DIR/ai-enhancements.sh" ]; then
            "$SCRIPTS_DIR/ai-enhancements.sh" cleanup >/dev/null 2>&1 || warning "Cleanup failed"
        fi
    else
        log "High system load ($load_avg) - skipping cleanup"
    fi
}

# Background theme switching
switch_theme_background() {
    log "Running background theme switching..."
    
    if [ -f "$SCRIPTS_DIR/ai-enhancements.sh" ]; then
        "$SCRIPTS_DIR/ai-enhancements.sh" theme >/dev/null 2>&1 || warning "Theme switching failed"
    fi
}

# Smart notifications
send_smart_notifications() {
    local notifications_sent=0
    
    # Check for system issues
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    local cpu_temp=""
    
    # Try to get CPU temperature
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        cpu_temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    fi
    
    # High memory usage warning
    if [ "$memory_usage" -gt 85 ]; then
        notify-send "🔥 High Memory Usage" "Memory usage at ${memory_usage}%. Consider closing applications." -u normal 2>/dev/null || true
        ((notifications_sent++))
    fi
    
    # High disk usage warning
    if [ "$disk_usage" -gt 90 ]; then
        notify-send "💾 Critical Disk Space" "Disk usage at ${disk_usage}%. Immediate cleanup needed." -u critical 2>/dev/null || true
        ((notifications_sent++))
    fi
    
    # High CPU temperature warning
    if [ -n "$cpu_temp" ] && [ "$cpu_temp" -gt 75 ]; then
        notify-send "🌡️ High CPU Temperature" "CPU temperature at ${cpu_temp}°C. Check cooling." -u normal 2>/dev/null || true
        ((notifications_sent++))
    fi
    
    # Battery notifications for laptops
    if [ -d "/sys/class/power_supply/BAT"* ] 2>/dev/null; then
        local battery_level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "100")
        local ac_connected=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1 || echo "1")
        
        if [ "$ac_connected" = "0" ] && [ "$battery_level" -lt 15 ]; then
            notify-send "🔋 Critical Battery" "Battery at ${battery_level}%. Connect charger immediately!" -u critical 2>/dev/null || true
            ((notifications_sent++))
        fi
    fi
    
    # AI recommendations notification (once per hour)
    local hour=$(date +%H)
    local last_recommendation_file="$CONFIG_DIR/last_recommendation_hour"
    
    if [ ! -f "$last_recommendation_file" ] || [ "$(cat "$last_recommendation_file" 2>/dev/null)" != "$hour" ]; then
        if command -v python3 >/dev/null 2>&1 && [ -f "$SCRIPTS_DIR/learning-system.py" ]; then
            # Generate recommendations and check if there are important ones
            python3 "$SCRIPTS_DIR/learning-system.py" recommend >/dev/null 2>&1
            
            local recommendations_file="$CONFIG_DIR/recommendations.json"
            if [ -f "$recommendations_file" ]; then
                local high_priority_cleanup=$(grep -o '"priority": "high"' "$recommendations_file" 2>/dev/null | wc -l)
                local theme_change=$(grep -o '"workload":' "$recommendations_file" 2>/dev/null | wc -l)
                
                if [ "$high_priority_cleanup" -gt 0 ] || [ "$theme_change" -gt 0 ]; then
                    notify-send "🤖 AI Recommendations" "New optimization suggestions available. Check system status." 2>/dev/null || true
                    ((notifications_sent++))
                fi
            fi
            echo "$hour" > "$last_recommendation_file"
        fi
    fi
    
    if [ "$notifications_sent" -gt 0 ]; then
        log "Sent $notifications_sent smart notifications"
    fi
}

# Manual trigger functions
trigger_full_optimization() {
    log "Triggering full AI system optimization..."
    
    collect_data_background
    optimize_performance_background
    cleanup_system_background
    switch_theme_background
    
    success "Full optimization completed"
}

# Generate system status report
generate_status_report() {
    log "Generating AI system status report..."
    
    local status_file="$CONFIG_DIR/system_status.json"
    local uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
    local uptime_hours=$((uptime_seconds / 3600))
    
    # System metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^ *//')
    
    # AI system status
    local scheduler_status="running"
    if ! pgrep -f "ai-scheduler.sh daemon" >/dev/null; then
        scheduler_status="stopped"
    fi
    
    # Generate JSON report
    cat > "$status_file" << EOF
{
  "timestamp": "$(date --iso-8601=seconds)",
  "system": {
    "uptime_hours": $uptime_hours,
    "cpu_usage": $cpu_usage,
    "memory_usage": $memory_usage,
    "disk_usage": $disk_usage,
    "load_average": $load_avg
  },
  "ai_system": {
    "scheduler_status": "$scheduler_status",
    "last_optimization": "$(stat -c %Y "$CONFIG_DIR/last_optimization" 2>/dev/null || echo "0")",
    "last_cleanup": "$(stat -c %Y "$CONFIG_DIR/last_cleanup" 2>/dev/null || echo "0")",
    "data_collection_active": $([ -f "$CONFIG_DIR/learning_data.json" ] && echo "true" || echo "false")
  },
  "recommendations_available": $([ -f "$CONFIG_DIR/recommendations.json" ] && echo "true" || echo "false"),
  "health_score": $(echo "scale=1; (100 - $memory_usage/2 - $disk_usage/2)" | bc -l 2>/dev/null || echo "75.0")
}
EOF
    
    success "Status report generated: $status_file"
    
    if command -v jq >/dev/null 2>&1; then
        echo "Current Status:"
        jq . "$status_file" 2>/dev/null || cat "$status_file"
    fi
}

# Stop scheduler daemon
stop_scheduler() {
    log "Stopping AI scheduler..."
    
    systemctl --user stop ai-scheduler.timer 2>/dev/null || true
    systemctl --user stop ai-scheduler.service 2>/dev/null || true
    
    # Kill any running daemon processes
    pkill -f "ai-scheduler.sh daemon" 2>/dev/null || true
    
    success "AI scheduler stopped"
}

# Main function dispatcher
case "${1:-help}" in
    setup)
        setup_scheduler
        ;;
    daemon)
        run_daemon
        ;;
    optimize)
        trigger_full_optimization
        ;;
    status)
        generate_status_report
        ;;
    stop)
        stop_scheduler
        ;;
    restart)
        stop_scheduler
        sleep 2
        setup_scheduler
        ;;
    help|*)
        echo "AI System Scheduler"
        echo "Automated background AI operations and monitoring"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  setup      - Install and start the AI scheduler service"
        echo "  daemon     - Run the scheduler daemon (used by systemd)"
        echo "  optimize   - Trigger full system optimization"
        echo "  status     - Generate and display system status report"
        echo "  stop       - Stop the scheduler daemon"
        echo "  restart    - Restart the scheduler daemon"
        echo "  help       - Show this help"
        echo
        echo "The scheduler runs automatically in the background and:"
        echo "  • Collects usage data every 5 minutes"
        echo "  • Optimizes performance every 30 minutes"
        echo "  • Cleans system every 2 hours"
        echo "  • Sends smart notifications every 15 minutes"
        echo "  • Switches themes at optimal times"
        echo
        echo "Examples:"
        echo "  $0 setup     # Install the AI scheduler"
        echo "  $0 status    # Check current system status"
        echo "  $0 optimize  # Run full optimization now"
        ;;
esac
