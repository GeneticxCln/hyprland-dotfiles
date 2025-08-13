#!/bin/bash
# Security & Authentication Manager
# Comprehensive security management for Hyprland

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
CONFIG_DIR="$HOME/.config/hypr/security"
KEYRING_SERVICE="hyprland-keyring"
VPN_PROFILES_DIR="$CONFIG_DIR/vpn"
FIREWALL_RULES_DIR="$CONFIG_DIR/firewall"

# Logging
log() { echo -e "${BLUE}[SECURITY]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$VPN_PROFILES_DIR" "$FIREWALL_RULES_DIR"
}

# PolicyKit Management
setup_polkit() {
    log "Setting up PolicyKit authentication..."
    
    # Create custom PolicyKit rule for Hyprland operations
    local polkit_rule="$HOME/.config/polkit-1/rules.d/50-hyprland.rules"
    mkdir -p "$(dirname "$polkit_rule")"
    
    cat > "$polkit_rule" << 'EOF'
// Hyprland PolicyKit Rules
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.systemd1.manage-units" ||
         action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
         action.id == "org.freedesktop.NetworkManager.network-control") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.modify-device-system" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
    
    success "PolicyKit rules configured"
    
    # Start polkit authentication agent if not running
    if ! pgrep -x "polkit-gnome-authentication-agent-1" > /dev/null; then
        if command -v polkit-gnome-authentication-agent-1 >/dev/null 2>&1; then
            polkit-gnome-authentication-agent-1 &
            log "PolicyKit agent started"
        elif command -v lxpolkit >/dev/null 2>&1; then
            lxpolkit &
            log "LXPolKit agent started"
        else
            warning "No PolicyKit authentication agent found"
        fi
    fi
}

# Keyring Management
setup_keyring() {
    log "Setting up keyring integration..."
    
    # Check if gnome-keyring is available
    if command -v gnome-keyring-daemon >/dev/null 2>&1; then
        # Start gnome-keyring if not running
        if ! pgrep -x "gnome-keyring-daemon" > /dev/null; then
            eval $(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
            export SSH_AUTH_SOCK
            export GNOME_KEYRING_CONTROL
            export GNOME_KEYRING_PID
            log "GNOME Keyring started"
        fi
        
        # Create Hyprland-specific keyring
        echo "" | gnome-keyring-daemon --unlock 2>/dev/null || true
        
    elif command -v keepassxc >/dev/null 2>&1; then
        log "KeePassXC detected as password manager"
        
    else
        warning "No keyring system found. Install gnome-keyring or keepassxc"
    fi
    
    success "Keyring setup complete"
}

# Store password in keyring
store_password() {
    local service="$1"
    local username="$2"
    local password="$3"
    
    if [ -z "$service" ] || [ -z "$username" ]; then
        error "Service name and username required"
        return 1
    fi
    
    if [ -z "$password" ]; then
        read -s -p "Enter password for $username@$service: " password
        echo
    fi
    
    if command -v secret-tool >/dev/null 2>&1; then
        echo "$password" | secret-tool store --label="$service ($username)" service "$service" username "$username"
        success "Password stored for $username@$service"
    else
        warning "secret-tool not available. Install libsecret-tools"
    fi
}

# Retrieve password from keyring
get_password() {
    local service="$1"
    local username="$2"
    
    if [ -z "$service" ] || [ -z "$username" ]; then
        error "Service name and username required"
        return 1
    fi
    
    if command -v secret-tool >/dev/null 2>&1; then
        secret-tool lookup service "$service" username "$username"
    else
        warning "secret-tool not available"
        return 1
    fi
}

# List stored passwords
list_passwords() {
    log "Stored passwords in keyring:"
    
    if command -v secret-tool >/dev/null 2>&1; then
        secret-tool search --all | grep -E "(service|username|label)" | while read line; do
            echo "  $line"
        done
    else
        warning "secret-tool not available"
    fi
}

# VPN Management
setup_vpn() {
    local profile_name="$1"
    local vpn_type="${2:-openvpn}"
    local config_file="$3"
    
    if [ -z "$profile_name" ]; then
        error "VPN profile name required"
        return 1
    fi
    
    log "Setting up VPN profile: $profile_name"
    
    local profile_dir="$VPN_PROFILES_DIR/$profile_name"
    mkdir -p "$profile_dir"
    
    case "$vpn_type" in
        openvpn)
            setup_openvpn "$profile_name" "$config_file"
            ;;
        wireguard)
            setup_wireguard "$profile_name" "$config_file"
            ;;
        *)
            error "Unsupported VPN type: $vpn_type"
            return 1
            ;;
    esac
    
    success "VPN profile '$profile_name' configured"
}

# OpenVPN setup
setup_openvpn() {
    local profile_name="$1"
    local config_file="$2"
    
    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        error "Valid OpenVPN config file required"
        return 1
    fi
    
    local profile_dir="$VPN_PROFILES_DIR/$profile_name"
    
    # Copy config file
    cp "$config_file" "$profile_dir/client.ovpn"
    
    # Create connection script
    cat > "$profile_dir/connect.sh" << EOF
#!/bin/bash
# OpenVPN connection script for $profile_name

CONFIG_FILE="$profile_dir/client.ovpn"

# Check if already connected
if pgrep -f "openvpn.*$profile_name" > /dev/null; then
    echo "VPN $profile_name is already connected"
    exit 1
fi

# Connect to VPN
sudo openvpn --config "\$CONFIG_FILE" --daemon --log "/tmp/openvpn-$profile_name.log"

# Wait for connection
sleep 3

if pgrep -f "openvpn.*$profile_name" > /dev/null; then
    echo "VPN $profile_name connected successfully"
    notify-send "🔒 VPN Connected" "Connected to $profile_name" -t 3000 2>/dev/null || true
else
    echo "Failed to connect to VPN $profile_name"
    exit 1
fi
EOF
    
    chmod +x "$profile_dir/connect.sh"
}

# WireGuard setup
setup_wireguard() {
    local profile_name="$1"
    local config_file="$2"
    
    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        error "Valid WireGuard config file required"
        return 1
    fi
    
    local profile_dir="$VPN_PROFILES_DIR/$profile_name"
    
    # Copy config file
    cp "$config_file" "$profile_dir/wg0.conf"
    
    # Create connection script
    cat > "$profile_dir/connect.sh" << EOF
#!/bin/bash
# WireGuard connection script for $profile_name

CONFIG_FILE="$profile_dir/wg0.conf"

# Check if already connected
if wg show | grep -q "$profile_name"; then
    echo "WireGuard $profile_name is already connected"
    exit 1
fi

# Connect to VPN
sudo wg-quick up "\$CONFIG_FILE"

if wg show | grep -q "$profile_name"; then
    echo "WireGuard $profile_name connected successfully"
    notify-send "🔒 VPN Connected" "Connected to $profile_name" -t 3000 2>/dev/null || true
else
    echo "Failed to connect to WireGuard $profile_name"
    exit 1
fi
EOF
    
    chmod +x "$profile_dir/connect.sh"
}

# Connect to VPN
connect_vpn() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        error "VPN profile name required"
        return 1
    fi
    
    local profile_dir="$VPN_PROFILES_DIR/$profile_name"
    
    if [ ! -d "$profile_dir" ]; then
        error "VPN profile '$profile_name' not found"
        return 1
    fi
    
    log "Connecting to VPN: $profile_name"
    
    if [ -x "$profile_dir/connect.sh" ]; then
        "$profile_dir/connect.sh"
    else
        error "Connection script not found for $profile_name"
    fi
}

# Disconnect from VPN
disconnect_vpn() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        # Disconnect all VPNs
        log "Disconnecting all VPNs..."
        
        # Kill OpenVPN processes
        sudo pkill -f "openvpn" 2>/dev/null || true
        
        # Disconnect WireGuard
        for config in /etc/wireguard/*.conf; do
            if [ -f "$config" ]; then
                local iface=$(basename "$config" .conf)
                sudo wg-quick down "$iface" 2>/dev/null || true
            fi
        done
        
        success "All VPNs disconnected"
    else
        log "Disconnecting VPN: $profile_name"
        
        # Kill specific OpenVPN process
        sudo pkill -f "openvpn.*$profile_name" 2>/dev/null || true
        
        # Disconnect specific WireGuard
        local profile_dir="$VPN_PROFILES_DIR/$profile_name"
        if [ -f "$profile_dir/wg0.conf" ]; then
            sudo wg-quick down "$profile_dir/wg0.conf" 2>/dev/null || true
        fi
        
        success "VPN $profile_name disconnected"
    fi
    
    notify-send "🔒 VPN Disconnected" "VPN connection closed" -t 3000 2>/dev/null || true
}

# Show VPN status
vpn_status() {
    echo -e "${CYAN}=== VPN Status ===${NC}"
    
    # Check OpenVPN
    if pgrep -x "openvpn" > /dev/null; then
        echo -e "${GREEN}OpenVPN: CONNECTED${NC}"
        pgrep -f "openvpn" | while read pid; do
            local cmd=$(ps -p "$pid" -o cmd --no-headers)
            echo "  $cmd"
        done
    else
        echo -e "${YELLOW}OpenVPN: DISCONNECTED${NC}"
    fi
    
    # Check WireGuard
    local wg_interfaces=$(wg show interfaces 2>/dev/null || true)
    if [ -n "$wg_interfaces" ]; then
        echo -e "${GREEN}WireGuard: CONNECTED${NC}"
        wg show
    else
        echo -e "${YELLOW}WireGuard: DISCONNECTED${NC}"
    fi
}

# Firewall Management
setup_firewall() {
    log "Setting up firewall (UFW)..."
    
    if ! command -v ufw >/dev/null 2>&1; then
        warning "UFW not installed. Install with: sudo pacman -S ufw"
        return 1
    fi
    
    # Enable UFW if disabled
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable
        log "UFW firewall enabled"
    fi
    
    # Basic firewall rules
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (be careful with this)
    sudo ufw allow ssh
    
    # Allow common services
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 53/tcp    # DNS
    sudo ufw allow 53/udp    # DNS
    
    success "Basic firewall rules applied"
}

# Add firewall rule
add_firewall_rule() {
    local rule="$1"
    
    if [ -z "$rule" ]; then
        error "Firewall rule required (e.g., 'allow 8080/tcp')"
        return 1
    fi
    
    log "Adding firewall rule: $rule"
    sudo ufw $rule
    
    success "Firewall rule added"
}

# Show firewall status
firewall_status() {
    echo -e "${CYAN}=== Firewall Status ===${NC}"
    
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status verbose
    else
        warning "UFW not installed"
    fi
}

# Security scan
security_scan() {
    log "Running security scan..."
    
    echo -e "${CYAN}=== Security Scan Results ===${NC}"
    
    # Check for running services
    echo -e "${GREEN}Listening Services:${NC}"
    ss -tuln | head -10
    
    echo
    
    # Check for SUID files
    echo -e "${GREEN}SUID Files (potential security risk):${NC}"
    find /usr -perm -4000 -type f 2>/dev/null | head -10
    
    echo
    
    # Check SSH configuration
    if [ -f "/etc/ssh/sshd_config" ]; then
        echo -e "${GREEN}SSH Security Check:${NC}"
        local root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
        local password_auth=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
        
        echo "  Root login: ${root_login:-default}"
        echo "  Password auth: ${password_auth:-default}"
        
        if [ "$root_login" = "yes" ]; then
            warning "Root SSH login is enabled (security risk)"
        fi
    fi
    
    echo
    
    # Check for failed login attempts
    echo -e "${GREEN}Recent Failed Logins:${NC}"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u sshd --since "1 hour ago" | grep "Failed" | tail -5 || echo "  No recent failures"
    fi
    
    success "Security scan complete"
}

# Enable 2FA
setup_2fa() {
    log "Setting up 2FA authentication..."
    
    if ! command -v google-authenticator >/dev/null 2>&1; then
        warning "google-authenticator not installed. Install with: sudo pacman -S libpam-google-authenticator"
        return 1
    fi
    
    # Run google-authenticator setup
    google-authenticator
    
    # Configure PAM for 2FA
    log "Configuring PAM for 2FA..."
    
    local pam_sshd="/etc/pam.d/sshd"
    if [ -f "$pam_sshd" ]; then
        if ! grep -q "pam_google_authenticator.so" "$pam_sshd"; then
            echo "auth required pam_google_authenticator.so" | sudo tee -a "$pam_sshd" >/dev/null
            log "2FA added to SSH PAM configuration"
        fi
    fi
    
    success "2FA setup complete. Restart SSH service to activate."
}

# Backup security settings
backup_security() {
    local backup_file="$CONFIG_DIR/security_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Creating security settings backup..."
    
    # Create backup of important security files
    tar -czf "$backup_file" \
        -C / \
        etc/ssh/sshd_config \
        etc/pam.d/ \
        "$HOME/.config/polkit-1/" \
        "$CONFIG_DIR/" \
        2>/dev/null || true
    
    success "Security backup created: $backup_file"
}

# Show help
show_help() {
    echo "Usage: security-manager [command] [options]"
    echo
    echo "Authentication Commands:"
    echo "  setup-polkit             Setup PolicyKit authentication"
    echo "  setup-keyring            Setup keyring integration"
    echo "  store-password [service] [username] [password]  Store password in keyring"
    echo "  get-password [service] [username]  Get password from keyring"
    echo "  list-passwords           List stored passwords"
    echo
    echo "VPN Commands:"
    echo "  setup-vpn [name] [type] [config]  Setup VPN profile"
    echo "  connect-vpn [name]       Connect to VPN"
    echo "  disconnect-vpn [name]    Disconnect from VPN (empty = all)"
    echo "  vpn-status               Show VPN connection status"
    echo
    echo "Firewall Commands:"
    echo "  setup-firewall           Setup and configure UFW firewall"
    echo "  add-rule [rule]          Add firewall rule"
    echo "  firewall-status          Show firewall status"
    echo
    echo "Security Commands:"
    echo "  security-scan            Run comprehensive security scan"
    echo "  setup-2fa                Setup 2FA authentication"
    echo "  backup-security          Backup security settings"
    echo "  help                     Show this help message"
    echo
    echo "Examples:"
    echo "  security-manager setup-polkit"
    echo "  security-manager setup-vpn myvpn openvpn /path/to/config.ovpn"
    echo "  security-manager connect-vpn myvpn"
    echo "  security-manager add-rule 'allow 8080/tcp'"
    echo "  security-manager store-password gmail john.doe@gmail.com"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    setup-polkit) setup_polkit ;;
    setup-keyring) setup_keyring ;;
    store-password) store_password "$2" "$3" "$4" ;;
    get-password) get_password "$2" "$3" ;;
    list-passwords) list_passwords ;;
    setup-vpn) setup_vpn "$2" "$3" "$4" ;;
    connect-vpn) connect_vpn "$2" ;;
    disconnect-vpn) disconnect_vpn "$2" ;;
    vpn-status) vpn_status ;;
    setup-firewall) setup_firewall ;;
    add-rule) add_firewall_rule "$2" ;;
    firewall-status) firewall_status ;;
    security-scan) security_scan ;;
    setup-2fa) setup_2fa ;;
    backup-security) backup_security ;;
    help|*) show_help ;;
esac
