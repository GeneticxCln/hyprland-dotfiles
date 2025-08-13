#!/bin/bash
# AI Manager - Master Control for AI-Powered System Automation
# Orchestrates smart optimization, predictive maintenance, and workload automation

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
SCRIPTS_DIR="$HOME/.config/hypr/scripts/ai"
CONFIG_DIR="$HOME/.config/hypr/ai-manager"
STATE_FILE="$CONFIG_DIR/ai_state.json"
LOG_FILE="$CONFIG_DIR/ai_manager.log"

# AI System Scripts
SMART_OPTIMIZER="$SCRIPTS_DIR/smart-optimizer.sh"
PREDICTIVE_MAINTENANCE="$SCRIPTS_DIR/predictive-maintenance.sh"
WORKLOAD_AUTOMATION="$SCRIPTS_DIR/workload-automation.sh"

# Logging
log() { echo -e "${BLUE}[AI-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
info() { echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
}

# Initialize AI systems
init_ai_systems() {
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
    "ai_systems": {
        "smart_optimizer": {
            "enabled": true,
            "status": "initialized",
            "last_run": 0,
            "errors": 0
        },
        "predictive_maintenance": {
            "enabled": true,
            "status": "initialized", 
            "last_run": 0,
            "errors": 0
        },
        "workload_automation": {
            "enabled": true,
            "status": "initialized",
            "last_run": 0,
            "errors": 0
        }
    },
    "global_settings": {
        "auto_start": true,
        "error_threshold": 3,
        "health_check_interval": 300,
        "coordination_enabled": true
    },
    "coordination": {
        "optimization_priority": "workload_automation",
        "conflict_resolution": "smart",
        "data_sharing": true
    }
}
EOF
    fi
}

# Health check for AI systems
health_check() {
    log "Performing AI systems health check..."
    
    local health_status=()
    local overall_health="healthy"
    
    # Check smart optimizer
    if [ -f "$SMART_OPTIMIZER" ] && [ -x "$SMART_OPTIMIZER" ]; then
        local optimizer_status=$("$SMART_OPTIMIZER" dashboard 2>/dev/null | grep -q "Smart System Dashboard" && echo "healthy" || echo "unhealthy")
        health_status+=("smart_optimizer:$optimizer_status")
        
        if [ "$optimizer_status" = "unhealthy" ]; then
            overall_health="degraded"
        fi
    else
        health_status+=("smart_optimizer:missing")
        overall_health="critical"
    fi
    
    # Check predictive maintenance
    if [ -f "$PREDICTIVE_MAINTENANCE" ] && [ -x "$PREDICTIVE_MAINTENANCE" ]; then
        local maintenance_status=$("$PREDICTIVE_MAINTENANCE" dashboard 2>/dev/null | grep -q "Predictive Maintenance Dashboard" && echo "healthy" || echo "unhealthy")
        health_status+=("predictive_maintenance:$maintenance_status")
        
        if [ "$maintenance_status" = "unhealthy" ]; then
            overall_health="degraded"
        fi
    else
        health_status+=("predictive_maintenance:missing")
        overall_health="critical"
    fi
    
    # Check workload automation
    if [ -f "$WORKLOAD_AUTOMATION" ] && [ -x "$WORKLOAD_AUTOMATION" ]; then
        local workload_status=$("$WORKLOAD_AUTOMATION" dashboard 2>/dev/null | grep -q "Workload Automation Dashboard" && echo "healthy" || echo "unhealthy")
        health_status+=("workload_automation:$workload_status")
        
        if [ "$workload_status" = "unhealthy" ]; then
            overall_health="degraded"
        fi
    else
        health_status+=("workload_automation:missing")
        overall_health="critical"
    fi
    
    # Update state file with health information
    local updated_state=$(cat "$STATE_FILE" | jq --arg status "$overall_health" --argjson timestamp "$(date +%s)" '
    .global_settings.last_health_check = $timestamp |
    .global_settings.overall_health = $status
    ')
    echo "$updated_state" > "$STATE_FILE"
    
    # Report health status
    case "$overall_health" in
        "healthy") 
            success "All AI systems are healthy"
            return 0
            ;;
        "degraded")
            warning "Some AI systems are experiencing issues"
            return 1
            ;;
        "critical")
            error "Critical AI systems are missing or failing"
            return 2
            ;;
    esac
}

# Start all AI systems
start_all_systems() {
    log "Starting all AI systems..."
    
    local started_count=0
    local state=$(cat "$STATE_FILE")
    
    # Start Smart Optimizer
    local smart_enabled=$(echo "$state" | jq -r '.ai_systems.smart_optimizer.enabled')
    if [ "$smart_enabled" = "true" ]; then
        log "Starting Smart Optimizer learning..."
        if "$SMART_OPTIMIZER" train >/dev/null 2>&1; then
            info "✓ Smart Optimizer initialized"
            ((started_count++))
        else
            error "✗ Smart Optimizer failed to start"
        fi
    fi
    
    # Start Predictive Maintenance
    local maintenance_enabled=$(echo "$state" | jq -r '.ai_systems.predictive_maintenance.enabled')
    if [ "$maintenance_enabled" = "true" ]; then
        log "Starting Predictive Maintenance monitoring..."
        if "$PREDICTIVE_MAINTENANCE" schedule >/dev/null 2>&1; then
            info "✓ Predictive Maintenance scheduled"
            ((started_count++))
        else
            warning "✗ Predictive Maintenance scheduling failed"
        fi
    fi
    
    # Start Workload Automation
    local workload_enabled=$(echo "$state" | jq -r '.ai_systems.workload_automation.enabled')
    if [ "$workload_enabled" = "true" ]; then
        log "Starting Workload Automation..."
        if "$WORKLOAD_AUTOMATION" schedule >/dev/null 2>&1; then
            info "✓ Workload Automation scheduled"
            ((started_count++))
        else
            warning "✗ Workload Automation scheduling failed"
        fi
    fi
    
    success "Started $started_count AI systems"
}

# Stop all AI systems
stop_all_systems() {
    log "Stopping all AI systems..."
    
    # Stop scheduled services
    sudo systemctl stop predictive-maintenance.timer workload-automation.timer 2>/dev/null || true
    
    success "All AI systems stopped"
}

# Coordinated optimization run
run_coordinated_optimization() {
    log "Running coordinated AI optimization..."
    
    local state=$(cat "$STATE_FILE")
    local coordination_enabled=$(echo "$state" | jq -r '.global_settings.coordination_enabled')
    
    if [ "$coordination_enabled" != "true" ]; then
        warning "Coordination is disabled, running systems independently"
        run_independent_systems
        return
    fi
    
    # Step 1: Collect data and analyze patterns
    log "Phase 1: Data Collection and Pattern Analysis"
    "$SMART_OPTIMIZER" collect 2>/dev/null || warning "Smart optimizer data collection failed"
    "$PREDICTIVE_MAINTENANCE" health 2>/dev/null || warning "Health metrics collection failed"
    
    # Step 2: Analyze and predict
    log "Phase 2: Analysis and Prediction"
    "$SMART_OPTIMIZER" analyze 2>/dev/null || warning "Pattern analysis failed"
    "$PREDICTIVE_MAINTENANCE" predict 2>/dev/null || warning "Failure prediction failed"
    
    # Step 3: Detect current workload
    log "Phase 3: Workload Detection"
    local workload_detection=$("$WORKLOAD_AUTOMATION" detect 2>/dev/null || echo '{"workload": "unknown", "confidence": 0}')
    local current_workload=$(echo "$workload_detection" | jq -r '.workload')
    local workload_confidence=$(echo "$workload_detection" | jq -r '.confidence')
    
    info "Detected workload: $current_workload (confidence: $(echo "scale=0; $workload_confidence * 100" | bc)%)"
    
    # Step 4: Coordinated optimization based on workload
    log "Phase 4: Coordinated Optimization"
    
    # Apply workload-specific optimizations
    if [ "$current_workload" != "unknown" ]; then
        "$WORKLOAD_AUTOMATION" apply "$current_workload" 2>/dev/null || warning "Workload application failed"
    fi
    
    # Run smart optimizations (non-conflicting)
    "$SMART_OPTIMIZER" auto-optimize 2>/dev/null || warning "Smart optimization failed"
    
    # Run predictive maintenance (safe optimizations only during active workloads)
    if [ "$current_workload" = "idle" ]; then
        "$PREDICTIVE_MAINTENANCE" maintain 2>/dev/null || warning "Predictive maintenance failed"
    else
        log "Skipping invasive maintenance during $current_workload workload"
    fi
    
    # Step 5: Generate recommendations
    log "Phase 5: Generating Recommendations"
    "$SMART_OPTIMIZER" recommendations 2>/dev/null || true
    
    success "Coordinated optimization completed"
}

# Run systems independently
run_independent_systems() {
    log "Running AI systems independently..."
    
    # Run each system in background
    "$SMART_OPTIMIZER" optimize-now >/dev/null 2>&1 &
    "$PREDICTIVE_MAINTENANCE" monitor >/dev/null 2>&1 &
    "$WORKLOAD_AUTOMATION" monitor >/dev/null 2>&1 &
    
    # Wait for completion
    wait
    
    success "Independent system runs completed"
}

# Show comprehensive AI dashboard
show_ai_dashboard() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    AI Systems Dashboard                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    local state=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
    
    # Overall system status
    echo -e "${GREEN}AI System Status:${NC}"
    local overall_health=$(echo "$state" | jq -r '.global_settings.overall_health // "unknown"')
    case "$overall_health" in
        "healthy") echo -e "  Overall Health: ${GREEN}●${NC} Healthy" ;;
        "degraded") echo -e "  Overall Health: ${YELLOW}●${NC} Degraded" ;;
        "critical") echo -e "  Overall Health: ${RED}●${NC} Critical" ;;
        *) echo -e "  Overall Health: ${YELLOW}●${NC} Unknown" ;;
    esac
    
    local coordination_enabled=$(echo "$state" | jq -r '.global_settings.coordination_enabled // false')
    echo -e "  Coordination: $([ "$coordination_enabled" = "true" ] && echo -e "${GREEN}Enabled${NC}" || echo -e "${YELLOW}Disabled${NC}")"
    
    # Individual system status
    echo -e "\n${GREEN}System Components:${NC}"
    
    # Smart Optimizer status
    if [ -f "$SMART_OPTIMIZER" ]; then
        echo -e "  ${GREEN}●${NC} Smart Optimizer - Available"
        local optimizer_data_dir="$HOME/.config/hypr/ai-optimizer"
        if [ -d "$optimizer_data_dir" ]; then
            local record_count=$(find "$optimizer_data_dir/logs" -name "usage_*.json" 2>/dev/null | wc -l)
            echo -e "    Learning Data: $record_count days of usage patterns"
        fi
    else
        echo -e "  ${RED}●${NC} Smart Optimizer - Missing"
    fi
    
    # Predictive Maintenance status
    if [ -f "$PREDICTIVE_MAINTENANCE" ]; then
        echo -e "  ${GREEN}●${NC} Predictive Maintenance - Available"
        if systemctl is-active predictive-maintenance.timer >/dev/null 2>&1; then
            echo -e "    Monitoring: ${GREEN}Active${NC} (automated)"
        else
            echo -e "    Monitoring: ${YELLOW}Manual${NC}"
        fi
    else
        echo -e "  ${RED}●${NC} Predictive Maintenance - Missing"
    fi
    
    # Workload Automation status  
    if [ -f "$WORKLOAD_AUTOMATION" ]; then
        echo -e "  ${GREEN}●${NC} Workload Automation - Available"
        if systemctl is-active workload-automation.timer >/dev/null 2>&1; then
            echo -e "    Automation: ${GREEN}Active${NC}"
            # Show current workload if available
            local workload_state_file="$HOME/.config/hypr/workload-automation/state/automation_state.json"
            if [ -f "$workload_state_file" ]; then
                local current_workload=$(cat "$workload_state_file" | jq -r '.current_workload // "unknown"')
                echo -e "    Current Workload: ${MAGENTA}$current_workload${NC}"
            fi
        else
            echo -e "    Automation: ${YELLOW}Manual${NC}"
        fi
    else
        echo -e "  ${RED}●${NC} Workload Automation - Missing"
    fi
    
    # Recent activity summary
    echo -e "\n${GREEN}Recent AI Activity:${NC}"
    
    # Check for recent optimizer activity
    local optimizer_log="$HOME/.config/hypr/ai-optimizer/logs"
    if [ -d "$optimizer_log" ]; then
        local recent_optimizations=$(find "$optimizer_log" -name "usage_*.json" -mtime -1 2>/dev/null | wc -l)
        echo -e "  Smart Optimizer: $recent_optimizations recent learning sessions"
    fi
    
    # Check for maintenance alerts
    local maintenance_alerts="$HOME/.config/hypr/predictive-maintenance/alerts"
    if [ -d "$maintenance_alerts" ]; then
        local recent_alerts=$(find "$maintenance_alerts" -name "alerts_*.json" -mtime -1 2>/dev/null | xargs cat 2>/dev/null | wc -l)
        echo -e "  Maintenance Alerts: $recent_alerts in last 24 hours"
    fi
    
    # Performance metrics
    echo -e "\n${GREEN}System Performance:${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo -e "  CPU: ${cpu_usage}%"
    echo -e "  Memory: ${memory_usage}%"
    echo -e "  Load Average: $load_avg"
    
    # Quick actions
    echo -e "\n${GREEN}Quick Actions:${NC}"
    echo -e "  ${CYAN}ai-manager optimize${NC}  - Run coordinated optimization"
    echo -e "  ${CYAN}ai-manager health${NC}    - Check system health"
    echo -e "  ${CYAN}ai-manager start${NC}     - Start all AI systems"
}

# Interactive AI configuration
configure_ai() {
    echo -e "${CYAN}AI Systems Configuration${NC}"
    echo "Configure each AI system individually or globally:"
    echo
    
    local state=$(cat "$STATE_FILE")
    
    # Global settings
    echo -e "${GREEN}Global Settings:${NC}"
    read -p "Enable system coordination? (y/n) [y]: " coordination
    coordination=${coordination:-y}
    
    read -p "Auto-start AI systems on boot? (y/n) [y]: " autostart
    autostart=${autostart:-y}
    
    # Individual system toggles
    echo -e "\n${GREEN}Individual Systems:${NC}"
    read -p "Enable Smart Optimizer? (y/n) [y]: " smart_opt
    smart_opt=${smart_opt:-y}
    
    read -p "Enable Predictive Maintenance? (y/n) [y]: " pred_maint
    pred_maint=${pred_maint:-y}
    
    read -p "Enable Workload Automation? (y/n) [y]: " workload_auto
    workload_auto=${workload_auto:-y}
    
    # Update configuration
    local updated_config=$(echo "$state" | jq \
        --argjson coordination "$([ "$coordination" = "y" ] && echo true || echo false)" \
        --argjson autostart "$([ "$autostart" = "y" ] && echo true || echo false)" \
        --argjson smart "$([ "$smart_opt" = "y" ] && echo true || echo false)" \
        --argjson maint "$([ "$pred_maint" = "y" ] && echo true || echo false)" \
        --argjson workload "$([ "$workload_auto" = "y" ] && echo true || echo false)" '
        .global_settings.coordination_enabled = $coordination |
        .global_settings.auto_start = $autostart |
        .ai_systems.smart_optimizer.enabled = $smart |
        .ai_systems.predictive_maintenance.enabled = $maint |
        .ai_systems.workload_automation.enabled = $workload
    ')
    
    echo "$updated_config" > "$STATE_FILE"
    success "AI configuration updated"
}

# Emergency AI system recovery
emergency_recovery() {
    error "Initiating emergency AI system recovery..."
    
    # Stop all AI services
    stop_all_systems
    
    # Reset to safe defaults
    cat > "$STATE_FILE" << 'EOF'
{
    "ai_systems": {
        "smart_optimizer": {"enabled": false, "status": "recovery"},
        "predictive_maintenance": {"enabled": false, "status": "recovery"},
        "workload_automation": {"enabled": false, "status": "recovery"}
    },
    "global_settings": {
        "coordination_enabled": false,
        "emergency_mode": true
    }
}
EOF
    
    # Apply safe system settings
    echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    
    warning "AI systems are in emergency recovery mode"
    echo "Run 'ai-manager health' to check status and 'ai-manager configure' to re-enable systems"
}

# Show help
show_help() {
    echo "Usage: ai-manager [command] [options]"
    echo
    echo "Control Commands:"
    echo "  dashboard            Show comprehensive AI systems dashboard"
    echo "  start               Start all enabled AI systems"
    echo "  stop                Stop all AI systems"
    echo "  restart             Restart all AI systems"
    echo "  optimize            Run coordinated AI optimization"
    echo
    echo "Monitoring Commands:"
    echo "  health              Check health of all AI systems"
    echo "  status              Show current status and configuration"
    echo "  logs                Show recent AI system logs"
    echo
    echo "Configuration Commands:"
    echo "  configure           Interactive AI systems configuration"
    echo "  enable <system>     Enable specific AI system"
    echo "  disable <system>    Disable specific AI system"
    echo
    echo "Maintenance Commands:"
    echo "  recovery            Emergency recovery mode"
    echo "  reset               Reset all AI systems to defaults"
    echo "  cleanup             Clean up old logs and data"
    echo
    echo "Individual System Access:"
    echo "  smart <args>        Direct access to Smart Optimizer"
    echo "  maintenance <args>  Direct access to Predictive Maintenance"
    echo "  workload <args>     Direct access to Workload Automation"
    echo
    echo "Examples:"
    echo "  ai-manager dashboard"
    echo "  ai-manager optimize"
    echo "  ai-manager smart dashboard"
    echo "  ai-manager workload apply gaming"
    echo
    echo "Available AI Systems:"
    echo "  • smart_optimizer      - Pattern learning and optimization"
    echo "  • predictive_maintenance - Health monitoring and failure prediction"
    echo "  • workload_automation  - Automatic performance profile switching"
    echo
    echo "Features:"
    echo "  • Coordinated AI system management"
    echo "  • Intelligent conflict resolution"
    echo "  • Emergency recovery capabilities"
    echo "  • Comprehensive monitoring and logging"
    echo "  • Performance analytics and reporting"
    echo
}

# Main execution
setup_dirs
init_ai_systems

case "${1:-dashboard}" in
    dashboard) show_ai_dashboard ;;
    start) start_all_systems ;;
    stop) stop_all_systems ;;
    restart) stop_all_systems && sleep 2 && start_all_systems ;;
    optimize) run_coordinated_optimization ;;
    health) health_check ;;
    status) cat "$STATE_FILE" | jq '.' ;;
    logs) tail -50 "$LOG_FILE" ;;
    configure) configure_ai ;;
    recovery) emergency_recovery ;;
    smart) shift; "$SMART_OPTIMIZER" "$@" ;;
    maintenance) shift; "$PREDICTIVE_MAINTENANCE" "$@" ;;
    workload) shift; "$WORKLOAD_AUTOMATION" "$@" ;;
    help|*) show_help ;;
esac
