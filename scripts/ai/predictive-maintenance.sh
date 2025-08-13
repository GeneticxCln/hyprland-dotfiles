#!/bin/bash
# Predictive Maintenance System
# Monitors system health, predicts failures, and performs preventive maintenance

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
CONFIG_DIR="$HOME/.config/hypr/predictive-maintenance"
DATA_DIR="$CONFIG_DIR/data"
HEALTH_DIR="$CONFIG_DIR/health"
ALERTS_DIR="$CONFIG_DIR/alerts"
REPAIRS_DIR="$CONFIG_DIR/repairs"
HEALTH_LOG="$HEALTH_DIR/health_history.json"
PREDICTIONS_LOG="$DATA_DIR/failure_predictions.json"
MAINTENANCE_LOG="$DATA_DIR/maintenance_history.json"

# Health thresholds
CPU_TEMP_WARNING=75
CPU_TEMP_CRITICAL=85
MEMORY_WARNING=85
MEMORY_CRITICAL=95
DISK_WARNING=80
DISK_CRITICAL=90
LOAD_WARNING=3.0
LOAD_CRITICAL=5.0

# Prediction parameters
PREDICTION_WINDOW=24  # hours to predict ahead
HEALTH_SAMPLES=100    # number of samples for trend analysis
FAILURE_THRESHOLD=0.6 # probability threshold for failure prediction

# Logging
log() { echo -e "${BLUE}[PREDICT]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
alert() { echo -e "${MAGENTA}[ALERT]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$HEALTH_DIR" "$ALERTS_DIR" "$REPAIRS_DIR"
}

# Initialize health monitoring
init_health_monitoring() {
    if [ ! -f "$HEALTH_LOG" ]; then
        echo '{"health_records": [], "metrics": {}}' > "$HEALTH_LOG"
    fi
    
    if [ ! -f "$PREDICTIONS_LOG" ]; then
        echo '{"predictions": [], "accuracy_history": []}' > "$PREDICTIONS_LOG"
    fi
    
    if [ ! -f "$MAINTENANCE_LOG" ]; then
        echo '{"maintenance_actions": [], "scheduled_tasks": []}' > "$MAINTENANCE_LOG"
    fi
}

# Collect comprehensive health metrics
collect_health_metrics() {
    log "Collecting health metrics..."
    
    local timestamp=$(date +%s)
    
    # CPU metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_temp="unknown"
    
    # Try to get CPU temperature from various sources
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        cpu_temp=$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
    elif command -v sensors >/dev/null 2>&1; then
        cpu_temp=$(sensors | grep -E "Core|Package" | head -1 | awk '{print $3}' | sed 's/[+°C]//g' | cut -d'.' -f1)
    fi
    
    # Memory metrics
    local mem_total=$(free | grep Mem | awk '{print $2}')
    local mem_used=$(free | grep Mem | awk '{print $3}')
    local mem_available=$(free | grep Mem | awk '{print $7}')
    local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
    local swap_usage=$(free | grep Swap | awk '{if($2>0) printf "%.1f", $3/$2*100; else print "0"}')
    
    # Disk metrics
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    local disk_inodes=$(df -i / | awk 'NR==2{print $5}' | sed 's/%//')
    local disk_io=$(iostat -d 1 2 2>/dev/null | tail -n +4 | head -1 | awk '{print $4}' || echo "0")
    
    # Network metrics
    local network_errors=$(ip -s link show | grep -A1 "RX:" | tail -1 | awk '{print $3}')
    local network_drops=$(ip -s link show | grep -A1 "RX:" | tail -1 | awk '{print $4}')
    
    # Process metrics
    local zombie_procs=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
    local high_cpu_procs=$(ps aux --sort=-%cpu | head -6 | tail -5 | wc -l)
    
    # System uptime
    local uptime_seconds=$(cat /proc/uptime | awk '{print $1}' | cut -d'.' -f1)
    
    # File system health
    local fs_errors=$(dmesg | grep -i "error\|fail\|corrupt" | tail -10 | wc -l)
    
    # Service health
    local failed_services=$(systemctl list-units --failed --no-legend | wc -l)
    
    # Hardware health (if available)
    local smart_warnings=0
    if command -v smartctl >/dev/null 2>&1; then
        smart_warnings=$(smartctl -a /dev/sda 2>/dev/null | grep -i "warning\|error" | wc -l || echo "0")
    fi
    
    # Create health record
    local health_record=$(cat << EOF
{
    "timestamp": $timestamp,
    "cpu": {
        "usage": $cpu_usage,
        "temperature": "$cpu_temp",
        "load_average": $load_avg
    },
    "memory": {
        "usage_percent": $mem_usage,
        "total": $mem_total,
        "used": $mem_used,
        "available": $mem_available,
        "swap_usage": $swap_usage
    },
    "disk": {
        "usage_percent": $disk_usage,
        "inodes_percent": $disk_inodes,
        "io_wait": $disk_io
    },
    "network": {
        "errors": $network_errors,
        "drops": $network_drops
    },
    "system": {
        "uptime_seconds": $uptime_seconds,
        "zombie_processes": $zombie_procs,
        "high_cpu_processes": $high_cpu_procs,
        "filesystem_errors": $fs_errors,
        "failed_services": $failed_services,
        "smart_warnings": $smart_warnings
    }
}
EOF
)
    
    # Append to health log
    local updated_log=$(cat "$HEALTH_LOG" | jq --argjson record "$health_record" '
    .health_records += [$record] |
    .health_records = (.health_records | if length > 1000 then .[1:] else . end)
    ')
    echo "$updated_log" > "$HEALTH_LOG"
    
    # Check for immediate alerts
    check_immediate_alerts "$health_record"
}

# Check for immediate health alerts
check_immediate_alerts() {
    local health_record="$1"
    local alerts=()
    
    # CPU temperature alerts
    local cpu_temp=$(echo "$health_record" | jq -r '.cpu.temperature')
    if [ "$cpu_temp" != "unknown" ] && [ "$cpu_temp" != "null" ]; then
        if (( $(echo "$cpu_temp > $CPU_TEMP_CRITICAL" | bc -l) )); then
            alerts+=("CRITICAL:CPU temperature at ${cpu_temp}°C - immediate cooling required")
        elif (( $(echo "$cpu_temp > $CPU_TEMP_WARNING" | bc -l) )); then
            alerts+=("WARNING:CPU temperature at ${cpu_temp}°C - monitor closely")
        fi
    fi
    
    # Memory alerts
    local mem_usage=$(echo "$health_record" | jq -r '.memory.usage_percent')
    if (( $(echo "$mem_usage > $MEMORY_CRITICAL" | bc -l) )); then
        alerts+=("CRITICAL:Memory usage at ${mem_usage}% - system may become unresponsive")
    elif (( $(echo "$mem_usage > $MEMORY_WARNING" | bc -l) )); then
        alerts+=("WARNING:Memory usage at ${mem_usage}% - consider closing applications")
    fi
    
    # Disk alerts
    local disk_usage=$(echo "$health_record" | jq -r '.disk.usage_percent')
    if (( $(echo "$disk_usage > $DISK_CRITICAL" | bc -l) )); then
        alerts+=("CRITICAL:Disk usage at ${disk_usage}% - immediate cleanup required")
    elif (( $(echo "$disk_usage > $DISK_WARNING" | bc -l) )); then
        alerts+=("WARNING:Disk usage at ${disk_usage}% - cleanup recommended")
    fi
    
    # Load average alerts
    local load_avg=$(echo "$health_record" | jq -r '.cpu.load_average')
    if (( $(echo "$load_avg > $LOAD_CRITICAL" | bc -l) )); then
        alerts+=("CRITICAL:Load average at $load_avg - system overloaded")
    elif (( $(echo "$load_avg > $LOAD_WARNING" | bc -l) )); then
        alerts+=("WARNING:Load average at $load_avg - high system load")
    fi
    
    # System health alerts
    local failed_services=$(echo "$health_record" | jq -r '.system.failed_services')
    if [ "$failed_services" -gt 0 ]; then
        alerts+=("WARNING:$failed_services failed system services detected")
    fi
    
    local smart_warnings=$(echo "$health_record" | jq -r '.system.smart_warnings')
    if [ "$smart_warnings" -gt 0 ]; then
        alerts+=("WARNING:$smart_warnings SMART warnings detected - disk health issues")
    fi
    
    # Process alerts
    for alert in "${alerts[@]}"; do
        local level=$(echo "$alert" | cut -d':' -f1)
        local message=$(echo "$alert" | cut -d':' -f2-)
        
        case "$level" in
            "CRITICAL") error "$message" ;;
            "WARNING") warning "$message" ;;
        esac
        
        # Log alert
        echo "{\"timestamp\": $(date +%s), \"level\": \"$level\", \"message\": \"$message\"}" >> "$ALERTS_DIR/alerts_$(date +%Y%m%d).json"
    done
}

# Analyze health trends and predict failures
predict_failures() {
    log "Analyzing health trends and predicting failures..."
    
    local health_data=$(cat "$HEALTH_LOG" | jq '.health_records')
    local record_count=$(echo "$health_data" | jq length)
    
    if [ "$record_count" -lt 10 ]; then
        warning "Insufficient data for predictions (need at least 10 records)"
        return 1
    fi
    
    # Analyze CPU temperature trend
    local cpu_temp_trend=$(echo "$health_data" | jq '
    [.[] | select(.cpu.temperature != "unknown" and .cpu.temperature != null)] |
    if length > 5 then
        (.[length-5:] | map(.cpu.temperature | tonumber) | 
         (.[length-1] - .[0]) / length)
    else 0 end')
    
    # Analyze memory usage trend
    local memory_trend=$(echo "$health_data" | jq '
    if length > 5 then
        (.[length-5:] | map(.memory.usage_percent) | 
         (.[length-1] - .[0]) / length)
    else 0 end')
    
    # Analyze disk usage trend
    local disk_trend=$(echo "$health_data" | jq '
    if length > 5 then
        (.[length-5:] | map(.disk.usage_percent) | 
         (.[length-1] - .[0]) / length)
    else 0 end')
    
    # Calculate failure probabilities
    local predictions=()
    
    # CPU overheat prediction
    if [ "$cpu_temp_trend" != "0" ] && [ "$cpu_temp_trend" != "null" ]; then
        local current_temp=$(echo "$health_data" | jq -r '.[-1].cpu.temperature')
        if [ "$current_temp" != "unknown" ] && [ "$current_temp" != "null" ]; then
            local predicted_temp=$(echo "scale=2; $current_temp + ($cpu_temp_trend * $PREDICTION_WINDOW)" | bc)
            local overheat_probability=0
            
            if (( $(echo "$predicted_temp > $CPU_TEMP_CRITICAL" | bc -l) )); then
                overheat_probability=$(echo "scale=2; ($predicted_temp - $CPU_TEMP_CRITICAL) / 10 + 0.5" | bc)
                overheat_probability=$(echo "if ($overheat_probability > 1) 1 else $overheat_probability" | bc)
            fi
            
            predictions+=("{\"type\": \"cpu_overheat\", \"probability\": $overheat_probability, \"predicted_value\": $predicted_temp, \"threshold\": $CPU_TEMP_CRITICAL}")
        fi
    fi
    
    # Memory exhaustion prediction
    if [ "$memory_trend" != "0" ]; then
        local current_memory=$(echo "$health_data" | jq -r '.[-1].memory.usage_percent')
        local predicted_memory=$(echo "scale=2; $current_memory + ($memory_trend * $PREDICTION_WINDOW)" | bc)
        local memory_exhaustion_probability=0
        
        if (( $(echo "$predicted_memory > $MEMORY_CRITICAL" | bc -l) )); then
            memory_exhaustion_probability=$(echo "scale=2; ($predicted_memory - $MEMORY_CRITICAL) / 20 + 0.3" | bc)
            memory_exhaustion_probability=$(echo "if ($memory_exhaustion_probability > 1) 1 else $memory_exhaustion_probability" | bc)
        fi
        
        predictions+=("{\"type\": \"memory_exhaustion\", \"probability\": $memory_exhaustion_probability, \"predicted_value\": $predicted_memory, \"threshold\": $MEMORY_CRITICAL}")
    fi
    
    # Disk full prediction
    if [ "$disk_trend" != "0" ]; then
        local current_disk=$(echo "$health_data" | jq -r '.[-1].disk.usage_percent')
        local predicted_disk=$(echo "scale=2; $current_disk + ($disk_trend * $PREDICTION_WINDOW)" | bc)
        local disk_full_probability=0
        
        if (( $(echo "$predicted_disk > $DISK_CRITICAL" | bc -l) )); then
            disk_full_probability=$(echo "scale=2; ($predicted_disk - $DISK_CRITICAL) / 15 + 0.4" | bc)
            disk_full_probability=$(echo "if ($disk_full_probability > 1) 1 else $disk_full_probability" | bc)
        fi
        
        predictions+=("{\"type\": \"disk_full\", \"probability\": $disk_full_probability, \"predicted_value\": $predicted_disk, \"threshold\": $DISK_CRITICAL}")
    fi
    
    # System instability prediction (based on multiple factors)
    local instability_score=0
    local load_avg=$(echo "$health_data" | jq -r '.[-1].cpu.load_average')
    local zombie_procs=$(echo "$health_data" | jq -r '.[-1].system.zombie_processes')
    local failed_services=$(echo "$health_data" | jq -r '.[-1].system.failed_services')
    
    instability_score=$(echo "scale=2; $instability_score + ($load_avg / 10)" | bc)
    instability_score=$(echo "scale=2; $instability_score + ($zombie_procs * 0.1)" | bc)
    instability_score=$(echo "scale=2; $instability_score + ($failed_services * 0.2)" | bc)
    
    predictions+=("{\"type\": \"system_instability\", \"probability\": $instability_score, \"predicted_value\": $instability_score, \"threshold\": 0.6}")
    
    # Create predictions record
    local prediction_record=$(printf '%s\n' "${predictions[@]}" | jq -s '{
        "timestamp": now,
        "prediction_window_hours": '$PREDICTION_WINDOW',
        "predictions": .
    }')
    
    # Update predictions log
    local updated_predictions=$(cat "$PREDICTIONS_LOG" | jq --argjson record "$prediction_record" '
    .predictions += [$record] |
    .predictions = (.predictions | if length > 100 then .[1:] else . end)
    ')
    echo "$updated_predictions" > "$PREDICTIONS_LOG"
    
    # Show high-probability predictions
    echo "$prediction_record" | jq -r '.predictions[] | 
    select(.probability > '$FAILURE_THRESHOLD') | 
    "PREDICTION: " + .type + " (probability: " + (.probability * 100 | floor | tostring) + "%)"' |
    while read -r pred; do
        alert "$pred"
    done
}

# Perform predictive maintenance actions
perform_maintenance() {
    log "Performing predictive maintenance..."
    
    local maintenance_actions=()
    local predictions=$(cat "$PREDICTIONS_LOG" | jq -r '.predictions[-1].predictions[]? // empty')
    
    while IFS= read -r prediction; do
        local pred_type=$(echo "$prediction" | jq -r '.type')
        local probability=$(echo "$prediction" | jq -r '.probability')
        
        if (( $(echo "$probability > $FAILURE_THRESHOLD" | bc -l) )); then
            case "$pred_type" in
                "cpu_overheat")
                    log "Applying CPU cooling optimizations..."
                    # Reduce CPU frequency
                    echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
                    # Kill high CPU processes if gaming mode is not active
                    if [ ! -f "$HOME/.config/hypr/gaming/gaming_state" ] || ! grep -q "ACTIVE=true" "$HOME/.config/hypr/gaming/gaming_state"; then
                        pkill -f "chrome\|firefox" >/dev/null 2>&1 || true
                    fi
                    maintenance_actions+=("CPU_COOLING:Applied power save governor and closed heavy applications")
                    ;;
                "memory_exhaustion")
                    log "Applying memory optimization..."
                    # Clear caches
                    sync
                    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
                    # Kill memory-heavy processes
                    pkill -f "electron\|slack" >/dev/null 2>&1 || true
                    maintenance_actions+=("MEMORY_CLEANUP:Cleared caches and closed memory-heavy applications")
                    ;;
                "disk_full")
                    log "Applying disk cleanup..."
                    # Run comprehensive cleanup
                    if [ -f "$HOME/.config/hypr/scripts/system/system-maintenance.sh" ]; then
                        bash "$HOME/.config/hypr/scripts/system/system-maintenance.sh" cleanup >/dev/null 2>&1 || true
                    fi
                    # Clean package cache
                    sudo pacman -Scc --noconfirm >/dev/null 2>&1 || true
                    maintenance_actions+=("DISK_CLEANUP:Performed system cleanup and removed cached packages")
                    ;;
                "system_instability")
                    log "Applying system stabilization..."
                    # Restart problematic services
                    sudo systemctl restart NetworkManager >/dev/null 2>&1 || true
                    # Clear systemd journal
                    sudo journalctl --vacuum-time=1d >/dev/null 2>&1 || true
                    maintenance_actions+=("SYSTEM_STABILIZATION:Restarted services and cleaned logs")
                    ;;
            esac
        fi
    done <<< "$predictions"
    
    # Log maintenance actions
    if [ ${#maintenance_actions[@]} -gt 0 ]; then
        local maintenance_record=$(printf '%s\n' "${maintenance_actions[@]}" | jq -R -s '{
            "timestamp": now,
            "actions": split("\n")[:-1] | map(split(":") | {"type": .[0], "description": .[1]})
        }')
        
        local updated_maintenance=$(cat "$MAINTENANCE_LOG" | jq --argjson record "$maintenance_record" '
        .maintenance_actions += [$record]')
        echo "$updated_maintenance" > "$MAINTENANCE_LOG"
        
        success "Applied ${#maintenance_actions[@]} maintenance actions"
    else
        log "No maintenance actions required"
    fi
}

# Schedule automated maintenance
schedule_maintenance() {
    log "Setting up automated maintenance schedule..."
    
    # Create systemd timer for predictive maintenance
    cat > "/tmp/predictive-maintenance.service" << EOF
[Unit]
Description=Predictive Maintenance System
After=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=$HOME/.config/hypr/scripts/ai/predictive-maintenance.sh monitor
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > "/tmp/predictive-maintenance.timer" << EOF
[Unit]
Description=Run Predictive Maintenance every 15 minutes
Requires=predictive-maintenance.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Install systemd files
    sudo cp "/tmp/predictive-maintenance.service" "/etc/systemd/system/"
    sudo cp "/tmp/predictive-maintenance.timer" "/etc/systemd/system/"
    
    # Enable and start timer
    sudo systemctl daemon-reload
    sudo systemctl enable predictive-maintenance.timer
    sudo systemctl start predictive-maintenance.timer
    
    success "Automated maintenance scheduled every 15 minutes"
    
    rm -f "/tmp/predictive-maintenance.service" "/tmp/predictive-maintenance.timer"
}

# Show health dashboard
show_health_dashboard() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Predictive Maintenance Dashboard          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$HEALTH_LOG" ]; then
        warning "No health data available. Run 'monitor' first."
        return 1
    fi
    
    local latest_health=$(cat "$HEALTH_LOG" | jq '.health_records[-1]')
    
    # Current system health
    echo -e "${GREEN}Current System Health:${NC}"
    local cpu_usage=$(echo "$latest_health" | jq -r '.cpu.usage')
    local cpu_temp=$(echo "$latest_health" | jq -r '.cpu.temperature')
    local memory_usage=$(echo "$latest_health" | jq -r '.memory.usage_percent')
    local disk_usage=$(echo "$latest_health" | jq -r '.disk.usage_percent')
    local load_avg=$(echo "$latest_health" | jq -r '.cpu.load_average')
    
    echo -e "  CPU: ${cpu_usage}% (Temp: ${cpu_temp}°C, Load: $load_avg)"
    echo -e "  Memory: ${memory_usage}%"
    echo -e "  Disk: ${disk_usage}%"
    
    # Health trends
    echo -e "\n${GREEN}Health Trends (last 5 readings):${NC}"
    local cpu_trend=$(cat "$HEALTH_LOG" | jq -r '
    .health_records[-5:] | map(.cpu.usage) | 
    if length > 1 then (.[length-1] - .[0]) / (length-1) else 0 end')
    local mem_trend=$(cat "$HEALTH_LOG" | jq -r '
    .health_records[-5:] | map(.memory.usage_percent) | 
    if length > 1 then (.[length-1] - .[0]) / (length-1) else 0 end')
    
    if (( $(echo "$cpu_trend > 0" | bc -l) )); then
        echo -e "  CPU Usage: ${RED}↗ Increasing (+${cpu_trend}%/reading)${NC}"
    elif (( $(echo "$cpu_trend < 0" | bc -l) )); then
        echo -e "  CPU Usage: ${GREEN}↘ Decreasing (${cpu_trend}%/reading)${NC}"
    else
        echo -e "  CPU Usage: ${YELLOW}→ Stable${NC}"
    fi
    
    if (( $(echo "$mem_trend > 0" | bc -l) )); then
        echo -e "  Memory Usage: ${RED}↗ Increasing (+${mem_trend}%/reading)${NC}"
    elif (( $(echo "$mem_trend < 0" | bc -l) )); then
        echo -e "  Memory Usage: ${GREEN}↘ Decreasing (${mem_trend}%/reading)${NC}"
    else
        echo -e "  Memory Usage: ${YELLOW}→ Stable${NC}"
    fi
    
    # Failure predictions
    echo -e "\n${GREEN}Failure Predictions:${NC}"
    if [ -f "$PREDICTIONS_LOG" ]; then
        local latest_predictions=$(cat "$PREDICTIONS_LOG" | jq '.predictions[-1].predictions[]? // empty')
        local high_risk_count=0
        
        while IFS= read -r pred; do
            local pred_type=$(echo "$pred" | jq -r '.type')
            local probability=$(echo "$pred" | jq -r '.probability')
            local percentage=$(echo "scale=0; $probability * 100" | bc | cut -d'.' -f1)
            
            if (( $(echo "$probability > 0.8" | bc -l) )); then
                echo -e "  ${RED}🔴 $pred_type: ${percentage}% (CRITICAL)${NC}"
                ((high_risk_count++))
            elif (( $(echo "$probability > $FAILURE_THRESHOLD" | bc -l) )); then
                echo -e "  ${YELLOW}🟡 $pred_type: ${percentage}% (HIGH)${NC}"
                ((high_risk_count++))
            elif (( $(echo "$probability > 0.3" | bc -l) )); then
                echo -e "  ${BLUE}🔵 $pred_type: ${percentage}% (MEDIUM)${NC}"
            fi
        done <<< "$latest_predictions"
        
        if [ "$high_risk_count" -eq 0 ]; then
            echo -e "  ${GREEN}✅ No high-risk predictions${NC}"
        fi
    else
        echo -e "  ${YELLOW}No predictions available${NC}"
    fi
    
    # Recent maintenance
    echo -e "\n${GREEN}Recent Maintenance Actions:${NC}"
    if [ -f "$MAINTENANCE_LOG" ]; then
        local recent_maintenance=$(cat "$MAINTENANCE_LOG" | jq -r '
        .maintenance_actions[-3:][] | 
        .timestamp as $ts | .actions[] | 
        "  " + (.type | gsub("_"; " ")) + ": " + .description' 2>/dev/null || echo "  No recent actions")
        echo -e "$recent_maintenance"
    else
        echo -e "  No maintenance history"
    fi
    
    # System status
    echo -e "\n${GREEN}Monitoring Status:${NC}"
    if systemctl is-active predictive-maintenance.timer >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Automated monitoring active${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Automated monitoring not active${NC}"
    fi
    
    local record_count=$(cat "$HEALTH_LOG" | jq '.health_records | length')
    echo -e "  Health records: $record_count"
}

# Monitor mode (continuous health monitoring)
monitor_mode() {
    log "Starting health monitoring cycle..."
    
    collect_health_metrics
    predict_failures
    perform_maintenance
    
    success "Health monitoring cycle completed"
}

# Show help
show_help() {
    echo "Usage: predictive-maintenance [command]"
    echo
    echo "Monitoring Commands:"
    echo "  monitor              Perform one monitoring cycle"
    echo "  dashboard            Show health and predictions dashboard"
    echo "  health               Collect current health metrics"
    echo "  predict              Analyze trends and predict failures"
    echo "  maintain             Perform predictive maintenance actions"
    echo
    echo "Management Commands:"
    echo "  schedule             Set up automated monitoring"
    echo "  unschedule          Remove automated monitoring"
    echo "  history             Show health history"
    echo "  alerts              Show recent alerts"
    echo
    echo "Examples:"
    echo "  predictive-maintenance dashboard"
    echo "  predictive-maintenance monitor"
    echo "  predictive-maintenance schedule"
    echo
    echo "Features:"
    echo "  • Predictive failure analysis"
    echo "  • Automated preventive maintenance"
    echo "  • Trend-based health monitoring"
    echo "  • Smart alert system"
    echo "  • Self-healing capabilities"
    echo "  • Performance optimization"
    echo
}

# Unschedule automated maintenance
unschedule_maintenance() {
    log "Removing automated maintenance schedule..."
    
    sudo systemctl stop predictive-maintenance.timer >/dev/null 2>&1 || true
    sudo systemctl disable predictive-maintenance.timer >/dev/null 2>&1 || true
    sudo rm -f "/etc/systemd/system/predictive-maintenance.timer" || true
    sudo rm -f "/etc/systemd/system/predictive-maintenance.service" || true
    sudo systemctl daemon-reload
    
    success "Automated maintenance removed"
}

# Main execution
setup_dirs
init_health_monitoring

case "${1:-dashboard}" in
    monitor) monitor_mode ;;
    dashboard) show_health_dashboard ;;
    health) collect_health_metrics ;;
    predict) predict_failures ;;
    maintain) perform_maintenance ;;
    schedule) schedule_maintenance ;;
    unschedule) unschedule_maintenance ;;
    history) 
        if [ -f "$HEALTH_LOG" ]; then
            cat "$HEALTH_LOG" | jq '.health_records[-10:]' 
        else
            error "No health history available"
        fi
        ;;
    alerts)
        if ls "$ALERTS_DIR"/alerts_*.json >/dev/null 2>&1; then
            cat "$ALERTS_DIR"/alerts_*.json | tail -20
        else
            log "No alerts found"
        fi
        ;;
    help|*) show_help ;;
esac
