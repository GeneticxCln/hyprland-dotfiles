#!/bin/bash
# Smart System Optimizer with AI-powered recommendations
# Learns usage patterns and provides intelligent system optimizations

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
CONFIG_DIR="$HOME/.config/hypr/ai-optimizer"
DATA_DIR="$CONFIG_DIR/data"
MODELS_DIR="$CONFIG_DIR/models"
LOGS_DIR="$CONFIG_DIR/logs"
PATTERNS_FILE="$DATA_DIR/usage_patterns.json"
PREDICTIONS_FILE="$DATA_DIR/predictions.json"
RECOMMENDATIONS_FILE="$DATA_DIR/recommendations.json"

# Learning parameters
LEARNING_WINDOW=7 # days
MIN_SAMPLES=10
CONFIDENCE_THRESHOLD=0.7

# Logging
log() { echo -e "${BLUE}[AI-OPT]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$MODELS_DIR" "$LOGS_DIR"
}

# Initialize data structures
init_data_structures() {
    if [ ! -f "$PATTERNS_FILE" ]; then
        cat > "$PATTERNS_FILE" << 'EOF'
{
    "system_usage": {
        "hourly_patterns": {},
        "daily_patterns": {},
        "weekly_patterns": {},
        "application_usage": {},
        "resource_consumption": {},
        "performance_metrics": {}
    },
    "user_behavior": {
        "gaming_sessions": [],
        "work_patterns": [],
        "theme_preferences": [],
        "audio_profiles": [],
        "display_configurations": []
    },
    "environmental_data": {
        "time_based_preferences": {},
        "workload_patterns": {},
        "power_profiles": {}
    }
}
EOF
    fi
    
    if [ ! -f "$PREDICTIONS_FILE" ]; then
        echo '{"predictions": [], "accuracy_metrics": {}}' > "$PREDICTIONS_FILE"
    fi
    
    if [ ! -f "$RECOMMENDATIONS_FILE" ]; then
        echo '{"recommendations": [], "applied": [], "feedback": []}' > "$RECOMMENDATIONS_FILE"
    fi
}

# Collect system usage data
collect_usage_data() {
    local timestamp=$(date +%s)
    local hour=$(date +%H)
    local day=$(date +%u)
    local date_str=$(date +%Y-%m-%d)
    
    log "Collecting usage data..."
    
    # System metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    # Active applications
    local active_apps=$(hyprctl clients -j | jq -r '.[].class' | sort | uniq -c | sort -nr)
    
    # Current workspace
    local workspace=$(hyprctl activeworkspace -j | jq -r '.id')
    
    # Gaming mode status
    local gaming_active="false"
    if [ -f "$HOME/.config/hypr/gaming/gaming_state" ] && grep -q "ACTIVE=true" "$HOME/.config/hypr/gaming/gaming_state"; then
        gaming_active="true"
    fi
    
    # Power profile (if available)
    local power_profile="balanced"
    if command -v powerprofilesctl >/dev/null 2>&1; then
        power_profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
    fi
    
    # Create usage record
    local usage_record=$(cat << EOF
{
    "timestamp": $timestamp,
    "hour": $hour,
    "day": $day,
    "date": "$date_str",
    "system_metrics": {
        "cpu_usage": $cpu_usage,
        "memory_usage": $memory_usage,
        "disk_usage": $disk_usage
    },
    "user_context": {
        "active_workspace": $workspace,
        "gaming_mode": $gaming_active,
        "power_profile": "$power_profile"
    },
    "applications": $(echo "$active_apps" | head -10 | jq -R -s 'split("\n")[:-1]')
}
EOF
)
    
    # Append to daily log
    echo "$usage_record" >> "$LOGS_DIR/usage_$(date +%Y%m%d).json"
}

# Analyze patterns using simple statistical methods
analyze_patterns() {
    log "Analyzing usage patterns..."
    
    # Combine recent logs
    local combined_data="$DATA_DIR/combined_recent.json"
    echo '[]' > "$combined_data"
    
    # Process last 7 days of logs
    for i in $(seq 0 $((LEARNING_WINDOW-1))); do
        local date_str=$(date -d "-$i days" +%Y%m%d)
        local log_file="$LOGS_DIR/usage_$date_str.json"
        
        if [ -f "$log_file" ]; then
            # Combine all records into a single JSON array
            jq -s 'add' "$combined_data" <(cat "$log_file" | jq -s .) > "$combined_data.tmp"
            mv "$combined_data.tmp" "$combined_data"
        fi
    done
    
    # Analyze patterns with jq
    local patterns=$(cat "$combined_data" | jq '
    {
        "hourly_cpu_avg": (group_by(.hour) | map({
            hour: .[0].hour,
            avg_cpu: (map(.system_metrics.cpu_usage | tonumber) | add / length)
        })),
        "daily_patterns": (group_by(.day) | map({
            day: .[0].day,
            avg_cpu: (map(.system_metrics.cpu_usage | tonumber) | add / length),
            avg_memory: (map(.system_metrics.memory_usage | tonumber) | add / length),
            gaming_sessions: (map(select(.user_context.gaming_mode == "true")) | length)
        })),
        "workspace_usage": (group_by(.user_context.active_workspace) | map({
            workspace: .[0].user_context.active_workspace,
            usage_count: length,
            avg_cpu: (map(.system_metrics.cpu_usage | tonumber) | add / length)
        })),
        "gaming_patterns": {
            "total_sessions": (map(select(.user_context.gaming_mode == "true")) | length),
            "avg_gaming_cpu": (map(select(.user_context.gaming_mode == "true")) | 
                             map(.system_metrics.cpu_usage | tonumber) | 
                             if length > 0 then (add / length) else 0 end),
            "gaming_hours": (map(select(.user_context.gaming_mode == "true")) | 
                            map(.hour) | group_by(.) | map({hour: .[0], count: length}))
        }
    }')
    
    # Update patterns file
    local updated_patterns=$(jq --argjson new_patterns "$patterns" '
    .system_usage.hourly_patterns = $new_patterns.hourly_cpu_avg |
    .system_usage.daily_patterns = $new_patterns.daily_patterns |
    .user_behavior.gaming_sessions = $new_patterns.gaming_patterns |
    .system_usage.resource_consumption = $new_patterns.workspace_usage
    ' "$PATTERNS_FILE")
    
    echo "$updated_patterns" > "$PATTERNS_FILE"
    
    success "Pattern analysis completed"
}

# Generate intelligent recommendations
generate_recommendations() {
    log "Generating AI-powered recommendations..."
    
    local current_hour=$(date +%H)
    local current_day=$(date +%u)
    local recommendations=()
    
    # Load current patterns
    local patterns=$(cat "$PATTERNS_FILE")
    
    # CPU optimization recommendations
    local avg_cpu=$(echo "$patterns" | jq -r --argjson hour "$current_hour" '
    .system_usage.hourly_patterns[] | select(.hour == $hour) | .avg_cpu // 0')
    
    if (( $(echo "$avg_cpu > 70" | bc -l) )); then
        recommendations+=("HIGH_CPU_USAGE:Consider enabling performance mode or closing unnecessary applications")
        recommendations+=("CPU_OPTIMIZATION:Gaming mode might improve performance during high CPU usage")
    fi
    
    # Gaming pattern recommendations
    local gaming_data=$(echo "$patterns" | jq -r '.user_behavior.gaming_sessions')
    local gaming_hours=$(echo "$gaming_data" | jq -r --argjson hour "$current_hour" '
    .gaming_hours[]? | select(.hour == $hour) | .count // 0')
    
    if (( $(echo "$gaming_hours > 3" | bc -l) )); then
        recommendations+=("GAMING_PREDICTION:High probability of gaming session. Pre-enable gaming mode?")
        recommendations+=("PERFORMANCE_PREP:Consider switching to performance power profile")
    fi
    
    # Workspace optimization
    local workspace_data=$(echo "$patterns" | jq -r '.system_usage.resource_consumption')
    local high_usage_workspaces=$(echo "$workspace_data" | jq -r '.[] | select(.avg_cpu > 60) | .workspace')
    
    if [ -n "$high_usage_workspaces" ]; then
        recommendations+=("WORKSPACE_OPTIMIZATION:Consider redistributing applications across workspaces")
    fi
    
    # Power management recommendations
    local low_usage_hours=$(echo "$patterns" | jq -r '.system_usage.hourly_patterns[] | select(.avg_cpu < 30) | .hour')
    if echo "$low_usage_hours" | grep -q "$current_hour"; then
        recommendations+=("POWER_SAVINGS:Low usage period detected. Consider power-save mode")
        recommendations+=("MAINTENANCE_WINDOW:Good time for system maintenance and cleanup")
    fi
    
    # Memory optimization
    local current_memory=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if (( $(echo "$current_memory > 80" | bc -l) )); then
        recommendations+=("MEMORY_CLEANUP:High memory usage detected. Consider running memory cleanup")
        recommendations+=("APPLICATION_AUDIT:Review running applications for memory leaks")
    fi
    
    # Time-based theme recommendations
    if [ "$current_hour" -ge 18 ] || [ "$current_hour" -le 6 ]; then
        recommendations+=("THEME_SUGGESTION:Consider switching to dark theme for evening usage")
    else
        recommendations+=("THEME_SUGGESTION:Light theme recommended for daytime usage")
    fi
    
    # Generate structured recommendations
    local structured_recommendations=$(printf '%s\n' "${recommendations[@]}" | jq -R -s '
    split("\n")[:-1] | map(split(":") | {
        category: .[0],
        message: .[1],
        timestamp: now,
        confidence: (if (.[0] | contains("PREDICTION")) then 0.8 
                    elif (.[0] | contains("OPTIMIZATION")) then 0.9 
                    else 0.7 end),
        priority: (if (.[0] | contains("HIGH") or .[0] | contains("CRITICAL")) then "high"
                  elif (.[0] | contains("SUGGESTION")) then "low"
                  else "medium" end),
        applied: false
    })')
    
    # Update recommendations file
    echo "{\"recommendations\": $structured_recommendations, \"generated_at\": $(date +%s)}" > "$RECOMMENDATIONS_FILE"
    
    success "Generated $(echo "$structured_recommendations" | jq length) recommendations"
}

# Apply automatic optimizations
apply_auto_optimizations() {
    log "Applying automatic optimizations..."
    
    local recommendations=$(cat "$RECOMMENDATIONS_FILE" | jq -r '.recommendations[]')
    local applied_count=0
    
    while IFS= read -r rec; do
        local category=$(echo "$rec" | jq -r '.category')
        local confidence=$(echo "$rec" | jq -r '.confidence')
        local priority=$(echo "$rec" | jq -r '.priority')
        
        # Only auto-apply high-confidence, non-disruptive optimizations
        if (( $(echo "$confidence > 0.8" | bc -l) )) && [ "$priority" != "high" ]; then
            case "$category" in
                "POWER_SAVINGS")
                    if command -v powerprofilesctl >/dev/null 2>&1; then
                        powerprofilesctl set power-saver 2>/dev/null || true
                        log "Applied power-save profile"
                        ((applied_count++))
                    fi
                    ;;
                "MEMORY_CLEANUP")
                    # Run gentle memory cleanup
                    sync
                    echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
                    log "Applied memory cleanup"
                    ((applied_count++))
                    ;;
                "CPU_OPTIMIZATION")
                    # Adjust CPU governor if not in gaming mode
                    if [ ! -f "$HOME/.config/hypr/gaming/gaming_state" ] || ! grep -q "ACTIVE=true" "$HOME/.config/hypr/gaming/gaming_state"; then
                        echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
                        log "Applied CPU optimization"
                        ((applied_count++))
                    fi
                    ;;
            esac
        fi
    done <<< "$recommendations"
    
    success "Applied $applied_count automatic optimizations"
}

# Show intelligent dashboard
show_dashboard() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                Smart System Dashboard                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    
    # Current system status
    echo -e "${GREEN}Current System Status:${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo -e "  CPU Usage: ${cpu_usage}%"
    echo -e "  Memory Usage: ${memory_usage}%"
    echo -e "  Load Average: $load_avg"
    
    # AI Predictions
    echo -e "\n${GREEN}AI Predictions:${NC}"
    if [ -f "$PATTERNS_FILE" ]; then
        local current_hour=$(date +%H)
        local predicted_cpu=$(cat "$PATTERNS_FILE" | jq -r --argjson hour "$current_hour" '
        .system_usage.hourly_patterns[]? | select(.hour == $hour) | .avg_cpu // "No data"')
        
        if [ "$predicted_cpu" != "No data" ] && [ "$predicted_cpu" != "null" ]; then
            echo -e "  Predicted CPU for this hour: ${predicted_cpu}%"
            
            # Compare with actual
            local diff=$(echo "$cpu_usage - $predicted_cpu" | bc)
            if (( $(echo "$diff > 10" | bc -l) )); then
                echo -e "  ${YELLOW}⚠️  Higher than predicted (+${diff}%)${NC}"
            elif (( $(echo "$diff < -10" | bc -l) )); then
                echo -e "  ${GREEN}✅ Lower than predicted (${diff}%)${NC}"
            else
                echo -e "  ${GREEN}✅ Within predicted range${NC}"
            fi
        else
            echo -e "  ${YELLOW}Still learning patterns...${NC}"
        fi
    fi
    
    # Active recommendations
    echo -e "\n${GREEN}Active Recommendations:${NC}"
    if [ -f "$RECOMMENDATIONS_FILE" ]; then
        local rec_count=$(cat "$RECOMMENDATIONS_FILE" | jq -r '.recommendations | length')
        if [ "$rec_count" -gt 0 ]; then
            cat "$RECOMMENDATIONS_FILE" | jq -r '.recommendations[] | 
            "  " + (.priority | ascii_upcase) + ": " + .message' | head -5
            
            if [ "$rec_count" -gt 5 ]; then
                echo -e "  ${YELLOW}... and $((rec_count - 5)) more${NC}"
            fi
        else
            echo -e "  ${GREEN}No active recommendations${NC}"
        fi
    fi
    
    # Learning status
    echo -e "\n${GREEN}Learning Status:${NC}"
    local days_of_data=$(ls "$LOGS_DIR"/usage_*.json 2>/dev/null | wc -l)
    local total_samples=$(cat "$LOGS_DIR"/usage_*.json 2>/dev/null | wc -l)
    
    echo -e "  Days of data: $days_of_data"
    echo -e "  Total samples: $total_samples"
    
    if [ "$total_samples" -ge "$MIN_SAMPLES" ]; then
        echo -e "  ${GREEN}✅ Sufficient data for predictions${NC}"
    else
        echo -e "  ${YELLOW}⏳ Collecting more data (need $((MIN_SAMPLES - total_samples)) more samples)${NC}"
    fi
}

# Predict optimal settings
predict_optimal_settings() {
    local target_time="${1:-now}"
    
    log "Predicting optimal settings for $target_time"
    
    # Parse target time
    local target_hour
    if [ "$target_time" = "now" ]; then
        target_hour=$(date +%H)
    else
        target_hour=$(date -d "$target_time" +%H 2>/dev/null || echo "$(date +%H)")
    fi
    
    # Load patterns
    local patterns=$(cat "$PATTERNS_FILE")
    
    # Predict gaming likelihood
    local gaming_probability=$(echo "$patterns" | jq -r --argjson hour "$target_hour" '
    (.user_behavior.gaming_sessions.gaming_hours[]? | select(.hour == $hour) | .count // 0) / 
    (.user_behavior.gaming_sessions.total_sessions // 1) * 100')
    
    # Predict resource usage
    local predicted_cpu=$(echo "$patterns" | jq -r --argjson hour "$target_hour" '
    .system_usage.hourly_patterns[]? | select(.hour == $hour) | .avg_cpu // 50')
    
    echo -e "${GREEN}Predictions for hour $target_hour:${NC}"
    echo -e "  CPU Usage: ${predicted_cpu}%"
    echo -e "  Gaming Probability: ${gaming_probability}%"
    
    # Optimal settings recommendations
    echo -e "\n${GREEN}Recommended Settings:${NC}"
    
    if (( $(echo "$gaming_probability > 50" | bc -l) )); then
        echo -e "  🎮 Enable Gaming Mode"
        echo -e "  ⚡ Performance Power Profile"
        echo -e "  🎨 Gaming Theme Profile"
    fi
    
    if (( $(echo "$predicted_cpu > 70" | bc -l) )); then
        echo -e "  🔥 Monitor CPU Temperature"
        echo -e "  💨 Increase Fan Curves"
        echo -e "  🚀 Performance CPU Governor"
    elif (( $(echo "$predicted_cpu < 30" | bc -l) )); then
        echo -e "  🔋 Power Save Mode"
        echo -e "  💤 Reduce Background Services"
        echo -e "  🌱 Eco CPU Governor"
    fi
}

# Train the model with new data
train_model() {
    log "Training optimization model..."
    
    collect_usage_data
    analyze_patterns
    generate_recommendations
    
    # Calculate accuracy of previous predictions
    local accuracy_file="$DATA_DIR/accuracy.json"
    if [ -f "$PREDICTIONS_FILE" ]; then
        # Simple accuracy calculation based on CPU predictions
        local actual_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
        local current_hour=$(date +%H)
        local predicted_cpu=$(cat "$PATTERNS_FILE" | jq -r --argjson hour "$current_hour" '
        .system_usage.hourly_patterns[]? | select(.hour == $hour) | .avg_cpu // 0')
        
        if [ "$predicted_cpu" != "0" ]; then
            local error=$(echo "scale=2; sqrt(($actual_cpu - $predicted_cpu)^2)" | bc)
            local accuracy=$(echo "scale=2; 100 - ($error / $actual_cpu * 100)" | bc)
            
            echo "{\"timestamp\": $(date +%s), \"accuracy\": $accuracy, \"error\": $error}" >> "$accuracy_file"
            log "Prediction accuracy: ${accuracy}%"
        fi
    fi
    
    success "Model training completed"
}

# Show help
show_help() {
    echo "Usage: smart-optimizer [command] [options]"
    echo
    echo "Learning Commands:"
    echo "  collect              Collect current usage data"
    echo "  analyze              Analyze usage patterns"
    echo "  train                Train the optimization model"
    echo
    echo "Prediction Commands:"
    echo "  predict [time]       Predict optimal settings (time: 'now', '14:00', etc.)"
    echo "  recommendations      Generate current recommendations"
    echo "  dashboard            Show intelligent system dashboard"
    echo
    echo "Optimization Commands:"
    echo "  auto-optimize        Apply automatic optimizations"
    echo "  optimize-now         Full optimization cycle"
    echo
    echo "Examples:"
    echo "  smart-optimizer dashboard"
    echo "  smart-optimizer predict 15:30"
    echo "  smart-optimizer auto-optimize"
    echo "  smart-optimizer train"
    echo
    echo "Features:"
    echo "  • Machine learning-based pattern recognition"
    echo "  • Predictive system optimization"
    echo "  • Intelligent resource management"
    echo "  • Usage pattern analysis"
    echo "  • Automated performance tuning"
    echo "  • Smart power management"
    echo
}

# Main execution
setup_dirs
init_data_structures

case "${1:-dashboard}" in
    collect) collect_usage_data ;;
    analyze) analyze_patterns ;;
    train) train_model ;;
    predict) predict_optimal_settings "$2" ;;
    recommendations) generate_recommendations ;;
    dashboard) show_dashboard ;;
    auto-optimize) apply_auto_optimizations ;;
    optimize-now) 
        train_model
        apply_auto_optimizations
        show_dashboard
        ;;
    help|*) show_help ;;
esac
