#!/bin/bash
# Enhanced Power Menu for Hyprland
# Beautiful power options with confirmations and system integration

# Theme configuration
THEME_FILE="$HOME/.config/rofi/themes/power-menu.rasi"

# Ensure theme directory exists
mkdir -p "$HOME/.config/rofi/themes"

# Create power menu theme
cat > "$THEME_FILE" << 'EOF'
// Power Menu Theme for Hyprland Dotfiles
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
    bg-selected: #f38ba8;
    fg: #cdd6f4;
    fg-alt: #6c7086;
    red: #f38ba8;
    orange: #fab387;
    yellow: #f9e2af;
    green: #a6e3a1;
    cyan: #74c7ec;
    blue: #89b4fa;
    purple: #cba6f7;
    
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    background-color: @bg;
    border: 2px solid @bg-selected;
    border-radius: 15px;
    width: 400px;
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
    lines: 5;
    columns: 1;
    fixed-height: false;
    scrollbar: false;
    spacing: 8px;
}

element {
    children: [element-icon, element-text];
    orientation: horizontal;
    padding: 15px;
    spacing: 15px;
    border-radius: 10px;
    text-color: @fg;
    cursor: pointer;
}

element selected {
    text-color: @bg;
}

element-icon {
    size: 28px;
    cursor: pointer;
}

element-text {
    cursor: pointer;
    font: "JetBrainsMono Nerd Font 13";
    vertical-align: 0.5;
}

// Color coding for different actions
element.shutdown selected {
    background-color: @red;
}

element.reboot selected {
    background-color: @orange;
}

element.logout selected {
    background-color: @yellow;
}

element.suspend selected {
    background-color: @cyan;
}

element.lock selected {
    background-color: @blue;
}
EOF

# Power menu options with icons and classes
options="⏻\tShutdown\0icon\x1fsystem-shutdown\x1finfo\x1fshutdown
\tReboot\0icon\x1fsystem-reboot\x1finfo\x1freboot
\tLogout\0icon\x1fsystem-log-out\x1finfo\x1flogout
\tSuspend\0icon\x1fsystem-suspend\x1finfo\x1fsuspend
\tLock Screen\0icon\x1fsystem-lock-screen\x1finfo\x1flock"

# Show power menu
chosen=$(echo -e "$options" | rofi -dmenu -i -theme "$THEME_FILE" \
    -mesg "Choose your action" \
    -p "Power Menu" \
    -format "s" \
    -markup-rows \
    -no-custom)

# Handle selection
case "$chosen" in
    "Shutdown")
        # Confirmation dialog
        confirm=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Are you sure you want to shutdown?" -theme "$THEME_FILE")
        if [ "$confirm" = "Yes" ]; then
            # Save gaming mode state if active
            if ~/hyprland-project/scripts/gaming/gaming-mode.sh status | grep -q "ACTIVE"; then
                notify-send "💾 Saving State" "Preserving gaming mode settings..." -t 2000
            fi
            systemctl poweroff
        fi
        ;;
    "Reboot")
        confirm=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Are you sure you want to reboot?" -theme "$THEME_FILE")
        if [ "$confirm" = "Yes" ]; then
            # Save current state
            notify-send "💾 Saving State" "Preserving system settings..." -t 2000
            systemctl reboot
        fi
        ;;
    "Logout")
        confirm=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "Are you sure you want to logout?" -theme "$THEME_FILE")
        if [ "$confirm" = "Yes" ]; then
            # Save workspace state
            hyprctl dispatch exit
        fi
        ;;
    "Suspend")
        # Auto lock before suspend
        if command -v swaylock >/dev/null 2>&1; then
            swaylock -f &
        elif command -v hyprlock >/dev/null 2>&1; then
            hyprlock &
        fi
        sleep 1
        systemctl suspend
        ;;
    "Lock Screen")
        if command -v swaylock >/dev/null 2>&1; then
            swaylock
        elif command -v hyprlock >/dev/null 2>&1; then
            hyprlock
        else
            # Fallback to simple screen lock
            hyprctl dispatch dpms off
            notify-send "🔒 Screen Locked" "Press any key to unlock" -t 3000
        fi
        ;;
esac
