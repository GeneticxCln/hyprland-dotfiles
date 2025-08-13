#!/bin/bash
# Advanced System Resource Monitor
# Comprehensive system monitoring for Hyprland

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
REFRESH_RATE=2
WARN_CPU=80
WARN_MEMORY=85
WARN_DISK=90
WARN_TEMP=70

# Logging
log() { echo -e "${BLUE}[MONITOR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Get system info
get_system_info() {
    echo -e "${CYAN}=== System Information ===${NC}"
    echo -e "${GREEN}Hostname:${NC} $(hostname)"
    echo -e "${GREEN}Kernel:${NC} $(uname -r)"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p)"
    echo -e "${GREEN}Architecture:${NC} $(uname -m)"
    if command -v lsb_release >/dev/null 2>&1; then
        echo -e "${GREEN}Distribution:${NC} $(lsb_release -d | cut -f2)"
    fi
    echo
}

# Get CPU info
get_cpu_info() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    local cpu_cores=$(nproc)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    
    echo -e "${CYAN}=== CPU Information ===${NC}"
    echo -e "${GREEN}Model:${NC} $cpu_model"
    echo -e "${GREEN}Cores:${NC} $cpu_cores"
    echo -e "${GREEN}Usage:${NC} $cpu_usage%"
    
    # Color code CPU usage
    if (( $(echo "$cpu_usage > $WARN_CPU" | bc -l) )); then
        echo -e "${RED}WARNING: High CPU usage detected!${NC}"
    fi
    
    echo -e "${GREEN}Load Average:${NC} $load_avg"
    
    # Show per-core usage if available
    if command -v mpstat >/dev/null 2>&1; then
        echo -e "${GREEN}Per-core usage:${NC}"
        mpstat -P ALL 1 1 | grep -E "Average.*[0-9]" | awk '{print "Core " $2 ": " 100-$NF "%"}'
    fi
    echo
}

# Get memory info
get_memory_info() {
    local mem_info=$(free -h)
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local swap_usage=$(free | grep Swap | awk '{if($2>0) printf "%.1f", $3/$2 * 100.0; else print "0.0"}')
    
    echo -e "${CYAN}=== Memory Information ===${NC}"
    echo -e "${GREEN}Memory Usage:${NC} $mem_usage%"
    
    # Color code memory usage
    if (( $(echo "$mem_usage > $WARN_MEMORY" | bc -l) )); then
        echo -e "${RED}WARNING: High memory usage detected!${NC}"
    fi
    
    echo -e "${GREEN}Swap Usage:${NC} $swap_usage%"
    echo "$mem_info" | while read -r line; do
        echo -e "${GREEN}${line}${NC}"
    done
    echo
}

# Get disk info
get_disk_info() {
    echo -e "${CYAN}=== Disk Information ===${NC}"
    df -h | grep -E "^/dev" | while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        local device=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local available=$(echo "$line" | awk '{print $4}')
        
        echo -e "${GREEN}$device${NC} mounted on ${GREEN}$mount${NC}"
        echo -e "  Size: $size | Used: $used ($usage%) | Available: $available"
        
        # Color code disk usage
        if [ "$usage" -gt "$WARN_DISK" ]; then
            echo -e "${RED}  WARNING: Low disk space!${NC}"
        fi
        echo
    done
}

# Get temperature info
get_temperature_info() {
    echo -e "${CYAN}=== Temperature Information ===${NC}"
    
    if command -v sensors >/dev/null 2>&1; then
        sensors | while IFS= read -r line; do
            if [[ $line == *"°C"* ]]; then
                local temp=$(echo "$line" | grep -o '+[0-9]\+\.[0-9]\+°C' | head -1 | sed 's/+\|°C//g')
                echo -e "${GREEN}$line${NC}"
                
                # Check for high temperatures
                if [ -n "$temp" ] && (( $(echo "$temp > $WARN_TEMP" | bc -l) )); then
                    echo -e "${RED}  WARNING: High temperature detected!${NC}"
                fi
            else
                echo -e "${GREEN}$line${NC}"
            fi
        done
    else
        warning "lm-sensors not installed. Install with: sudo pacman -S lm-sensors"
    fi
    echo
}

# Get network info
get_network_info() {
    echo -e "${CYAN}=== Network Information ===${NC}"
    
    # Show active interfaces
    ip -br addr show | grep -E "(UP|UNKNOWN)" | while read -r line; do
        local interface=$(echo "$line" | awk '{print $1}')
        local state=$(echo "$line" | awk '{print $2}')
        local ip=$(echo "$line" | awk '{print $3}' | cut -d'/' -f1)
        
        echo -e "${GREEN}Interface:${NC} $interface (${state})"
        if [ "$ip" != "" ]; then
            echo -e "${GREEN}IP Address:${NC} $ip"
        fi
        
        # Show network statistics if available
        if [ -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
            local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
            local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
            local rx_mb=$((rx_bytes / 1024 / 1024))
            local tx_mb=$((tx_bytes / 1024 / 1024))
            echo -e "${GREEN}RX:${NC} ${rx_mb}MB | ${GREEN}TX:${NC} ${tx_mb}MB"
        fi
        echo
    done
}

# Get process info
get_process_info() {
    echo -e "${CYAN}=== Top Processes ===${NC}"
    echo -e "${GREEN}By CPU usage:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -n +2 | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
    
    echo
    echo -e "${GREEN}By Memory usage:${NC}"
    ps aux --sort=-%mem | head -6 | tail -n +2 | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
    echo
}

# Get GPU info (if available)
get_gpu_info() {
    echo -e "${CYAN}=== GPU Information ===${NC}"
    
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "${GREEN}NVIDIA GPU detected:${NC}"
        nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | while IFS=',' read -r name temp util mem_used mem_total; do
            echo -e "${GREEN}Name:${NC} $name"
            echo -e "${GREEN}Temperature:${NC} ${temp}°C"
            echo -e "${GREEN}Utilization:${NC} ${util}%"
            echo -e "${GREEN}Memory:${NC} ${mem_used}MB / ${mem_total}MB"
        done
    elif lspci | grep -i vga | grep -i amd >/dev/null; then
        echo -e "${GREEN}AMD GPU detected${NC}"
        if command -v radeontop >/dev/null 2>&1; then
            echo "Use 'radeontop' for detailed AMD GPU monitoring"
        fi
    elif lspci | grep -i vga | grep -i intel >/dev/null; then
        echo -e "${GREEN}Intel GPU detected${NC}"
        if command -v intel_gpu_top >/dev/null 2>&1; then
            echo "Use 'intel_gpu_top' for detailed Intel GPU monitoring"
        fi
    else
        echo -e "${YELLOW}No GPU detected or monitoring tools not available${NC}"
    fi
    echo
}

# Show system overview
show_overview() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                    System Resource Monitor                   ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    get_system_info
    get_cpu_info
    get_memory_info
    get_disk_info
    get_temperature_info
    get_network_info
    get_process_info
    get_gpu_info
}

# Continuous monitoring
monitor_continuous() {
    while true; do
        show_overview
        echo -e "${BLUE}Press Ctrl+C to exit. Refreshing in ${REFRESH_RATE}s...${NC}"
        sleep $REFRESH_RATE
    done
}

# Check system health
check_health() {
    local issues=0
    
    echo -e "${CYAN}=== System Health Check ===${NC}"
    
    # Check CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    if (( $(echo "$cpu_usage > $WARN_CPU" | bc -l) )); then
        echo -e "${RED}❌ High CPU usage: $cpu_usage%${NC}"
        ((issues++))
    else
        echo -e "${GREEN}✅ CPU usage normal: $cpu_usage%${NC}"
    fi
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > $WARN_MEMORY" | bc -l) )); then
        echo -e "${RED}❌ High memory usage: $mem_usage%${NC}"
        ((issues++))
    else
        echo -e "${GREEN}✅ Memory usage normal: $mem_usage%${NC}"
    fi
    
    # Check disk usage
    df -h | grep -E "^/dev" | while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        
        if [ "$usage" -gt "$WARN_DISK" ]; then
            echo -e "${RED}❌ Low disk space on $mount: $usage%${NC}"
            ((issues++))
        else
            echo -e "${GREEN}✅ Disk space normal on $mount: $usage%${NC}"
        fi
    done
    
    # Check temperatures
    if command -v sensors >/dev/null 2>&1; then
        local max_temp=$(sensors | grep -o '+[0-9]\+\.[0-9]\+°C' | sed 's/+\|°C//g' | sort -n | tail -1)
        if [ -n "$max_temp" ] && (( $(echo "$max_temp > $WARN_TEMP" | bc -l) )); then
            echo -e "${RED}❌ High temperature detected: ${max_temp}°C${NC}"
            ((issues++))
        else
            echo -e "${GREEN}✅ Temperature normal: ${max_temp}°C${NC}"
        fi
    fi
    
    echo
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}🎉 System health is good!${NC}"
    else
        echo -e "${RED}⚠️  $issues issue(s) detected${NC}"
    fi
}

# Export system report
export_report() {
    local report_file="$HOME/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "System Resource Report"
        echo "Generated: $(date)"
        echo "========================"
        echo
        
        get_system_info
        get_cpu_info
        get_memory_info
        get_disk_info
        get_temperature_info
        get_network_info
        get_process_info
        get_gpu_info
    } > "$report_file"
    
    success "Report saved to: $report_file"
}

# Show help
show_help() {
    echo "Usage: system-monitor [command]"
    echo
    echo "Commands:"
    echo "  overview           Show complete system overview"
    echo "  monitor            Start continuous monitoring"
    echo "  health             Check system health status"
    echo "  cpu                Show CPU information"
    echo "  memory             Show memory information"
    echo "  disk               Show disk information"
    echo "  temp               Show temperature information"
    echo "  network            Show network information"
    echo "  processes          Show top processes"
    echo "  gpu                Show GPU information"
    echo "  export             Export system report"
    echo "  help               Show this help message"
    echo
    echo "Configuration (environment variables):"
    echo "  REFRESH_RATE       Monitoring refresh rate (default: 2s)"
    echo "  WARN_CPU           CPU usage warning threshold (default: 80%)"
    echo "  WARN_MEMORY        Memory usage warning threshold (default: 85%)"
    echo "  WARN_DISK          Disk usage warning threshold (default: 90%)"
    echo "  WARN_TEMP          Temperature warning threshold (default: 70°C)"
    echo
}

# Main execution
case "${1:-overview}" in
    overview) show_overview ;;
    monitor) monitor_continuous ;;
    health) check_health ;;
    cpu) get_cpu_info ;;
    memory) get_memory_info ;;
    disk) get_disk_info ;;
    temp) get_temperature_info ;;
    network) get_network_info ;;
    processes) get_process_info ;;
    gpu) get_gpu_info ;;
    export) export_report ;;
    help|*) show_help ;;
esac
