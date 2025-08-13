#!/bin/bash
# System Maintenance & Health Manager
# Comprehensive system cleanup, health monitoring, and package management

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
CONFIG_DIR="$HOME/.config/hypr/maintenance"
LOGS_DIR="$CONFIG_DIR/logs"
BACKUP_DIR="$CONFIG_DIR/backups"
REPORTS_DIR="$CONFIG_DIR/reports"

# Thresholds
DISK_WARN_THRESHOLD=85
MEMORY_WARN_THRESHOLD=80
CPU_WARN_THRESHOLD=75
TEMP_WARN_THRESHOLD=70

# Logging
log() { echo -e "${BLUE}[MAINTENANCE]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$LOGS_DIR" "$BACKUP_DIR" "$REPORTS_DIR"
}

# System cleanup
system_cleanup() {
    log "Starting comprehensive system cleanup..."
    local cleaned_space=0
    
    echo -e "${CYAN}=== System Cleanup Report ===${NC}"
    
    # Package cache cleanup
    log "Cleaning package cache..."
    if command -v pacman >/dev/null 2>&1; then
        local cache_before=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')
        sudo pacman -Scc --noconfirm >/dev/null 2>&1
        local cache_after=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}Package cache:${NC} $cache_before → $cache_after"
    elif command -v apt >/dev/null 2>&1; then
        local cache_before=$(du -sh /var/cache/apt 2>/dev/null | awk '{print $1}')
        sudo apt clean >/dev/null 2>&1
        sudo apt autoclean >/dev/null 2>&1
        local cache_after=$(du -sh /var/cache/apt 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}Package cache:${NC} $cache_before → $cache_after"
    fi
    
    # Remove orphaned packages
    log "Removing orphaned packages..."
    if command -v pacman >/dev/null 2>&1; then
        local orphans=$(pacman -Qtdq 2>/dev/null)
        if [ -n "$orphans" ]; then
            echo "$orphans" | sudo pacman -Rns - --noconfirm >/dev/null 2>&1
            echo -e "${GREEN}Orphaned packages:${NC} $(echo "$orphans" | wc -l) removed"
        else
            echo -e "${GREEN}Orphaned packages:${NC} None found"
        fi
    elif command -v apt >/dev/null 2>&1; then
        sudo apt autoremove -y >/dev/null 2>&1
        echo -e "${GREEN}Orphaned packages:${NC} Removed"
    fi
    
    # Clean temporary files
    log "Cleaning temporary files..."
    local temp_before=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    local temp_after=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}Temporary files:${NC} $temp_before → $temp_after"
    
    # Clean user cache
    log "Cleaning user cache..."
    if [ -d "$HOME/.cache" ]; then
        local cache_before=$(du -sh "$HOME/.cache" 2>/dev/null | awk '{print $1}')
        find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null || true
        local cache_after=$(du -sh "$HOME/.cache" 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}User cache:${NC} $cache_before → $cache_after"
    fi
    
    # Clean logs
    log "Cleaning system logs..."
    if command -v journalctl >/dev/null 2>&1; then
        local logs_before=$(journalctl --disk-usage 2>/dev/null | awk '{print $7}' | head -1)
        sudo journalctl --vacuum-time=30d >/dev/null 2>&1
        sudo journalctl --vacuum-size=100M >/dev/null 2>&1
        local logs_after=$(journalctl --disk-usage 2>/dev/null | awk '{print $7}' | head -1)
        echo -e "${GREEN}System logs:${NC} $logs_before → $logs_after"
    fi
    
    # Clean thumbnails
    if [ -d "$HOME/.thumbnails" ]; then
        log "Cleaning thumbnails..."
        local thumb_before=$(du -sh "$HOME/.thumbnails" 2>/dev/null | awk '{print $1}')
        find "$HOME/.thumbnails" -type f -atime +30 -delete 2>/dev/null || true
        local thumb_after=$(du -sh "$HOME/.thumbnails" 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}Thumbnails:${NC} $thumb_before → $thumb_after"
    fi
    
    # Clean browser cache
    log "Cleaning browser cache..."
    local browsers=("google-chrome" "firefox" "chromium")
    for browser in "${browsers[@]}"; do
        local cache_dir=""
        case "$browser" in
            google-chrome) cache_dir="$HOME/.config/google-chrome" ;;
            firefox) cache_dir="$HOME/.mozilla/firefox" ;;
            chromium) cache_dir="$HOME/.config/chromium" ;;
        esac
        
        if [ -d "$cache_dir" ]; then
            find "$cache_dir" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
            find "$cache_dir" -name "*.tmp" -delete 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}Browser cache:${NC} Cleaned"
    
    success "System cleanup completed!"
}

# Health check
health_check() {
    log "Running comprehensive health check..."
    local issues=0
    local warnings=0
    
    echo -e "${CYAN}=== System Health Report ===${NC}"
    
    # Disk space check
    echo -e "${GREEN}Storage Health:${NC}"
    df -h | grep -E "^/dev" | while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        local device=$(echo "$line" | awk '{print $1}')
        
        if [ "$usage" -gt "$DISK_WARN_THRESHOLD" ]; then
            echo -e "  ${RED}⚠️  $device ($mount): ${usage}% - Critical${NC}"
            ((issues++))
        elif [ "$usage" -gt 70 ]; then
            echo -e "  ${YELLOW}⚠️  $device ($mount): ${usage}% - Warning${NC}"
            ((warnings++))
        else
            echo -e "  ${GREEN}✅ $device ($mount): ${usage}% - OK${NC}"
        fi
    done
    
    # Memory check
    echo -e "${GREEN}Memory Health:${NC}"
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$mem_usage" -gt "$MEMORY_WARN_THRESHOLD" ]; then
        echo -e "  ${RED}⚠️  Memory: ${mem_usage}% - High usage${NC}"
        ((issues++))
    else
        echo -e "  ${GREEN}✅ Memory: ${mem_usage}% - OK${NC}"
    fi
    
    # CPU check
    echo -e "${GREEN}CPU Health:${NC}"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    if (( $(echo "$cpu_usage > $CPU_WARN_THRESHOLD" | bc -l) )); then
        echo -e "  ${RED}⚠️  CPU: ${cpu_usage}% - High usage${NC}"
        ((issues++))
    else
        echo -e "  ${GREEN}✅ CPU: ${cpu_usage}% - OK${NC}"
    fi
    
    # Load average check
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load / $cores" | bc)
    if (( $(echo "$load_per_core > 1.5" | bc -l) )); then
        echo -e "  ${RED}⚠️  Load: $load (${load_per_core}/core) - High${NC}"
        ((issues++))
    else
        echo -e "  ${GREEN}✅ Load: $load (${load_per_core}/core) - OK${NC}"
    fi
    
    # Temperature check
    echo -e "${GREEN}Temperature Health:${NC}"
    if command -v sensors >/dev/null 2>&1; then
        local max_temp=$(sensors 2>/dev/null | grep -o '+[0-9]\+\.[0-9]\+°C' | sed 's/+\|°C//g' | sort -n | tail -1)
        if [ -n "$max_temp" ] && (( $(echo "$max_temp > $TEMP_WARN_THRESHOLD" | bc -l) )); then
            echo -e "  ${RED}⚠️  Temperature: ${max_temp}°C - High${NC}"
            ((issues++))
        else
            echo -e "  ${GREEN}✅ Temperature: ${max_temp}°C - OK${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Temperature: Sensors not available${NC}"
    fi
    
    # Service check
    echo -e "${GREEN}Service Health:${NC}"
    local critical_services=("NetworkManager" "systemd-logind")
    for service in "${critical_services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ $service: Active${NC}"
        else
            echo -e "  ${RED}⚠️  $service: Inactive${NC}"
            ((issues++))
        fi
    done
    
    # Disk errors check
    echo -e "${GREEN}Disk Health:${NC}"
    if command -v smartctl >/dev/null 2>&1; then
        for disk in /dev/sd? /dev/nvme?n?; do
            if [ -e "$disk" ]; then
                local health=$(sudo smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
                local disk_name=$(basename "$disk")
                if [ "$health" = "PASSED" ]; then
                    echo -e "  ${GREEN}✅ $disk_name: $health${NC}"
                else
                    echo -e "  ${RED}⚠️  $disk_name: $health${NC}"
                    ((issues++))
                fi
            fi
        done
    else
        echo -e "  ${YELLOW}⚠️  SMART: Not available (install smartmontools)${NC}"
    fi
    
    # Network connectivity check
    echo -e "${GREEN}Network Health:${NC}"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Internet: Connected${NC}"
    else
        echo -e "  ${RED}⚠️  Internet: No connectivity${NC}"
        ((issues++))
    fi
    
    # Security updates check
    echo -e "${GREEN}Security Updates:${NC}"
    if command -v pacman >/dev/null 2>&1; then
        local updates=$(checkupdates 2>/dev/null | wc -l)
        if [ "$updates" -gt 10 ]; then
            echo -e "  ${YELLOW}⚠️  Updates available: $updates${NC}"
            ((warnings++))
        else
            echo -e "  ${GREEN}✅ Updates: $updates available${NC}"
        fi
    fi
    
    # Summary
    echo
    if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
        echo -e "${GREEN}🎉 System health is excellent!${NC}"
    elif [ $issues -eq 0 ]; then
        echo -e "${YELLOW}⚠️  System health is good with $warnings warnings${NC}"
    else
        echo -e "${RED}❌ System health issues detected: $issues critical, $warnings warnings${NC}"
    fi
    
    # Save report
    local report_file="$REPORTS_DIR/health_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "System Health Report"
        echo "Generated: $(date)"
        echo "Issues: $issues"
        echo "Warnings: $warnings"
        echo "========================"
    } > "$report_file"
    log "Health report saved: $report_file"
}

# Package management
manage_packages() {
    local action="$1"
    
    case "$action" in
        update)
            log "Updating package database..."
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy
            elif command -v apt >/dev/null 2>&1; then
                sudo apt update
            fi
            success "Package database updated"
            ;;
        upgrade)
            log "Upgrading system packages..."
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -Syu --noconfirm
            elif command -v apt >/dev/null 2>&1; then
                sudo apt upgrade -y
            fi
            success "System packages upgraded"
            ;;
        autoremove)
            log "Removing orphaned packages..."
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || echo "No orphaned packages"
            elif command -v apt >/dev/null 2>&1; then
                sudo apt autoremove -y
            fi
            success "Orphaned packages removed"
            ;;
        list-updates)
            log "Checking for available updates..."
            if command -v pacman >/dev/null 2>&1; then
                checkupdates || echo "No updates available"
            elif command -v apt >/dev/null 2>&1; then
                apt list --upgradable
            fi
            ;;
        *)
            echo "Package management options:"
            echo "  update       - Update package database"
            echo "  upgrade      - Upgrade system packages"
            echo "  autoremove   - Remove orphaned packages"
            echo "  list-updates - List available updates"
            ;;
    esac
}

# Log analysis
analyze_logs() {
    log "Analyzing system logs..."
    
    echo -e "${CYAN}=== Log Analysis Report ===${NC}"
    
    # Journal errors
    if command -v journalctl >/dev/null 2>&1; then
        echo -e "${GREEN}Recent Errors (last 24h):${NC}"
        local error_count=$(journalctl --since "24 hours ago" --priority=err --no-pager | wc -l)
        echo "  Error messages: $error_count"
        
        if [ "$error_count" -gt 0 ]; then
            echo "  Top errors:"
            journalctl --since "24 hours ago" --priority=err --no-pager | \
                awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | \
                sort | uniq -c | sort -nr | head -5 | \
                sed 's/^/    /'
        fi
    fi
    
    # Failed services
    echo -e "${GREEN}Failed Services:${NC}"
    local failed_services=$(systemctl --failed --no-legend | wc -l)
    if [ "$failed_services" -gt 0 ]; then
        echo "  Failed units: $failed_services"
        systemctl --failed --no-legend | sed 's/^/    /'
    else
        echo "  No failed services"
    fi
    
    # Disk usage trends
    echo -e "${GREEN}Disk Usage Trends:${NC}"
    df -h | grep -E "^/dev" | while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}')
        local mount=$(echo "$line" | awk '{print $6}')
        echo "  $mount: $usage"
    done
}

# System optimization
optimize_system() {
    log "Optimizing system performance..."
    
    # Update font cache
    log "Updating font cache..."
    fc-cache -fv >/dev/null 2>&1
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        log "Updating desktop database..."
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi
    
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
        log "Updating MIME database..."
        update-mime-database ~/.local/share/mime/ 2>/dev/null || true
    fi
    
    # Trim SSDs
    if command -v fstrim >/dev/null 2>&1; then
        log "Trimming SSDs..."
        sudo fstrim -av >/dev/null 2>&1 || true
    fi
    
    # Update locate database
    if command -v updatedb >/dev/null 2>&1; then
        log "Updating locate database..."
        sudo updatedb >/dev/null 2>&1 || true
    fi
    
    success "System optimization completed"
}

# Create maintenance schedule
schedule_maintenance() {
    local interval="${1:-weekly}"
    
    log "Setting up maintenance schedule: $interval"
    
    # Create systemd service
    local service_file="$HOME/.config/systemd/user/system-maintenance.service"
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=System Maintenance Service
After=network.target

[Service]
Type=oneshot
ExecStart=$0 auto-maintenance
EOF
    
    # Create timer
    local timer_file="$HOME/.config/systemd/user/system-maintenance.timer"
    
    local timer_spec
    case "$interval" in
        daily) timer_spec="daily" ;;
        weekly) timer_spec="weekly" ;;
        monthly) timer_spec="monthly" ;;
        *) timer_spec="weekly" ;;
    esac
    
    cat > "$timer_file" << EOF
[Unit]
Description=System Maintenance Timer
Requires=system-maintenance.service

[Timer]
OnCalendar=$timer_spec
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable timer
    systemctl --user daemon-reload
    systemctl --user enable system-maintenance.timer
    systemctl --user start system-maintenance.timer
    
    success "Maintenance scheduled: $interval"
}

# Auto maintenance routine
auto_maintenance() {
    log "Running automated maintenance routine..."
    
    local report_file="$REPORTS_DIR/auto_maintenance_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Automated Maintenance Report"
        echo "Generated: $(date)"
        echo "========================="
        echo
        
        # Run cleanup
        echo "=== CLEANUP ==="
        system_cleanup
        echo
        
        # Run health check
        echo "=== HEALTH CHECK ==="
        health_check
        echo
        
        # Optimize system
        echo "=== OPTIMIZATION ==="
        optimize_system
        echo
        
        # Package updates
        echo "=== PACKAGE MANAGEMENT ==="
        manage_packages update
        manage_packages autoremove
        
    } | tee "$report_file"
    
    success "Automated maintenance completed. Report: $report_file"
}

# Show system information
show_system_info() {
    echo -e "${CYAN}=== System Information ===${NC}"
    
    # Basic info
    echo -e "${GREEN}Hostname:${NC} $(hostname)"
    echo -e "${GREEN}Kernel:${NC} $(uname -r)"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p)"
    echo -e "${GREEN}Architecture:${NC} $(uname -m)"
    
    # OS info
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo -e "${GREEN}Distribution:${NC} $NAME $VERSION"
    fi
    
    # Hardware info
    echo -e "${GREEN}CPU:${NC} $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')"
    echo -e "${GREEN}CPU Cores:${NC} $(nproc)"
    echo -e "${GREEN}Memory:${NC} $(free -h | grep Mem | awk '{print $2}')"
    
    # Disk info
    echo -e "${GREEN}Disk Usage:${NC}"
    df -h | grep -E "^/dev" | awk '{print "  " $1 ": " $3 "/" $2 " (" $5 ")"}'
}

# Show help
show_help() {
    echo "Usage: system-maintenance [command] [options]"
    echo
    echo "Maintenance Commands:"
    echo "  cleanup              Comprehensive system cleanup"
    echo "  health-check         Run system health diagnostics"
    echo "  optimize             Optimize system performance"
    echo "  auto-maintenance     Run full automated maintenance"
    echo
    echo "Package Management:"
    echo "  packages [action]    Manage packages (update/upgrade/autoremove/list-updates)"
    echo
    echo "Analysis Commands:"
    echo "  analyze-logs         Analyze system logs for issues"
    echo "  system-info          Show detailed system information"
    echo
    echo "Scheduling Commands:"
    echo "  schedule [interval]  Schedule automated maintenance (daily/weekly/monthly)"
    echo
    echo "Examples:"
    echo "  system-maintenance cleanup"
    echo "  system-maintenance health-check"
    echo "  system-maintenance packages upgrade"
    echo "  system-maintenance schedule weekly"
    echo
    echo "Features:"
    echo "  • Comprehensive system cleanup and optimization"
    echo "  • Health monitoring with configurable thresholds"
    echo "  • Automated package management"
    echo "  • Log analysis and error detection"
    echo "  • Scheduled maintenance with systemd timers"
    echo "  • Detailed reporting and history tracking"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    cleanup) system_cleanup ;;
    health-check) health_check ;;
    optimize) optimize_system ;;
    auto-maintenance) auto_maintenance ;;
    packages) manage_packages "$2" ;;
    analyze-logs) analyze_logs ;;
    system-info) show_system_info ;;
    schedule) schedule_maintenance "$2" ;;
    help|*) show_help ;;
esac
