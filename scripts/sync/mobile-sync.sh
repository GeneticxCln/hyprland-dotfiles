#!/bin/bash
# Mobile Device Integration & Sync Manager
# KDE Connect, cloud sync, and mobile integration for Hyprland

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
CONFIG_DIR="$HOME/.config/hypr/mobile-sync"
SYNC_DIR="$HOME/MobileSync"
BACKUP_DIR="$CONFIG_DIR/backups"
CLOUD_CONFIGS_DIR="$CONFIG_DIR/cloud-configs"

# Logging
log() { echo -e "${BLUE}[MOBILE-SYNC]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$SYNC_DIR" "$BACKUP_DIR" "$CLOUD_CONFIGS_DIR"
    mkdir -p "$SYNC_DIR/Pictures" "$SYNC_DIR/Documents" "$SYNC_DIR/Music" "$SYNC_DIR/Videos"
}

# KDE Connect Management
setup_kdeconnect() {
    log "Setting up KDE Connect..."
    
    # Check if KDE Connect is installed
    if ! command -v kdeconnect-cli >/dev/null 2>&1; then
        warning "KDE Connect not installed. Installing..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm kdeconnect
        elif command -v apt >/dev/null 2>&1; then
            sudo apt install -y kdeconnect
        else
            error "Unable to install KDE Connect automatically"
            return 1
        fi
    fi
    
    # Start KDE Connect daemon
    if ! pgrep -x "kdeconnectd" > /dev/null; then
        kdeconnectd &
        log "KDE Connect daemon started"
    fi
    
    # Start KDE Connect indicator
    if command -v kdeconnect-indicator >/dev/null 2>&1 && ! pgrep -x "kdeconnect-indicator" > /dev/null; then
        kdeconnect-indicator &
        log "KDE Connect indicator started"
    fi
    
    success "KDE Connect setup complete"
}

# List available devices
list_devices() {
    log "Scanning for mobile devices..."
    
    if ! command -v kdeconnect-cli >/dev/null 2>&1; then
        error "KDE Connect not installed"
        return 1
    fi
    
    echo -e "${CYAN}=== Available Devices ===${NC}"
    
    # List all devices
    local devices=$(kdeconnect-cli --list-available)
    if [ -z "$devices" ]; then
        echo "No devices found. Make sure KDE Connect is running on your mobile device."
        echo "Download KDE Connect from Google Play Store or F-Droid."
        return
    fi
    
    echo "$devices"
    echo
    
    # Show paired devices
    echo -e "${CYAN}=== Paired Devices ===${NC}"
    kdeconnect-cli --list-devices
}

# Pair with device
pair_device() {
    local device_id="$1"
    
    if [ -z "$device_id" ]; then
        log "Available devices:"
        kdeconnect-cli --list-available
        read -p "Enter device ID to pair: " device_id
    fi
    
    if [ -z "$device_id" ]; then
        error "Device ID required"
        return 1
    fi
    
    log "Pairing with device: $device_id"
    kdeconnect-cli --pair --device "$device_id"
    
    success "Pairing request sent to device $device_id"
    log "Accept the pairing request on your mobile device"
}

# Send file to device
send_file() {
    local file_path="$1"
    local device_id="$2"
    
    if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
        error "Valid file path required"
        return 1
    fi
    
    if [ -z "$device_id" ]; then
        log "Available paired devices:"
        kdeconnect-cli --list-devices
        read -p "Enter device ID: " device_id
    fi
    
    log "Sending file $file_path to device $device_id"
    kdeconnect-cli --share "$file_path" --device "$device_id"
    
    success "File sent to device $device_id"
}

# Send notification to device
send_notification() {
    local title="$1"
    local message="$2"
    local device_id="$3"
    
    if [ -z "$title" ] || [ -z "$message" ]; then
        error "Title and message required"
        return 1
    fi
    
    if [ -z "$device_id" ]; then
        log "Available paired devices:"
        kdeconnect-cli --list-devices
        read -p "Enter device ID: " device_id
    fi
    
    log "Sending notification to device $device_id"
    kdeconnect-cli --ping-msg "$title: $message" --device "$device_id"
    
    success "Notification sent to device $device_id"
}

# Ring device (find my phone)
ring_device() {
    local device_id="$1"
    
    if [ -z "$device_id" ]; then
        log "Available paired devices:"
        kdeconnect-cli --list-devices
        read -p "Enter device ID: " device_id
    fi
    
    log "Ringing device $device_id"
    kdeconnect-cli --ring --device "$device_id"
    
    success "Device $device_id is now ringing"
}

# Sync clipboard
sync_clipboard() {
    local device_id="$1"
    local content="$2"
    
    if [ -z "$device_id" ]; then
        log "Available paired devices:"
        kdeconnect-cli --list-devices
        read -p "Enter device ID: " device_id
    fi
    
    if [ -z "$content" ]; then
        # Get clipboard content
        if command -v wl-paste >/dev/null 2>&1; then
            content=$(wl-paste)
        elif command -v xclip >/dev/null 2>&1; then
            content=$(xclip -selection clipboard -o)
        else
            read -p "Enter content to sync: " content
        fi
    fi
    
    log "Syncing clipboard to device $device_id"
    echo "$content" | kdeconnect-cli --share-text --device "$device_id"
    
    success "Clipboard synced to device $device_id"
}

# Setup cloud storage sync
setup_cloud_sync() {
    local cloud_service="$1"
    
    case "$cloud_service" in
        gdrive)
            setup_google_drive
            ;;
        dropbox)
            setup_dropbox
            ;;
        nextcloud)
            setup_nextcloud
            ;;
        onedrive)
            setup_onedrive
            ;;
        *)
            echo "Available cloud services:"
            echo "  gdrive    - Google Drive"
            echo "  dropbox   - Dropbox"
            echo "  nextcloud - Nextcloud"
            echo "  onedrive  - OneDrive"
            ;;
    esac
}

# Google Drive setup
setup_google_drive() {
    log "Setting up Google Drive sync..."
    
    # Check for rclone
    if ! command -v rclone >/dev/null 2>&1; then
        warning "rclone not installed. Installing..."
        curl https://rclone.org/install.sh | sudo bash
    fi
    
    # Configure Google Drive
    log "Configuring Google Drive..."
    rclone config create gdrive drive
    
    # Create sync script
    cat > "$CONFIG_DIR/gdrive-sync.sh" << 'EOF'
#!/bin/bash
# Google Drive sync script

SYNC_DIR="$HOME/MobileSync"
REMOTE_NAME="gdrive"

# Sync important directories
rclone sync "$SYNC_DIR/Documents" "$REMOTE_NAME:MobileSync/Documents" -v
rclone sync "$SYNC_DIR/Pictures" "$REMOTE_NAME:MobileSync/Pictures" -v
rclone sync "$SYNC_DIR/Music" "$REMOTE_NAME:MobileSync/Music" -v

echo "Google Drive sync completed"
EOF
    
    chmod +x "$CONFIG_DIR/gdrive-sync.sh"
    success "Google Drive sync configured"
}

# Dropbox setup
setup_dropbox() {
    log "Setting up Dropbox sync..."
    
    # Check for Dropbox
    if ! command -v dropbox >/dev/null 2>&1; then
        warning "Dropbox not installed. Please install from AUR: yay -S dropbox"
        return 1
    fi
    
    # Start Dropbox
    dropbox start
    
    # Create sync links
    ln -sf "$HOME/Dropbox/MobileSync" "$SYNC_DIR/Dropbox"
    
    success "Dropbox sync configured"
}

# Nextcloud setup
setup_nextcloud() {
    local server_url="$1"
    local username="$2"
    local password="$3"
    
    log "Setting up Nextcloud sync..."
    
    if [ -z "$server_url" ]; then
        read -p "Enter Nextcloud server URL: " server_url
    fi
    
    if [ -z "$username" ]; then
        read -p "Enter username: " username
    fi
    
    if [ -z "$password" ]; then
        read -s -p "Enter password: " password
        echo
    fi
    
    # Check for rclone
    if ! command -v rclone >/dev/null 2>&1; then
        curl https://rclone.org/install.sh | sudo bash
    fi
    
    # Configure Nextcloud
    rclone config create nextcloud webdav \
        url="$server_url/remote.php/webdav/" \
        vendor=nextcloud \
        user="$username" \
        pass="$(rclone obscure "$password")"
    
    success "Nextcloud sync configured"
}

# OneDrive setup
setup_onedrive() {
    log "Setting up OneDrive sync..."
    
    # Check for OneDrive
    if ! command -v onedrive >/dev/null 2>&1; then
        warning "OneDrive not installed. Install from AUR: yay -S onedrive-abraunegg"
        return 1
    fi
    
    # Configure OneDrive
    onedrive --synchronize --single-directory "MobileSync"
    
    success "OneDrive sync configured"
}

# Auto sync service
setup_auto_sync() {
    local interval="${1:-300}" # 5 minutes default
    
    log "Setting up auto-sync service..."
    
    # Create systemd user service
    local service_file="$HOME/.config/systemd/user/mobile-sync.service"
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=Mobile Sync Service
After=network.target

[Service]
Type=simple
ExecStart=$0 sync-all
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF
    
    # Create timer
    local timer_file="$HOME/.config/systemd/user/mobile-sync.timer"
    
    cat > "$timer_file" << EOF
[Unit]
Description=Mobile Sync Timer
Requires=mobile-sync.service

[Timer]
OnBootSec=${interval}s
OnUnitActiveSec=${interval}s

[Install]
WantedBy=timers.target
EOF
    
    # Enable and start
    systemctl --user daemon-reload
    systemctl --user enable mobile-sync.timer
    systemctl --user start mobile-sync.timer
    
    success "Auto-sync service configured (interval: ${interval}s)"
}

# Sync all configured services
sync_all() {
    log "Running full sync..."
    
    # Sync cloud services
    if [ -x "$CONFIG_DIR/gdrive-sync.sh" ]; then
        log "Syncing Google Drive..."
        "$CONFIG_DIR/gdrive-sync.sh"
    fi
    
    # Sync with paired devices
    local devices=$(kdeconnect-cli --list-devices --id-only 2>/dev/null || true)
    for device_id in $devices; do
        if kdeconnect-cli --device "$device_id" --available; then
            log "Syncing with device: $device_id"
            # Send recent files
            find "$SYNC_DIR" -type f -mtime -1 | head -10 | while read file; do
                send_file "$file" "$device_id" 2>/dev/null || true
            done
        fi
    done
    
    success "Sync completed"
}

# Backup mobile data
backup_mobile_data() {
    local backup_name="${1:-mobile_backup_$(date +%Y%m%d_%H%M%S)}"
    local backup_path="$BACKUP_DIR/$backup_name.tar.gz"
    
    log "Creating mobile data backup..."
    
    tar -czf "$backup_path" \
        "$SYNC_DIR" \
        "$HOME/.config/kdeconnect" \
        "$CONFIG_DIR" \
        2>/dev/null || true
    
    success "Backup created: $backup_path"
}

# Restore mobile data
restore_mobile_data() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log "Available backups:"
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
        read -p "Enter backup file path: " backup_file
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring mobile data from backup..."
    
    # Extract backup
    tar -xzf "$backup_file" -C /
    
    success "Mobile data restored from backup"
}

# Show device status
device_status() {
    echo -e "${CYAN}=== Mobile Device Status ===${NC}"
    
    if ! command -v kdeconnect-cli >/dev/null 2>&1; then
        warning "KDE Connect not installed"
        return 1
    fi
    
    # Show paired devices
    local devices=$(kdeconnect-cli --list-devices --id-only 2>/dev/null || true)
    
    if [ -z "$devices" ]; then
        echo "No devices paired"
        return
    fi
    
    for device_id in $devices; do
        local device_name=$(kdeconnect-cli --device "$device_id" --name 2>/dev/null)
        local battery=$(kdeconnect-cli --device "$device_id" --get-battery 2>/dev/null || echo "unknown")
        local available=$(kdeconnect-cli --device "$device_id" --available && echo "online" || echo "offline")
        
        echo -e "${GREEN}Device:${NC} $device_name ($device_id)"
        echo -e "${GREEN}Status:${NC} $available"
        echo -e "${GREEN}Battery:${NC} $battery%"
        echo
    done
}

# Show help
show_help() {
    echo "Usage: mobile-sync [command] [options]"
    echo
    echo "KDE Connect Commands:"
    echo "  setup-kdeconnect         Setup KDE Connect integration"
    echo "  list-devices             List available and paired devices"
    echo "  pair [device-id]         Pair with a mobile device"
    echo "  send-file [file] [device-id]  Send file to device"
    echo "  send-notification [title] [message] [device-id]  Send notification"
    echo "  ring [device-id]         Ring device (find my phone)"
    echo "  sync-clipboard [device-id] [content]  Sync clipboard content"
    echo
    echo "Cloud Sync Commands:"
    echo "  setup-cloud [service]    Setup cloud storage sync (gdrive/dropbox/nextcloud/onedrive)"
    echo "  sync-all                 Sync all configured services and devices"
    echo "  setup-auto-sync [interval]  Setup automatic sync service"
    echo
    echo "Backup Commands:"
    echo "  backup [name]            Backup mobile sync data"
    echo "  restore [backup-file]    Restore from backup"
    echo
    echo "Status Commands:"
    echo "  device-status            Show status of paired devices"
    echo "  help                     Show this help message"
    echo
    echo "Examples:"
    echo "  mobile-sync setup-kdeconnect"
    echo "  mobile-sync pair abc123def456"
    echo "  mobile-sync send-file ~/Pictures/photo.jpg abc123def456"
    echo "  mobile-sync setup-cloud gdrive"
    echo "  mobile-sync send-notification 'Meeting' 'Meeting in 15 minutes'"
    echo
    echo "Features:"
    echo "  • KDE Connect integration for Android devices"
    echo "  • File sharing between devices"
    echo "  • Clipboard synchronization"
    echo "  • Notification forwarding"
    echo "  • Cloud storage synchronization"
    echo "  • Automatic backup and restore"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    setup-kdeconnect) setup_kdeconnect ;;
    list-devices) list_devices ;;
    pair) pair_device "$2" ;;
    send-file) send_file "$2" "$3" ;;
    send-notification) send_notification "$2" "$3" "$4" ;;
    ring) ring_device "$2" ;;
    sync-clipboard) sync_clipboard "$2" "$3" ;;
    setup-cloud) setup_cloud_sync "$2" ;;
    sync-all) sync_all ;;
    setup-auto-sync) setup_auto_sync "$2" ;;
    backup) backup_mobile_data "$2" ;;
    restore) restore_mobile_data "$2" ;;
    device-status) device_status ;;
    help|*) show_help ;;
esac
