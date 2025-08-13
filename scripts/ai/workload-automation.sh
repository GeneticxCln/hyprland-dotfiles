#!/bin/bash
# Workload Automation Engine
# Automatically manages system resources based on workload detection and optimization

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
CONFIG_DIR="$HOME/.config/hypr/workload-automation"
PROFILES_DIR="$CONFIG_DIR/profiles"
RULES_DIR="$CONFIG_DIR/rules"
LOGS_DIR="$CONFIG_DIR/logs"
STATE_DIR="$CONFIG_DIR/state"
WORKLOAD_CONFIG="$CONFIG_DIR/workload_config.json"
AUTOMATION_STATE="$STATE_DIR/automation_state.json"
PERFORMANCE_LOG="$LOGS_DIR/performance_log.json"

# Workload detection parameters
MIN_DETECTION_TIME=30  # seconds
WORKLOAD_CONFIDENCE_THRESHOLD=0.7
PROFILE_SWITCH_COOLDOWN=60  # seconds between profile switches

# Logging
log() { echo -e "${BLUE}[WORKLOAD]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR" "$RULES_DIR" "$LOGS_DIR" "$STATE_DIR"
}

# Initialize workload automation system
init_workload_system() {
    if [ ! -f "$WORKLOAD_CONFIG" ]; then
        cat > "$WORKLOAD_CONFIG" << 'EOF'
{
    "enabled": true,
    "auto_detection": true,
    "performance_tracking": true,
    "workload_types": {
        "gaming": {
            "cpu_priority": "performance",
            "gpu_priority": "performance",
            "power_profile": "performance",
            "network_priority": "high",
            "io_scheduler": "mq-deadline",
            "processes_to_suspend": ["firefox", "chrome", "slack", "discord"],
            "services_to_stop": ["packagekit", "updatedb.mlocate"]
        },
        "development": {
            "cpu_priority": "balanced",
            "power_profile": "balanced",
            "network_priority": "medium",
            "io_scheduler": "bfq",
            "memory_optimization": true,
            "swap_aggressiveness": 10
        },
        "media": {
            "cpu_priority": "performance",
            "gpu_priority": "performance", 
            "power_profile": "performance",
            "audio_priority": "high",
            "interrupt_balancing": false
        },
        "productivity": {
            "cpu_priority": "balanced",
            "power_profile": "balanced",
            "memory_optimization": true,
            "background_apps_limit": true
        },
        "idle": {
            "cpu_priority": "powersave",
            "power_profile": "power-saver",
            "suspend_unused_services": true,
            "reduce_refresh_rate": true
        }
    },
    "detection_rules": {
        "gaming": {
            "processes": ["steam", "lutris", "heroic", "bottles", "wine"],
            "gpu_usage_threshold": 70,
            "cpu_usage_threshold": 60,
            "fullscreen_apps": true
        },
        "development": {
            "processes": ["code", "nvim", "vim", "emacs", "jetbrains", "docker", "node", "python", "cargo", "make", "cmake", "gcc", "g++"],
            "cpu_usage_threshold": 40,
            "memory_usage_threshold": 30
        },
        "media": {
            "processes": ["vlc", "mpv", "obs", "kdenlive", "blender", "gimp", "audacity"],
            "gpu_usage_threshold": 50,
            "audio_active": true
        },
        "productivity": {
            "processes": ["libreoffice", "firefox", "chrome", "thunderbird", "zoom", "teams"],
            "cpu_usage_threshold": 30,
            "window_count_threshold": 5
        }
    }
}
EOF
    fi
    
    if [ ! -f "$AUTOMATION_STATE" ]; then
        echo '{"current_workload": "idle", "last_switch": 0, "confidence": 0, "enabled": true}' > "$AUTOMATION_STATE"
    fi
    
    if [ ! -f "$PERFORMANCE_LOG" ]; then
        echo '{"performance_records": [], "workload_history": []}' > "$PERFORMANCE_LOG"
    fi
}

# Detect current workload based on system state
detect_workload() {
    log "Detecting current workload..."
    
    local workload_scores=()
    local config=$(cat "$WORKLOAD_CONFIG")
    
    # Get current system metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
    local memory_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    local gpu_usage=0
    
    # Try to get GPU usage
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1 || echo "0")
    elif command -v radeontop >/dev/null 2>&1; then
        gpu_usage=$(radeontop -d - -l 1 | grep -o "gpu [0-9]*" | awk '{print $2}' | head -1 || echo "0")
    fi
    
    # Get active processes
    local active_processes=$(ps aux --sort=-%cpu | head -20 | awk '{print tolower($11)}' | sed 's|.*/||')
    
    # Get window information
    local window_count=0
    local fullscreen_active=false
    if command -v hyprctl >/dev/null 2>&1; then
        window_count=$(hyprctl clients -j | jq length)
        fullscreen_active=$(hyprctl clients -j | jq 'any(.fullscreen)')
    fi
    
    # Check audio activity
    local audio_active=false
    if command -v pactl >/dev/null 2>&1; then
        audio_active=$(pactl list sink-inputs | grep -q "State: RUNNING" && echo "true" || echo "false")
    fi
    
    # Evaluate each workload type
    for workload in gaming development media productivity idle; do
        local score=0
        local rules=$(echo "$config" | jq -r ".detection_rules.$workload")
        
        # Process-based detection
        local required_processes=$(echo "$rules" | jq -r '.processes[]?' 2>/dev/null || echo "")
        local process_matches=0
        for process in $required_processes; do
            if echo "$active_processes" | grep -q "$process"; then
                ((process_matches++))
                score=$((score + 30))
            fi
        done
        
        # CPU usage threshold
        local cpu_threshold=$(echo "$rules" | jq -r '.cpu_usage_threshold // 0')
        if [ "$cpu_usage" -ge "$cpu_threshold" ] && [ "$cpu_threshold" -gt 0 ]; then
            score=$((score + 20))
        fi
        
        # GPU usage threshold
        local gpu_threshold=$(echo "$rules" | jq -r '.gpu_usage_threshold // 0')
        if [ "$gpu_usage" -ge "$gpu_threshold" ] && [ "$gpu_threshold" -gt 0 ]; then
            score=$((score + 25))
        fi
        
        # Memory usage threshold
        local mem_threshold=$(echo "$rules" | jq -r '.memory_usage_threshold // 0')
        if [ "$memory_usage" -ge "$mem_threshold" ] && [ "$mem_threshold" -gt 0 ]; then
            score=$((score + 15))
        fi
        
        # Fullscreen detection
        local needs_fullscreen=$(echo "$rules" | jq -r '.fullscreen_apps // false')
        if [ "$needs_fullscreen" = "true" ] && [ "$fullscreen_active" = "true" ]; then
            score=$((score + 20))
        fi
        
        # Audio activity
        local needs_audio=$(echo "$rules" | jq -r '.audio_active // false')
        if [ "$needs_audio" = "true" ] && [ "$audio_active" = "true" ]; then
            score=$((score + 15))
        fi
        
        # Window count threshold
        local window_threshold=$(echo "$rules" | jq -r '.window_count_threshold // 0')
        if [ "$window_count" -ge "$window_threshold" ] && [ "$window_threshold" -gt 0 ]; then
            score=$((score + 10))
        fi
        
        # Special handling for idle workload
        if [ "$workload" = "idle" ]; then
            if [ "$cpu_usage" -lt 15 ] && [ "$gpu_usage" -lt 10 ] && [ "$process_matches" -eq 0 ]; then
                score=$((score + 40))
            fi
        fi
        
        workload_scores+=("$workload:$score")
        info "Workload '$workload' score: $score (processes: $process_matches)"
    done
    
    # Find the highest scoring workload
    local best_workload="idle"
    local best_score=0
    local confidence=0
    
    for entry in "${workload_scores[@]}"; do
        local workload=$(echo "$entry" | cut -d':' -f1)
        local score=$(echo "$entry" | cut -d':' -f2)
        
        if [ "$score" -gt "$best_score" ]; then
            best_score=$score
            best_workload=$workload
        fi
    done
    
    # Calculate confidence (normalized score)
    if [ "$best_score" -gt 0 ]; then
        confidence=$(echo "scale=2; $best_score / 100" | bc)
        if (( $(echo "$confidence > 1" | bc -l) )); then
            confidence=1.0
        fi
    fi
    
    # Return results
    cat << EOF
{
    "workload": "$best_workload",
    "confidence": $confidence,
    "score": $best_score,
    "metrics": {
        "cpu": $cpu_usage,
        "gpu": $gpu_usage,
        "memory": $memory_usage,
        "windows": $window_count,
        "fullscreen": $fullscreen_active,
        "audio": $audio_active
    }
}
EOF
}

# Apply workload optimization profile
apply_workload_profile() {
    local workload="$1"
    local force="${2:-false}"
    
    log "Applying $workload workload profile..."
    
    local config=$(cat "$WORKLOAD_CONFIG")
    local profile=$(echo "$config" | jq -r ".workload_types.$workload")
    
    if [ "$profile" = "null" ]; then
        error "Unknown workload type: $workload"
        return 1
    fi
    
    local applied_optimizations=()
    
    # CPU Priority/Governor
    local cpu_priority=$(echo "$profile" | jq -r '.cpu_priority // "balanced"')
    case "$cpu_priority" in
        "performance")
            echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
            applied_optimizations+=("CPU governor set to performance")
            ;;
        "powersave")
            echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
            applied_optimizations+=("CPU governor set to powersave")
            ;;
        "balanced")
            echo "schedutil" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
            applied_optimizations+=("CPU governor set to balanced")
            ;;
    esac
    
    # Power Profile
    local power_profile=$(echo "$profile" | jq -r '.power_profile // "balanced"')
    if command -v powerprofilesctl >/dev/null 2>&1; then
        case "$power_profile" in
            "performance"|"balanced"|"power-saver")
                powerprofilesctl set "$power_profile" 2>/dev/null || true
                applied_optimizations+=("Power profile set to $power_profile")
                ;;
        esac
    fi
    
    # I/O Scheduler
    local io_scheduler=$(echo "$profile" | jq -r '.io_scheduler // ""')
    if [ -n "$io_scheduler" ]; then
        for disk in /sys/block/*/queue/scheduler; do
            if [ -f "$disk" ]; then
                echo "$io_scheduler" | sudo tee "$disk" >/dev/null 2>&1 || true
            fi
        done
        applied_optimizations+=("I/O scheduler set to $io_scheduler")
    fi
    
    # Memory optimization
    local memory_opt=$(echo "$profile" | jq -r '.memory_optimization // false')
    if [ "$memory_opt" = "true" ]; then
        # Adjust swappiness
        local swap_aggr=$(echo "$profile" | jq -r '.swap_aggressiveness // 60')
        echo "$swap_aggr" | sudo tee /proc/sys/vm/swappiness >/dev/null 2>&1 || true
        applied_optimizations+=("Memory optimization enabled (swappiness: $swap_aggr)")
    fi
    
    # Process management
    local processes_to_suspend=$(echo "$profile" | jq -r '.processes_to_suspend[]?' 2>/dev/null || echo "")
    for process in $processes_to_suspend; do
        if pgrep "$process" >/dev/null 2>&1; then
            pkill -STOP "$process" 2>/dev/null || true
            applied_optimizations+=("Suspended process: $process")
        fi
    done
    
    # Service management
    local services_to_stop=$(echo "$profile" | jq -r '.services_to_stop[]?' 2>/dev/null || echo "")
    for service in $services_to_stop; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            sudo systemctl stop "$service" 2>/dev/null || true
            applied_optimizations+=("Stopped service: $service")
        fi
    done
    
    # Gaming-specific optimizations
    if [ "$workload" = "gaming" ]; then
        # Disable CPU idle states for lower latency
        echo 0 | sudo tee /sys/devices/system/cpu/cpu*/cpuidle/state*/disable >/dev/null 2>&1 || true
        
        # Set CPU affinity for better gaming performance
        echo "2-7" | sudo tee /sys/fs/cgroup/cpuset/cpuset.cpus >/dev/null 2>&1 || true
        
        # Enable gaming mode if available
        if [ -f "$HOME/.config/hypr/scripts/gaming/gaming-mode.sh" ]; then
            bash "$HOME/.config/hypr/scripts/gaming/gaming-mode.sh" enable >/dev/null 2>&1 || true
            applied_optimizations+=("Enabled gaming mode optimizations")
        fi
        
        # Set high priority for X/Wayland
        pgrep -f "Xorg\|Hyprland" | xargs -r sudo renice -20 -p 2>/dev/null || true
        applied_optimizations+=("Set high priority for display server")
    fi
    
    # Media-specific optimizations
    if [ "$workload" = "media" ]; then
        # Optimize for media workloads
        echo 1 | sudo tee /proc/sys/kernel/sched_rt_runtime_us >/dev/null 2>&1 || true
        
        # Disable interrupt balancing for better realtime performance
        local interrupt_balancing=$(echo "$profile" | jq -r '.interrupt_balancing // true')
        if [ "$interrupt_balancing" = "false" ]; then
            sudo systemctl stop irqbalance 2>/dev/null || true
            applied_optimizations+=("Disabled interrupt balancing for realtime performance")
        fi
    fi
    
    # Idle-specific optimizations
    if [ "$workload" = "idle" ]; then
        # Resume any suspended processes
        pkill -CONT -f "firefox\|chrome\|slack\|discord" 2>/dev/null || true
        
        # Restart stopped services
        sudo systemctl start packagekit 2>/dev/null || true
        sudo systemctl start irqbalance 2>/dev/null || true
        
        applied_optimizations+=("Restored normal system operation")
    fi
    
    # Log the profile application
    local timestamp=$(date +%s)
    local optimization_record=$(printf '%s\n' "${applied_optimizations[@]}" | jq -R -s '{
        "timestamp": '$timestamp',
        "workload": "'$workload'",
        "optimizations": split("\n")[:-1],
        "forced": '$force'
    }')
    
    # Update performance log
    local updated_log=$(cat "$PERFORMANCE_LOG" | jq --argjson record "$optimization_record" '
    .workload_history += [$record] |
    .workload_history = (.workload_history | if length > 50 then .[1:] else . end)
    ')
    echo "$updated_log" > "$PERFORMANCE_LOG"
    
    success "Applied $workload profile with ${#applied_optimizations[@]} optimizations"
    
    # Update automation state
    local updated_state=$(cat "$AUTOMATION_STATE" | jq --arg workload "$workload" --argjson timestamp "$timestamp" '
    .current_workload = $workload |
    .last_switch = $timestamp
    ')
    echo "$updated_state" > "$AUTOMATION_STATE"
}

# Monitor and automatically adjust workloads
auto_monitor() {
    log "Starting automatic workload monitoring..."
    
    local state=$(cat "$AUTOMATION_STATE")
    local enabled=$(echo "$state" | jq -r '.enabled // true')
    
    if [ "$enabled" != "true" ]; then
        warning "Workload automation is disabled"
        return 1
    fi
    
    local current_workload=$(echo "$state" | jq -r '.current_workload')
    local last_switch=$(echo "$state" | jq -r '.last_switch')
    local current_time=$(date +%s)
    
    # Check cooldown period
    if [ $((current_time - last_switch)) -lt $PROFILE_SWITCH_COOLDOWN ]; then
        info "In cooldown period, skipping workload detection"
        return 0
    fi
    
    # Detect current workload
    local detection_result=$(detect_workload)
    local detected_workload=$(echo "$detection_result" | jq -r '.workload')
    local confidence=$(echo "$detection_result" | jq -r '.confidence')
    
    info "Detected workload: $detected_workload (confidence: $(echo "scale=0; $confidence * 100" | bc)%)"
    
    # Only switch if confidence is high enough and workload is different
    if [ "$detected_workload" != "$current_workload" ]; then
        if (( $(echo "$confidence > $WORKLOAD_CONFIDENCE_THRESHOLD" | bc -l) )); then
            log "Switching from $current_workload to $detected_workload workload"
            apply_workload_profile "$detected_workload"
            
            # Record performance metrics before and after switch
            record_performance_metrics "$detected_workload" "$detection_result"
        else
            info "Confidence too low ($(echo "scale=0; $confidence * 100" | bc)%) for workload switch"
        fi
    else
        info "Workload unchanged ($current_workload), no action needed"
    fi
    
    # Update state with latest detection
    local updated_state=$(echo "$state" | jq --argjson detection "$detection_result" '
    .last_detection = $detection |
    .confidence = $detection.confidence
    ')
    echo "$updated_state" > "$AUTOMATION_STATE"
}

# Record performance metrics
record_performance_metrics() {
    local workload="$1"
    local detection_data="$2"
    
    local timestamp=$(date +%s)
    local metrics=$(echo "$detection_data" | jq '.metrics')
    
    # Additional performance metrics
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local context_switches=$(grep "^ctxt" /proc/stat | awk '{print $2}')
    local interrupts=$(grep "^intr" /proc/stat | awk '{print $2}')
    
    # Create performance record
    local performance_record=$(echo "$metrics" | jq --arg workload "$workload" --argjson timestamp "$timestamp" --argjson load "$load_avg" --argjson ctx "$context_switches" --argjson int "$interrupts" '{
        "timestamp": $timestamp,
        "workload": $workload,
        "cpu_usage": .cpu,
        "gpu_usage": .gpu,
        "memory_usage": .memory,
        "window_count": .windows,
        "fullscreen_active": .fullscreen,
        "audio_active": .audio,
        "load_average": $load,
        "context_switches": $ctx,
        "interrupts": $int
    }')
    
    # Update performance log
    local updated_log=$(cat "$PERFORMANCE_LOG" | jq --argjson record "$performance_record" '
    .performance_records += [$record] |
    .performance_records = (.performance_records | if length > 1000 then .[1:] else . end)
    ')
    echo "$updated_log" > "$PERFORMANCE_LOG"
}

# Show workload automation dashboard
show_dashboard() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             Workload Automation Dashboard             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    
    local state=$(cat "$AUTOMATION_STATE")
    local current_workload=$(echo "$state" | jq -r '.current_workload')
    local confidence=$(echo "$state" | jq -r '.confidence // 0')
    local enabled=$(echo "$state" | jq -r '.enabled // true')
    
    # Current status
    echo -e "${GREEN}Current Status:${NC}"
    echo -e "  Active Workload: ${MAGENTA}$current_workload${NC}"
    echo -e "  Confidence: $(echo "scale=0; $confidence * 100" | bc)%"
    echo -e "  Automation: $([ "$enabled" = "true" ] && echo -e "${GREEN}Enabled${NC}" || echo -e "${RED}Disabled${NC}")"
    
    # Recent detection
    if [ -f "$AUTOMATION_STATE" ]; then
        local last_detection=$(echo "$state" | jq -r '.last_detection // empty')
        if [ -n "$last_detection" ] && [ "$last_detection" != "empty" ]; then
            echo -e "\n${GREEN}Last Detection:${NC}"
            local metrics=$(echo "$last_detection" | jq -r '.metrics')
            echo -e "  CPU Usage: $(echo "$metrics" | jq -r '.cpu')%"
            echo -e "  GPU Usage: $(echo "$metrics" | jq -r '.gpu')%"
            echo -e "  Memory Usage: $(echo "$metrics" | jq -r '.memory')%"
            echo -e "  Windows Open: $(echo "$metrics" | jq -r '.windows')"
            echo -e "  Fullscreen: $(echo "$metrics" | jq -r '.fullscreen')"
            echo -e "  Audio Active: $(echo "$metrics" | jq -r '.audio')"
        fi
    fi
    
    # Workload history
    echo -e "\n${GREEN}Recent Workload Changes:${NC}"
    if [ -f "$PERFORMANCE_LOG" ]; then
        cat "$PERFORMANCE_LOG" | jq -r '.workload_history[-5:][]? | 
        "  " + (.timestamp | strftime("%H:%M:%S")) + " - " + .workload + " (" + (.optimizations | length | tostring) + " optimizations)"' 2>/dev/null || echo "  No recent changes"
    else
        echo "  No workload history available"
    fi
    
    # Performance trends
    echo -e "\n${GREEN}Performance Trends:${NC}"
    if [ -f "$PERFORMANCE_LOG" ]; then
        local avg_cpu=$(cat "$PERFORMANCE_LOG" | jq -r '[.performance_records[-10:][]? | .cpu_usage] | if length > 0 then (add / length | floor) else 0 end')
        local avg_memory=$(cat "$PERFORMANCE_LOG" | jq -r '[.performance_records[-10:][]? | .memory_usage] | if length > 0 then (add / length | floor) else 0 end')
        local avg_load=$(cat "$PERFORMANCE_LOG" | jq -r '[.performance_records[-10:][]? | .load_average] | if length > 0 then (add / length * 100 | floor) / 100 else 0 end')
        
        echo -e "  Average CPU (last 10 records): ${avg_cpu}%"
        echo -e "  Average Memory: ${avg_memory}%"
        echo -e "  Average Load: $avg_load"
    else
        echo "  No performance data available"
    fi
    
    # Available workload profiles
    echo -e "\n${GREEN}Available Workload Profiles:${NC}"
    local config=$(cat "$WORKLOAD_CONFIG")
    echo "$config" | jq -r '.workload_types | keys[]' | while read -r profile; do
        if [ "$profile" = "$current_workload" ]; then
            echo -e "  ${GREEN}● $profile${NC} (active)"
        else
            echo -e "  ○ $profile"
        fi
    done
    
    # Automation status
    echo -e "\n${GREEN}Automation Status:${NC}"
    if systemctl is-active workload-automation.timer >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Automated monitoring active${NC}"
        local next_run=$(systemctl list-timers workload-automation.timer --no-pager | grep workload-automation.timer | awk '{print $1, $2}' | head -1)
        [ -n "$next_run" ] && echo -e "  Next run: $next_run"
    else
        echo -e "  ${YELLOW}⚠️ Automated monitoring not scheduled${NC}"
    fi
}

# Schedule automated workload monitoring
schedule_automation() {
    log "Setting up automated workload monitoring..."
    
    # Create systemd service
    cat > "/tmp/workload-automation.service" << EOF
[Unit]
Description=Workload Automation Engine
After=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=$HOME/.config/hypr/scripts/ai/workload-automation.sh monitor
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create systemd timer
    cat > "/tmp/workload-automation.timer" << EOF
[Unit]
Description=Run Workload Automation every 30 seconds
Requires=workload-automation.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=30sec
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Install systemd files
    sudo cp "/tmp/workload-automation.service" "/etc/systemd/system/"
    sudo cp "/tmp/workload-automation.timer" "/etc/systemd/system/"
    
    # Enable and start timer
    sudo systemctl daemon-reload
    sudo systemctl enable workload-automation.timer
    sudo systemctl start workload-automation.timer
    
    success "Automated workload monitoring scheduled every 30 seconds"
    
    rm -f "/tmp/workload-automation.service" "/tmp/workload-automation.timer"
}

# Create custom workload profile
create_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    log "Creating custom workload profile: $profile_name"
    
    # Interactive profile creation
    echo -e "${CYAN}Creating workload profile '$profile_name'${NC}"
    echo "Please provide the following settings (press Enter for defaults):"
    
    read -p "CPU Priority (performance/balanced/powersave) [balanced]: " cpu_priority
    cpu_priority=${cpu_priority:-balanced}
    
    read -p "Power Profile (performance/balanced/power-saver) [balanced]: " power_profile
    power_profile=${power_profile:-balanced}
    
    read -p "I/O Scheduler (mq-deadline/bfq/none) [none]: " io_scheduler
    io_scheduler=${io_scheduler:-none}
    
    read -p "Enable Memory Optimization? (true/false) [false]: " memory_opt
    memory_opt=${memory_opt:-false}
    
    echo "Detection rules for this workload:"
    read -p "Process names (comma-separated): " processes
    read -p "CPU usage threshold (0-100) [0]: " cpu_threshold
    cpu_threshold=${cpu_threshold:-0}
    read -p "GPU usage threshold (0-100) [0]: " gpu_threshold
    gpu_threshold=${gpu_threshold:-0}
    
    # Create profile JSON
    local profile_config=$(cat << EOF
{
    "cpu_priority": "$cpu_priority",
    "power_profile": "$power_profile",
    "io_scheduler": "$io_scheduler",
    "memory_optimization": $memory_opt
}
EOF
)
    
    local detection_rules=$(cat << EOF
{
    "processes": [$(echo "$processes" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')],
    "cpu_usage_threshold": $cpu_threshold,
    "gpu_usage_threshold": $gpu_threshold
}
EOF
)
    
    # Update main configuration
    local updated_config=$(cat "$WORKLOAD_CONFIG" | jq --arg name "$profile_name" --argjson profile "$profile_config" --argjson rules "$detection_rules" '
    .workload_types[$name] = $profile |
    .detection_rules[$name] = $rules
    ')
    echo "$updated_config" > "$WORKLOAD_CONFIG"
    
    success "Created workload profile '$profile_name'"
}

# Show help
show_help() {
    echo "Usage: workload-automation [command] [options]"
    echo
    echo "Monitoring Commands:"
    echo "  monitor              Perform workload detection and optimization"
    echo "  dashboard            Show automation status and metrics"
    echo "  detect               Detect current workload only"
    echo "  status               Show current automation state"
    echo
    echo "Profile Commands:"
    echo "  apply <workload>     Apply specific workload profile"
    echo "  create <name>        Create custom workload profile"
    echo "  list                 List available workload profiles"
    echo "  reset                Reset to idle workload"
    echo
    echo "Management Commands:"
    echo "  enable               Enable workload automation"
    echo "  disable              Disable workload automation"
    echo "  schedule             Set up automated monitoring"
    echo "  unschedule          Remove automated monitoring"
    echo
    echo "Examples:"
    echo "  workload-automation dashboard"
    echo "  workload-automation apply gaming"
    echo "  workload-automation create streaming"
    echo "  workload-automation schedule"
    echo
    echo "Available Workloads:"
    echo "  • gaming      - High performance for gaming"
    echo "  • development - Optimized for coding and compilation"
    echo "  • media       - Optimized for media creation/playback"
    echo "  • productivity- Balanced for office work"
    echo "  • idle        - Power saving for idle system"
    echo
    echo "Features:"
    echo "  • Automatic workload detection"
    echo "  • Performance optimization profiles"
    echo "  • Resource management automation"
    echo "  • Custom profile creation"
    echo "  • Performance tracking and analytics"
    echo "  • Intelligent process and service management"
    echo
}

# Enable/disable automation
toggle_automation() {
    local action="$1"
    
    if [ "$action" = "enable" ]; then
        local updated_state=$(cat "$AUTOMATION_STATE" | jq '.enabled = true')
        echo "$updated_state" > "$AUTOMATION_STATE"
        success "Workload automation enabled"
    elif [ "$action" = "disable" ]; then
        local updated_state=$(cat "$AUTOMATION_STATE" | jq '.enabled = false')
        echo "$updated_state" > "$AUTOMATION_STATE"
        warning "Workload automation disabled"
    fi
}

# Unschedule automation
unschedule_automation() {
    log "Removing automated workload monitoring..."
    
    sudo systemctl stop workload-automation.timer >/dev/null 2>&1 || true
    sudo systemctl disable workload-automation.timer >/dev/null 2>&1 || true
    sudo rm -f "/etc/systemd/system/workload-automation.timer" || true
    sudo rm -f "/etc/systemd/system/workload-automation.service" || true
    sudo systemctl daemon-reload
    
    success "Automated workload monitoring removed"
}

# Main execution
setup_dirs
init_workload_system

case "${1:-dashboard}" in
    monitor) auto_monitor ;;
    dashboard) show_dashboard ;;
    detect) detect_workload | jq '.' ;;
    status) cat "$AUTOMATION_STATE" | jq '.' ;;
    apply) 
        if [ -n "$2" ]; then
            apply_workload_profile "$2" true
        else
            error "Workload name required"
        fi
        ;;
    create)
        if [ -n "$2" ]; then
            create_profile "$2"
        else
            error "Profile name required"
        fi
        ;;
    list) 
        echo "Available workload profiles:"
        cat "$WORKLOAD_CONFIG" | jq -r '.workload_types | keys[]' | sed 's/^/  /'
        ;;
    reset) apply_workload_profile "idle" true ;;
    enable) toggle_automation "enable" ;;
    disable) toggle_automation "disable" ;;
    schedule) schedule_automation ;;
    unschedule) unschedule_automation ;;
    help|*) show_help ;;
esac
