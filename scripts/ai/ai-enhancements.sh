#!/bin/bash

# AI System Enhancements
# Practical AI features for daily desktop use

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hypr/ai-enhancements"
SCRIPTS_DIR="$HOME/.config/hypr/scripts"

log() { echo -e "${BLUE}[AI-ENH]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Setup
setup_dirs() {
    mkdir -p "$CONFIG_DIR"
}

# Intelligent Theme Switcher based on time and usage
smart_theme_switcher() {
    log "Running intelligent theme selection..."
    
    local hour=$(date +%H)
    local theme=""
    
    # Check if gaming mode is active
    if pgrep -f "steam\|lutris\|heroic" > /dev/null; then
        # Gaming: Use dark themes for less eye strain
        case $((hour % 4)) in
            0) theme="tokyonight-night" ;;
            1) theme="dracula" ;;
            2) theme="gruvbox-dark" ;;
            3) theme="catppuccin-mocha" ;;
        esac
        log "Gaming detected - applying dark theme: $theme"
    elif pgrep -f "code\|nvim\|vim" > /dev/null; then
        # Development: Use comfortable coding themes
        case $((hour % 3)) in
            0) theme="monokai-pro" ;;
            1) theme="tokyonight-storm" ;;
            2) theme="catppuccin-macchiato" ;;
        esac
        log "Development detected - applying coding theme: $theme"
    else
        # Time-based themes for general use
        if [ "$hour" -lt 6 ] || [ "$hour" -gt 20 ]; then
            # Night time - dark themes
            local dark_themes=("catppuccin-mocha" "tokyonight-night" "dracula" "gruvbox-dark" "everforest-dark")
            theme="${dark_themes[$((hour % ${#dark_themes[@]}))]}"
        elif [ "$hour" -lt 12 ]; then
            # Morning - light/fresh themes
            local morning_themes=("catppuccin-latte" "rose-pine-dawn" "solarized-light" "everforest-light")
            theme="${morning_themes[$((hour % ${#morning_themes[@]}))]}"
        elif [ "$hour" -lt 18 ]; then
            # Afternoon - balanced themes
            local balanced_themes=("catppuccin-macchiato" "tokyonight-storm" "nord" "gruvbox-light")
            theme="${balanced_themes[$((hour % ${#balanced_themes[@]}))]}"
        else
            # Evening - warm themes
            local evening_themes=("rose-pine" "catppuccin-frappe" "gruvbox-dark" "monokai-pro")
            theme="${evening_themes[$((hour % ${#evening_themes[@]}))]}"
        fi
        log "Time-based theme selection: $theme"
    fi
    
    # Apply the selected theme
    if [ -n "$theme" ] && [ -f "$SCRIPTS_DIR/../theme-switcher.sh" ]; then
        "$SCRIPTS_DIR/../theme-switcher.sh" "$theme" &>/dev/null
        success "Applied theme: $theme"
    fi
}

# Automatic system cleanup based on usage patterns
smart_cleanup() {
    log "Running intelligent system cleanup..."
    
    local cleanup_actions=0
    
    # Clean package cache if it's large
    local cache_size=$(du -sm /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "0")
    if [ "$cache_size" -gt 1000 ]; then
        log "Large package cache detected (${cache_size}MB) - cleaning..."
        sudo pacman -Sc --noconfirm &>/dev/null
        ((cleanup_actions++))
    fi
    
    # Clean old log files
    if [ -d "$HOME/.config/hypr" ]; then
        local old_logs=$(find "$HOME/.config/hypr" -name "*.log" -mtime +7 2>/dev/null | wc -l)
        if [ "$old_logs" -gt 0 ]; then
            log "Cleaning $old_logs old log files..."
            find "$HOME/.config/hypr" -name "*.log" -mtime +7 -delete 2>/dev/null
            ((cleanup_actions++))
        fi
    fi
    
    # Clean browser cache if too large
    local browser_cache=""
    if [ -d "$HOME/.cache/mozilla" ]; then
        local mozilla_size=$(du -sm "$HOME/.cache/mozilla" 2>/dev/null | cut -f1 || echo "0")
        if [ "$mozilla_size" -gt 500 ]; then
            log "Large Firefox cache (${mozilla_size}MB) - suggesting cleanup"
            browser_cache="firefox"
        fi
    fi
    
    # Clean tmp files
    local tmp_files=$(find /tmp -user $(whoami) -type f -mtime +1 2>/dev/null | wc -l)
    if [ "$tmp_files" -gt 100 ]; then
        log "Cleaning $tmp_files old temporary files..."
        find /tmp -user $(whoami) -type f -mtime +1 -delete 2>/dev/null || true
        ((cleanup_actions++))
    fi
    
    success "System cleanup completed - $cleanup_actions actions performed"
    
    if [ -n "$browser_cache" ]; then
        warning "Consider clearing $browser_cache cache manually (${mozilla_size:-unknown}MB)"
    fi
}

# Performance optimization based on current workload
smart_performance_optimization() {
    log "Analyzing system for performance optimizations..."
    
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local optimizations=0
    
    # CPU governor optimization
    if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
        local current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
        
        if pgrep -f "steam\|lutris\|heroic\|wine" > /dev/null; then
            # Gaming detected - use performance governor
            if [ "$current_governor" != "performance" ]; then
                log "Gaming detected - switching to performance governor"
                echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
                ((optimizations++))
            fi
        elif [ "$cpu_usage" -lt 10 ] && [ "$memory_usage" -lt 30 ]; then
            # Low usage - use powersave governor
            if [ "$current_governor" != "powersave" ]; then
                log "Low system usage - switching to powersave governor"
                echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
                ((optimizations++))
            fi
        else
            # Balanced usage - use ondemand governor
            if [ "$current_governor" != "ondemand" ] && [ "$current_governor" != "schedutil" ]; then
                log "Balanced usage - switching to ondemand governor"
                echo "ondemand" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
                ((optimizations++))
            fi
        fi
    fi
    
    # Memory optimization
    if [ "$memory_usage" -gt 80 ]; then
        log "High memory usage detected (${memory_usage}%) - optimizing..."
        
        # Drop caches if safe to do so
        sync
        echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
        ((optimizations++))
        
        # Find memory-heavy processes
        local heavy_procs=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print $11}' | tr '\n' ' ')
        log "Memory-heavy processes: $heavy_procs"
    fi
    
    # IO scheduler optimization
    for disk in $(lsblk -dn -o NAME | grep -v loop); do
        local current_scheduler=$(cat "/sys/block/$disk/queue/scheduler" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' || echo "unknown")
        
        if pgrep -f "steam\|lutris\|heroic" > /dev/null; then
            # Gaming - use mq-deadline for better latency
            if [ "$current_scheduler" != "mq-deadline" ]; then
                log "Setting mq-deadline scheduler for gaming"
                echo "mq-deadline" | sudo tee "/sys/block/$disk/queue/scheduler" >/dev/null 2>&1 || true
                ((optimizations++))
            fi
        elif pgrep -f "code\|nvim\|compile\|make\|cargo" > /dev/null; then
            # Development - use bfq for better interactivity
            if [ "$current_scheduler" != "bfq" ]; then
                log "Setting BFQ scheduler for development"
                echo "bfq" | sudo tee "/sys/block/$disk/queue/scheduler" >/dev/null 2>&1 || true
                ((optimizations++))
            fi
        fi
    done
    
    success "Performance optimization completed - $optimizations optimizations applied"
}

# Smart notification based on usage patterns
smart_notifications() {
    log "Checking for intelligent notifications..."
    
    local hour=$(date +%H)
    local notifications=0
    
    # Break reminder for long sessions
    local session_file="$CONFIG_DIR/session_start"
    if [ ! -f "$session_file" ]; then
        echo "$(date +%s)" > "$session_file"
    else
        local session_start=$(cat "$session_file")
        local current_time=$(date +%s)
        local session_duration=$(( (current_time - session_start) / 3600 ))
        
        if [ "$session_duration" -ge 2 ]; then
            notify-send "💻 Break Reminder" "You've been active for $session_duration hours. Consider taking a break!" 2>/dev/null || true
            echo "$(date +%s)" > "$session_file"  # Reset timer
            ((notifications++))
        fi
    fi
    
    # System health notifications
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$memory_usage" -gt 90 ]; then
        notify-send "⚠️ High Memory Usage" "Memory usage is at ${memory_usage}%. Consider closing some applications." 2>/dev/null || true
        ((notifications++))
    fi
    
    # Disk space warning
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 85 ]; then
        notify-send "💾 Disk Space Warning" "Disk usage is at ${disk_usage}%. Consider cleaning up files." 2>/dev/null || true
        ((notifications++))
    fi
    
    # Theme recommendation based on time
    if [ "$hour" -eq 6 ] || [ "$hour" -eq 18 ]; then
        notify-send "🎨 Theme Suggestion" "Would you like to switch to a theme optimized for this time of day?" 2>/dev/null || true
        ((notifications++))
    fi
    
    if [ "$notifications" -gt 0 ]; then
        success "Sent $notifications intelligent notifications"
    fi
}

# Battery optimization for laptops
smart_battery_management() {
    if [ ! -d "/sys/class/power_supply/BAT"* ] 2>/dev/null; then
        log "No battery detected - skipping battery management"
        return
    fi
    
    log "Optimizing battery usage..."
    
    local battery_level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "100")
    local ac_connected=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1 || echo "1")
    
    if [ "$ac_connected" = "0" ]; then
        # On battery power
        log "On battery power (${battery_level}%) - applying power saving"
        
        # Reduce screen brightness
        if command -v brightnessctl >/dev/null 2>&1; then
            brightnessctl set 60% >/dev/null 2>&1 || true
        fi
        
        # Enable power saving mode
        if command -v powerprofilesctl >/dev/null 2>&1; then
            powerprofilesctl set power-saver 2>/dev/null || true
        fi
        
        # Low battery warning
        if [ "$battery_level" -lt 20 ]; then
            notify-send "🔋 Low Battery" "Battery at ${battery_level}%. Connect charger soon." -u critical 2>/dev/null || true
        fi
    else
        # On AC power
        if command -v powerprofilesctl >/dev/null 2>&1; then
            powerprofilesctl set balanced 2>/dev/null || true
        fi
    fi
}

# Generate daily system report
generate_daily_report() {
    log "Generating daily AI system report..."
    
    local report_file="$CONFIG_DIR/daily_report_$(date +%Y%m%d).json"
    
    # Collect data
    local uptime_hours=$(($(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1) / 3600))
    local avg_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    local avg_memory=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # Count applications used
    local apps_used=$(ps aux --format=comm | sort | uniq | wc -l)
    
    # Generate report
    cat > "$report_file" << EOF
{
    "date": "$(date +%Y-%m-%d)",
    "system_stats": {
        "uptime_hours": $uptime_hours,
        "avg_cpu_usage": $avg_cpu,
        "avg_memory_usage": $avg_memory,
        "applications_used": $apps_used
    },
    "ai_actions": {
        "theme_switches": $(grep -c "Applied theme" "$CONFIG_DIR"/*.log 2>/dev/null || echo "0"),
        "optimizations": $(grep -c "optimizations applied" "$CONFIG_DIR"/*.log 2>/dev/null || echo "0"),
        "notifications": $(grep -c "notifications" "$CONFIG_DIR"/*.log 2>/dev/null || echo "0")
    },
    "recommendations": {
        "peak_usage_time": "$(date +%H):00",
        "suggested_theme": "catppuccin-mocha",
        "optimization_potential": "medium"
    }
}
EOF
    
    success "Daily report generated: $report_file"
}

# Main function dispatcher
case "${1:-help}" in
    theme)
        smart_theme_switcher
        ;;
    cleanup)
        smart_cleanup
        ;;
    optimize)
        smart_performance_optimization
        ;;
    notify)
        smart_notifications
        ;;
    battery)
        smart_battery_management
        ;;
    report)
        generate_daily_report
        ;;
    all)
        setup_dirs
        smart_theme_switcher
        smart_performance_optimization
        smart_cleanup
        smart_notifications
        smart_battery_management
        ;;
    help|*)
        echo "AI System Enhancements"
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  theme      - Intelligent theme switching based on context"
        echo "  cleanup    - Smart system cleanup based on usage patterns"
        echo "  optimize   - Performance optimization for current workload"  
        echo "  notify     - Smart notifications and reminders"
        echo "  battery    - Battery optimization for laptops"
        echo "  report     - Generate daily system report"
        echo "  all        - Run all enhancement functions"
        echo "  help       - Show this help"
        echo
        echo "Examples:"
        echo "  $0 theme     # Switch theme based on time/usage"
        echo "  $0 optimize  # Optimize performance for current workload"
        echo "  $0 all       # Run all AI enhancements"
        ;;
esac
