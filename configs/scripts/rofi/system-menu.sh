#!/bin/bash
# System Management Menu for Hyprland
# Quick access to all system management tools

# Theme configuration
THEME_FILE="$HOME/.config/rofi/themes/system-menu.rasi"

# Ensure theme directory exists
mkdir -p "$HOME/.config/rofi/themes"

# Create system menu theme
cat > "$THEME_FILE" << 'EOF'
// System Menu Theme for Hyprland Dotfiles
configuration {
    show-icons: true;
    display-drun: "";
    drun-display-format: "{name}";
    disable-history: false;
    sidebar-mode: false;
}

* {
    bg: #1e1e2e;
    bg-alt: #313244;
    bg-selected: #89b4fa;
    fg: #cdd6f4;
    fg-alt: #6c7086;
    
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    background-color: @bg;
    border: 2px solid @bg-selected;
    border-radius: 15px;
    width: 500px;
    location: center;
    padding: 25px;
}

mainbox {
    children: [message, listview];
    spacing: 20px;
}

message {
    background-color: @bg-alt;
    border-radius: 10px;
    padding: 15px;
    margin: 0 0 10px 0;
}

textbox {
    text-color: @fg;
    font: "JetBrainsMono Nerd Font Bold 14";
    horizontal-align: 0.5;
    vertical-align: 0.5;
}

listview {
    lines: 10;
    columns: 1;
    fixed-height: false;
    scrollbar: false;
    spacing: 5px;
}

element {
    children: [element-icon, element-text];
    orientation: horizontal;
    padding: 12px;
    spacing: 12px;
    border-radius: 8px;
    text-color: @fg;
    cursor: pointer;
}

element selected {
    background-color: @bg-selected;
    text-color: @bg;
}

element-icon {
    size: 24px;
    cursor: pointer;
}

element-text {
    cursor: pointer;
    font: "JetBrainsMono Nerd Font 12";
    vertical-align: 0.5;
}
EOF

# System menu options
options="🎮\tGaming Mode Manager
🖥️\tDisplay & Monitors
🔊\tAudio System
🎨\tTheme Manager
📱\tMobile & Sync
🔒\tSecurity Manager
🌐\tNetwork Manager
🛠️\tSystem Maintenance
📊\tSystem Monitor
📋\tClipboard Manager"

# Show system menu
chosen=$(echo -e "$options" | rofi -dmenu -i -theme "$THEME_FILE" \
    -mesg "System Management Tools" \
    -p "System Menu" \
    -format "s" \
    -no-custom)

# Handle selection
case "$chosen" in
    *"Gaming Mode Manager")
        # Show gaming submenu
        gaming_options="🎮\tToggle Gaming Mode
📊\tGaming Status
🎯\tLaunch Steam
⚙️\tCreate Profile
📝\tList Profiles"
        
        gaming_choice=$(echo -e "$gaming_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Gaming Mode Options" -p "Gaming" -format "s")
        
        case "$gaming_choice" in
            *"Toggle Gaming Mode") ~/hyprland-project/scripts/gaming/gaming-mode.sh toggle ;;
            *"Gaming Status") ~/hyprland-project/scripts/gaming/gaming-mode.sh status ;;
            *"Launch Steam") steam & ;;
            *"Create Profile") 
                profile_name=$(echo "" | rofi -dmenu -p "Profile name:" -theme "$THEME_FILE")
                if [ -n "$profile_name" ]; then
                    ~/hyprland-project/scripts/gaming/gaming-mode.sh create "$profile_name"
                fi
                ;;
            *"List Profiles") ~/hyprland-project/scripts/gaming/gaming-mode.sh list-profiles ;;
        esac
        ;;
        
    *"Display & Monitors")
        # Show monitor submenu
        monitor_options="📺\tMonitor Status
🔄\tAuto Configure
🖥️\tExtend Displays
📱\tMirror Displays
💾\tSave Profile
📋\tList Profiles"
        
        monitor_choice=$(echo -e "$monitor_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Display Management" -p "Monitors" -format "s")
        
        case "$monitor_choice" in
            *"Monitor Status") ~/hyprland-project/scripts/system/monitor-manager.sh list ;;
            *"Auto Configure") ~/hyprland-project/scripts/system/monitor-manager.sh auto ;;
            *"Extend Displays") ~/hyprland-project/scripts/system/monitor-manager.sh extend ;;
            *"Mirror Displays") ~/hyprland-project/scripts/system/monitor-manager.sh mirror ;;
            *"Save Profile") 
                profile_name=$(echo "" | rofi -dmenu -p "Profile name:" -theme "$THEME_FILE")
                if [ -n "$profile_name" ]; then
                    ~/hyprland-project/scripts/system/monitor-manager.sh save "$profile_name"
                fi
                ;;
            *"List Profiles") ~/hyprland-project/scripts/system/monitor-manager.sh list-profiles ;;
        esac
        ;;
        
    *"Audio System")
        # Show audio submenu
        audio_options="🔊\tAudio Info
🎵\tCreate Profile
📋\tList Profiles
🎛️\tSetup Equalizer
🎙️\tNoise Suppression
🔇\tEcho Cancellation
🎧\tTest Audio"
        
        audio_choice=$(echo -e "$audio_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Audio Management" -p "Audio" -format "s")
        
        case "$audio_choice" in
            *"Audio Info") ~/hyprland-project/scripts/audio/audio-manager.sh info ;;
            *"Create Profile") 
                profile_name=$(echo "" | rofi -dmenu -p "Profile name:" -theme "$THEME_FILE")
                if [ -n "$profile_name" ]; then
                    ~/hyprland-project/scripts/audio/audio-manager.sh create-profile "$profile_name"
                fi
                ;;
            *"List Profiles") ~/hyprland-project/scripts/audio/audio-manager.sh list-profiles ;;
            *"Setup Equalizer") ~/hyprland-project/scripts/audio/audio-manager.sh setup-equalizer ;;
            *"Noise Suppression") ~/hyprland-project/scripts/audio/audio-manager.sh setup-noise-suppression ;;
            *"Echo Cancellation") ~/hyprland-project/scripts/audio/audio-manager.sh setup-echo-cancel ;;
            *"Test Audio") 
                test_choice=$(echo -e "Speakers\nMicrophone" | rofi -dmenu -i -p "Test:" -theme "$THEME_FILE")
                case "$test_choice" in
                    "Speakers") ~/hyprland-project/scripts/audio/audio-manager.sh test speakers ;;
                    "Microphone") ~/hyprland-project/scripts/audio/audio-manager.sh test microphone ;;
                esac
                ;;
        esac
        ;;
        
    *"Theme Manager")
        # Show theme submenu
        theme_options="🎨\tTheme Status
🖱️\tSet Cursor Theme
🎯\tSet Icon Theme
🖼️\tSet GTK Theme
📚\tList Fonts
💾\tCreate Profile
📋\tLoad Profile"
        
        theme_choice=$(echo -e "$theme_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Theme Management" -p "Themes" -format "s")
        
        case "$theme_choice" in
            *"Theme Status") ~/hyprland-project/scripts/theming/theme-manager.sh status ;;
            *"Set Cursor Theme") ~/hyprland-project/scripts/theming/theme-manager.sh list-cursors ;;
            *"Set Icon Theme") ~/hyprland-project/scripts/theming/theme-manager.sh list-icons ;;
            *"Set GTK Theme") ~/hyprland-project/scripts/theming/theme-manager.sh list-gtk ;;
            *"List Fonts") ~/hyprland-project/scripts/theming/theme-manager.sh list-fonts ;;
            *"Create Profile") 
                profile_name=$(echo "" | rofi -dmenu -p "Profile name:" -theme "$THEME_FILE")
                if [ -n "$profile_name" ]; then
                    ~/hyprland-project/scripts/theming/theme-manager.sh create-profile "$profile_name"
                fi
                ;;
            *"Load Profile") 
                profiles=$(~/hyprland-project/scripts/theming/theme-manager.sh list-profiles | grep -o '^\s*[^ ]*' | tr -d ' ')
                if [ -n "$profiles" ]; then
                    profile_choice=$(echo "$profiles" | rofi -dmenu -i -p "Select profile:" -theme "$THEME_FILE")
                    if [ -n "$profile_choice" ]; then
                        ~/hyprland-project/scripts/theming/theme-manager.sh load-profile "$profile_choice"
                    fi
                fi
                ;;
        esac
        ;;
        
    *"Network Manager")
        # Show network submenu
        network_options="🌐\tNetwork Status
📶\tWiFi Scan
🔗\tWiFi Connect
📡\tCreate Hotspot
🔵\tBluetooth Status
🎧\tBluetooth Scan
🔍\tNetwork Diagnostics"
        
        network_choice=$(echo -e "$network_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Network Management" -p "Network" -format "s")
        
        case "$network_choice" in
            *"Network Status") ~/hyprland-project/scripts/network/network-manager.sh status ;;
            *"WiFi Scan") ~/hyprland-project/scripts/network/network-manager.sh wifi-scan ;;
            *"WiFi Connect") ~/hyprland-project/scripts/network/network-manager.sh wifi-scan ;;
            *"Create Hotspot") ~/hyprland-project/scripts/network/network-manager.sh create-hotspot ;;
            *"Bluetooth Status") ~/hyprland-project/scripts/network/network-manager.sh bluetooth-status ;;
            *"Bluetooth Scan") ~/hyprland-project/scripts/network/network-manager.sh bluetooth-scan ;;
            *"Network Diagnostics") ~/hyprland-project/scripts/network/network-manager.sh diagnostics ;;
        esac
        ;;
        
    *"System Maintenance")
        # Show maintenance submenu
        maintenance_options="🧹\tSystem Cleanup
🏥\tHealth Check
⚙️\tSystem Optimization
📊\tSystem Info
📈\tAnalyze Logs
📦\tPackage Management"
        
        maintenance_choice=$(echo -e "$maintenance_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "System Maintenance" -p "Maintenance" -format "s")
        
        case "$maintenance_choice" in
            *"System Cleanup") ~/hyprland-project/scripts/maintenance/system-maintenance.sh cleanup ;;
            *"Health Check") ~/hyprland-project/scripts/maintenance/system-maintenance.sh health-check ;;
            *"System Optimization") ~/hyprland-project/scripts/maintenance/system-maintenance.sh optimize ;;
            *"System Info") ~/hyprland-project/scripts/maintenance/system-maintenance.sh system-info ;;
            *"Analyze Logs") ~/hyprland-project/scripts/maintenance/system-maintenance.sh analyze-logs ;;
            *"Package Management")
                pkg_options="Update Database\nUpgrade System\nRemove Orphans\nList Updates"
                pkg_choice=$(echo -e "$pkg_options" | rofi -dmenu -i -p "Package action:" -theme "$THEME_FILE")
                case "$pkg_choice" in
                    "Update Database") ~/hyprland-project/scripts/maintenance/system-maintenance.sh packages update ;;
                    "Upgrade System") ~/hyprland-project/scripts/maintenance/system-maintenance.sh packages upgrade ;;
                    "Remove Orphans") ~/hyprland-project/scripts/maintenance/system-maintenance.sh packages autoremove ;;
                    "List Updates") ~/hyprland-project/scripts/maintenance/system-maintenance.sh packages list-updates ;;
                esac
                ;;
        esac
        ;;
        
    *"System Monitor")
        # Launch system monitor
        ~/hyprland-project/scripts/utils/system-monitor.sh monitor &
        ;;
        
    *"Mobile & Sync")
        # Show mobile submenu
        mobile_options="📱\tDevice Status
🔗\tSetup KDE Connect
📁\tSync All
☁️\tSetup Cloud Sync
💾\tBackup Data"
        
        mobile_choice=$(echo -e "$mobile_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Mobile & Sync" -p "Mobile" -format "s")
        
        case "$mobile_choice" in
            *"Device Status") ~/hyprland-project/scripts/sync/mobile-sync.sh device-status ;;
            *"Setup KDE Connect") ~/hyprland-project/scripts/sync/mobile-sync.sh setup-kdeconnect ;;
            *"Sync All") ~/hyprland-project/scripts/sync/mobile-sync.sh sync-all ;;
            *"Setup Cloud Sync") 
                cloud_choice=$(echo -e "Google Drive\nDropbox\nNextcloud\nOneDrive" | rofi -dmenu -i -p "Cloud service:" -theme "$THEME_FILE")
                case "$cloud_choice" in
                    "Google Drive") ~/hyprland-project/scripts/sync/mobile-sync.sh setup-cloud gdrive ;;
                    "Dropbox") ~/hyprland-project/scripts/sync/mobile-sync.sh setup-cloud dropbox ;;
                    "Nextcloud") ~/hyprland-project/scripts/sync/mobile-sync.sh setup-cloud nextcloud ;;
                    "OneDrive") ~/hyprland-project/scripts/sync/mobile-sync.sh setup-cloud onedrive ;;
                esac
                ;;
            *"Backup Data") ~/hyprland-project/scripts/sync/mobile-sync.sh backup ;;
        esac
        ;;
        
    *"Security Manager")
        # Show security submenu
        security_options="🔒\tVPN Status
🔐\tSetup PolicyKit
🗝️\tSetup Keyring
🧱\tFirewall Status
🔍\tSecurity Scan
🔑\tSetup 2FA"
        
        security_choice=$(echo -e "$security_options" | rofi -dmenu -i -theme "$THEME_FILE" \
            -mesg "Security Management" -p "Security" -format "s")
        
        case "$security_choice" in
            *"VPN Status") ~/hyprland-project/scripts/security/security-manager.sh vpn-status ;;
            *"Setup PolicyKit") ~/hyprland-project/scripts/security/security-manager.sh setup-polkit ;;
            *"Setup Keyring") ~/hyprland-project/scripts/security/security-manager.sh setup-keyring ;;
            *"Firewall Status") ~/hyprland-project/scripts/security/security-manager.sh firewall-status ;;
            *"Security Scan") ~/hyprland-project/scripts/security/security-manager.sh security-scan ;;
            *"Setup 2FA") ~/hyprland-project/scripts/security/security-manager.sh setup-2fa ;;
        esac
        ;;
esac
