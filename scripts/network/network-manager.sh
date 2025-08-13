#!/bin/bash
# Advanced Network & Connectivity Manager
# Comprehensive WiFi, Bluetooth, and network management for Hyprland

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
CONFIG_DIR="$HOME/.config/hypr/network"
PROFILES_DIR="$CONFIG_DIR/profiles"
HOTSPOT_DIR="$CONFIG_DIR/hotspot"

# Logging
log() { echo -e "${BLUE}[NETWORK]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR" "$HOTSPOT_DIR"
}

# Network status overview
network_status() {
    echo -e "${CYAN}=== Network Status Overview ===${NC}"
    
    # General connectivity
    echo -e "${GREEN}Connectivity:${NC}"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Internet: Connected${NC}"
    else
        echo -e "  ${RED}❌ Internet: No connectivity${NC}"
    fi
    
    # Network interfaces
    echo -e "${GREEN}Network Interfaces:${NC}"
    ip -br addr show | while read -r line; do
        local interface=$(echo "$line" | awk '{print $1}')
        local state=$(echo "$line" | awk '{print $2}')
        local ip=$(echo "$line" | awk '{print $3}' | cut -d'/' -f1)
        
        local status_icon="❌"
        local status_color="$RED"
        
        if [ "$state" = "UP" ]; then
            status_icon="✅"
            status_color="$GREEN"
        elif [ "$state" = "DOWN" ]; then
            status_icon="⬇️"
            status_color="$YELLOW"
        fi
        
        echo -e "  ${status_color}${status_icon} $interface: $state${NC}"
        if [ "$ip" != "" ]; then
            echo -e "    IP: $ip"
        fi
    done
    
    # WiFi status
    echo -e "${GREEN}WiFi Status:${NC}"
    if command -v nmcli >/dev/null 2>&1; then
        local wifi_status=$(nmcli radio wifi)
        if [ "$wifi_status" = "enabled" ]; then
            echo -e "  ${GREEN}✅ WiFi: Enabled${NC}"
            local current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
            if [ -n "$current_ssid" ]; then
                echo -e "    Connected to: $current_ssid"
                local signal=$(nmcli -f IN-USE,SIGNAL dev wifi | grep '*' | awk '{print $2}')
                echo -e "    Signal: ${signal}%"
            fi
        else
            echo -e "  ${RED}❌ WiFi: Disabled${NC}"
        fi
    fi
    
    # Bluetooth status
    echo -e "${GREEN}Bluetooth Status:${NC}"
    if command -v bluetoothctl >/dev/null 2>&1; then
        if systemctl is-active bluetooth >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ Bluetooth: Active${NC}"
            # List connected devices
            local connected_devices=$(bluetoothctl paired-devices | wc -l)
            echo -e "    Paired devices: $connected_devices"
        else
            echo -e "  ${RED}❌ Bluetooth: Inactive${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Bluetooth: Not available${NC}"
    fi
}

# WiFi Management
wifi_scan() {
    log "Scanning for WiFi networks..."
    
    if ! command -v nmcli >/dev/null 2>&1; then
        error "NetworkManager not found. Install with: sudo pacman -S networkmanager"
        return 1
    fi
    
    # Rescan
    nmcli device wifi rescan
    sleep 3
    
    echo -e "${CYAN}=== Available WiFi Networks ===${NC}"
    nmcli -f SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY device wifi list | head -20
}

# Connect to WiFi
wifi_connect() {
    local ssid="$1"
    local password="$2"
    
    if [ -z "$ssid" ]; then
        wifi_scan
        read -p "Enter SSID to connect: " ssid
    fi
    
    if [ -z "$ssid" ]; then
        error "SSID required"
        return 1
    fi
    
    log "Connecting to WiFi: $ssid"
    
    if [ -z "$password" ]; then
        read -s -p "Enter password (leave empty for open network): " password
        echo
    fi
    
    if [ -n "$password" ]; then
        nmcli device wifi connect "$ssid" password "$password"
    else
        nmcli device wifi connect "$ssid"
    fi
    
    if [ $? -eq 0 ]; then
        success "Connected to $ssid"
        notify-send "📶 WiFi Connected" "Connected to $ssid" -t 3000 2>/dev/null || true
    else
        error "Failed to connect to $ssid"
    fi
}

# Disconnect WiFi
wifi_disconnect() {
    log "Disconnecting from WiFi..."
    
    local current_connection=$(nmcli -t -f NAME con show --active | grep -v 'lo\|docker' | head -1)
    
    if [ -n "$current_connection" ]; then
        nmcli con down "$current_connection"
        success "Disconnected from $current_connection"
    else
        warning "No active WiFi connection found"
    fi
}

# Toggle WiFi
wifi_toggle() {
    local current_state=$(nmcli radio wifi)
    
    if [ "$current_state" = "enabled" ]; then
        log "Disabling WiFi..."
        nmcli radio wifi off
        success "WiFi disabled"
        notify-send "📶 WiFi" "WiFi disabled" -t 2000 2>/dev/null || true
    else
        log "Enabling WiFi..."
        nmcli radio wifi on
        success "WiFi enabled"
        notify-send "📶 WiFi" "WiFi enabled" -t 2000 2>/dev/null || true
    fi
}

# Create WiFi hotspot
create_hotspot() {
    local ssid="${1:-HyprlandHotspot}"
    local password="$2"
    local interface="${3:-wlan0}"
    
    if [ -z "$password" ]; then
        # Generate random password
        password=$(openssl rand -base64 12)
        log "Generated password: $password"
    fi
    
    log "Creating WiFi hotspot: $ssid"
    
    # Check if NetworkManager is available
    if ! command -v nmcli >/dev/null 2>&1; then
        error "NetworkManager required for hotspot functionality"
        return 1
    fi
    
    # Create hotspot connection
    nmcli con add type wifi ifname "$interface" con-name "Hotspot" autoconnect no \
        ssid "$ssid" mode ap -- \
        wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password" \
        ipv4.method shared
    
    # Start hotspot
    nmcli con up "Hotspot"
    
    if [ $? -eq 0 ]; then
        success "Hotspot created: $ssid"
        echo -e "${GREEN}Password:${NC} $password"
        
        # Save hotspot config
        cat > "$HOTSPOT_DIR/current_hotspot.conf" << EOF
SSID="$ssid"
PASSWORD="$password"
INTERFACE="$interface"
CREATED="$(date)"
EOF
        
        notify-send "📶 Hotspot Created" "SSID: $ssid" -t 5000 2>/dev/null || true
    else
        error "Failed to create hotspot"
    fi
}

# Stop hotspot
stop_hotspot() {
    log "Stopping WiFi hotspot..."
    
    if nmcli con show "Hotspot" >/dev/null 2>&1; then
        nmcli con down "Hotspot"
        nmcli con delete "Hotspot"
        success "Hotspot stopped and removed"
    else
        warning "No active hotspot found"
    fi
}

# Bluetooth Management
bluetooth_status() {
    echo -e "${CYAN}=== Bluetooth Status ===${NC}"
    
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        error "Bluetooth tools not found. Install with: sudo pacman -S bluez bluez-utils"
        return 1
    fi
    
    # Bluetooth service status
    if systemctl is-active bluetooth >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Bluetooth Service: Active${NC}"
        
        # Controller status
        local controller_powered=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        if [ "$controller_powered" = "yes" ]; then
            echo -e "${GREEN}✅ Controller: Powered${NC}"
        else
            echo -e "${RED}❌ Controller: Not powered${NC}"
        fi
        
        # List paired devices
        echo -e "${GREEN}Paired Devices:${NC}"
        bluetoothctl paired-devices | while read -r line; do
            local mac=$(echo "$line" | awk '{print $2}')
            local name=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
            local connected=""
            
            if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
                connected="${GREEN}[CONNECTED]${NC}"
            fi
            
            echo -e "  ${GREEN}$name${NC} ($mac) $connected"
        done
        
    else
        echo -e "${RED}❌ Bluetooth Service: Inactive${NC}"
    fi
}

# Bluetooth scan
bluetooth_scan() {
    log "Scanning for Bluetooth devices..."
    
    if ! systemctl is-active bluetooth >/dev/null 2>&1; then
        log "Starting Bluetooth service..."
        sudo systemctl start bluetooth
    fi
    
    # Power on controller
    bluetoothctl power on >/dev/null 2>&1
    bluetoothctl discoverable on >/dev/null 2>&1
    
    # Start scanning
    bluetoothctl scan on &
    local scan_pid=$!
    
    echo -e "${CYAN}=== Scanning for Bluetooth Devices ===${NC}"
    echo "Press Ctrl+C to stop scanning..."
    
    # Monitor for new devices
    timeout 30 bluetoothctl devices | while read -r line; do
        local mac=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
        echo -e "${GREEN}$name${NC} ($mac)"
    done
    
    # Stop scanning
    kill $scan_pid 2>/dev/null || true
    bluetoothctl scan off >/dev/null 2>&1
}

# Bluetooth pair device
bluetooth_pair() {
    local device_mac="$1"
    
    if [ -z "$device_mac" ]; then
        bluetooth_scan
        read -p "Enter device MAC address to pair: " device_mac
    fi
    
    if [ -z "$device_mac" ]; then
        error "Device MAC address required"
        return 1
    fi
    
    log "Pairing with device: $device_mac"
    
    # Pair device
    bluetoothctl pair "$device_mac"
    
    if [ $? -eq 0 ]; then
        # Trust and connect
        bluetoothctl trust "$device_mac"
        bluetoothctl connect "$device_mac"
        success "Device paired and connected: $device_mac"
    else
        error "Failed to pair device: $device_mac"
    fi
}

# Toggle Bluetooth
bluetooth_toggle() {
    if systemctl is-active bluetooth >/dev/null 2>&1; then
        local controller_powered=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        
        if [ "$controller_powered" = "yes" ]; then
            log "Disabling Bluetooth..."
            bluetoothctl power off
            success "Bluetooth disabled"
        else
            log "Enabling Bluetooth..."
            bluetoothctl power on
            success "Bluetooth enabled"
        fi
    else
        log "Starting Bluetooth service..."
        sudo systemctl start bluetooth
        bluetoothctl power on
        success "Bluetooth service started and enabled"
    fi
}

# Network diagnostics
network_diagnostics() {
    log "Running network diagnostics..."
    
    echo -e "${CYAN}=== Network Diagnostics ===${NC}"
    
    # DNS resolution test
    echo -e "${GREEN}DNS Resolution:${NC}"
    if nslookup google.com >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ DNS: Working${NC}"
    else
        echo -e "  ${RED}❌ DNS: Failed${NC}"
    fi
    
    # Gateway connectivity
    echo -e "${GREEN}Gateway Connectivity:${NC}"
    local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ -n "$gateway" ]; then
        if ping -c 1 "$gateway" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ Gateway ($gateway): Reachable${NC}"
        else
            echo -e "  ${RED}❌ Gateway ($gateway): Unreachable${NC}"
        fi
    else
        echo -e "  ${RED}❌ No default gateway found${NC}"
    fi
    
    # Internet connectivity
    echo -e "${GREEN}Internet Connectivity:${NC}"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Internet: Connected${NC}"
        
        # Speed test (if available)
        if command -v speedtest-cli >/dev/null 2>&1; then
            log "Running speed test..."
            speedtest-cli --simple
        fi
    else
        echo -e "  ${RED}❌ Internet: No connectivity${NC}"
    fi
    
    # Network interfaces info
    echo -e "${GREEN}Network Interface Details:${NC}"
    ip addr show | grep -E "^[0-9]|inet " | while read -r line; do
        if [[ $line =~ ^[0-9] ]]; then
            local interface=$(echo "$line" | awk '{print $2}' | sed 's/://')
            echo -e "  ${GREEN}Interface: $interface${NC}"
        elif [[ $line =~ inet ]]; then
            local ip=$(echo "$line" | awk '{print $2}')
            echo -e "    IP: $ip"
        fi
    done
}

# Save network profile
save_network_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        read -p "Enter profile name: " profile_name
    fi
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    log "Saving network profile: $profile_name"
    
    # Get current network settings
    {
        echo "# Network Profile: $profile_name"
        echo "# Created: $(date)"
        echo
        
        # WiFi connections
        echo "=== WiFi Connections ==="
        nmcli con show | grep wifi
        echo
        
        # Network interfaces
        echo "=== Network Interfaces ==="
        ip addr show
        echo
        
        # Routes
        echo "=== Routes ==="
        ip route show
        echo
        
        # DNS settings
        echo "=== DNS Settings ==="
        cat /etc/resolv.conf 2>/dev/null || echo "No DNS config found"
        
    } > "$profile_file"
    
    success "Network profile saved: $profile_file"
}

# Show help
show_help() {
    echo "Usage: network-manager [command] [options]"
    echo
    echo "General Commands:"
    echo "  status               Show network status overview"
    echo "  diagnostics          Run network diagnostics"
    echo "  save-profile [name]  Save current network configuration"
    echo
    echo "WiFi Commands:"
    echo "  wifi-scan            Scan for available WiFi networks"
    echo "  wifi-connect [ssid] [password]  Connect to WiFi network"
    echo "  wifi-disconnect      Disconnect from WiFi"
    echo "  wifi-toggle          Toggle WiFi on/off"
    echo
    echo "Hotspot Commands:"
    echo "  create-hotspot [ssid] [password] [interface]  Create WiFi hotspot"
    echo "  stop-hotspot         Stop active hotspot"
    echo
    echo "Bluetooth Commands:"
    echo "  bluetooth-status     Show Bluetooth status and devices"
    echo "  bluetooth-scan       Scan for Bluetooth devices"
    echo "  bluetooth-pair [mac] Pair with Bluetooth device"
    echo "  bluetooth-toggle     Toggle Bluetooth on/off"
    echo
    echo "Examples:"
    echo "  network-manager wifi-connect MyNetwork password123"
    echo "  network-manager create-hotspot MyHotspot"
    echo "  network-manager bluetooth-pair AA:BB:CC:DD:EE:FF"
    echo "  network-manager diagnostics"
    echo
    echo "Features:"
    echo "  • Comprehensive WiFi management"
    echo "  • Bluetooth device pairing and management"
    echo "  • WiFi hotspot creation"
    echo "  • Network diagnostics and troubleshooting"
    echo "  • Network profile management"
    echo "  • Real-time status monitoring"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    status) network_status ;;
    diagnostics) network_diagnostics ;;
    save-profile) save_network_profile "$2" ;;
    wifi-scan) wifi_scan ;;
    wifi-connect) wifi_connect "$2" "$3" ;;
    wifi-disconnect) wifi_disconnect ;;
    wifi-toggle) wifi_toggle ;;
    create-hotspot) create_hotspot "$2" "$3" "$4" ;;
    stop-hotspot) stop_hotspot ;;
    bluetooth-status) bluetooth_status ;;
    bluetooth-scan) bluetooth_scan ;;
    bluetooth-pair) bluetooth_pair "$2" ;;
    bluetooth-toggle) bluetooth_toggle ;;
    help|*) show_help ;;
esac
