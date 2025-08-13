#!/bin/bash

# Complete Theme Configuration Functions
# All 6 themes with full Quickshell, Rofi, Kitty, Dunst configurations

# Create Quickshell configuration for each theme
create_quickshell_config() {
    local theme="$1"
    local bg="$2"
    local surface0="$3"
    local text="$4" 
    local accent="$5"
    
    log "Creating Quickshell configuration for $theme theme..."
    
    # Source blur effects
    source "$SCRIPT_DIR/effects.sh" 2>/dev/null || true
    
    # Get transparency values for theme
    local panel_bg=$(apply_quickshell_blur "$theme" "panel" "$bg")
    local widget_bg=$(apply_quickshell_blur "$theme" "widget" "$bg")
    
    cat > "$HOME/.config/quickshell/shell.qml" << EOF
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Quickshell 2.0

ShellRoot {
    id: root
    
    // Bottom Panel
    PanelWindow {
        id: bottomPanel
        anchors {
            left: true
            right: true
            bottom: true
        }
        
        height: 65
        margins: 12
        color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            color: "$bg"
            radius: 16
            border.color: "$accent"
            border.width: 2
            opacity: 0.95
            
            // Blur effect
            layer.enabled: true
            layer.effect: ShaderEffect {
                property real blurRadius: 20
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 20
                
                // Left: App Launcher
                Rectangle {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    color: "$accent"
                    radius: 12
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰀻"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 22
                        color: "$bg"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onEntered: parent.scale = 1.1
                        onExited: parent.scale = 1.0
                        onClicked: Quickshell.exec("rofi -show drun")
                        
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                }
                
                // Workspaces
                Row {
                    spacing: 8
                    
                    Repeater {
                        model: 10
                        
                        Rectangle {
                            width: 35
                            height: 35
                            radius: 8
                            color: index < 5 ? "${accent}40" : "${surface0}80"
                            border.color: index === 0 ? "$accent" : "transparent"
                            border.width: 2
                            
                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 12
                                color: "$text"
                                font.bold: index === 0
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.1
                                onExited: parent.scale = 1.0
                                onClicked: Quickshell.exec("hyprctl dispatch workspace " + (index + 1))
                                
                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }
                    }
                }
                
                // Center: Window Title
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    color: "${surface0}60"
                    radius: 12
                    border.color: "${accent}30"
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Hyprland Desktop - $theme Theme"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 13
                        color: "$text"
                        elide: Text.ElideRight
                    }
                }
                
                // System Info Row
                RowLayout {
                    spacing: 12
                    
                    // Volume
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 45
                        color: "${surface0}60"
                        radius: 12
                        border.color: "${accent}30"
                        border.width: 1
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: "󰕾"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 16
                                color: "$accent"
                            }
                            
                            Text {
                                text: "75%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 11
                                color: "$text"
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.exec("pavucontrol")
                        }
                    }
                    
                    // Network
                    Rectangle {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 45
                        color: "${surface0}60"
                        radius: 12
                        border.color: "${accent}30"
                        border.width: 1
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: "󰤨"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 16
                                color: "$accent"
                            }
                            
                            Text {
                                text: "WiFi"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: 11
                                color: "$text"
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.exec("nm-connection-editor")
                        }
                    }
                    
                    // Clock
                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 45
                        color: "$accent"
                        radius: 12
                        
                        Text {
                            id: clockText
                            anchors.centerIn: parent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 13
                            color: "$bg"
                            font.bold: true
                            
                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: {
                                    var now = new Date()
                                    clockText.text = Qt.formatDateTime(now, "hh:mm:ss")
                                }
                            }
                            
                            Component.onCompleted: {
                                var now = new Date()
                                text = Qt.formatDateTime(now, "hh:mm:ss")
                            }
                        }
                    }
                    
                    // Power Menu
                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 45
                        color: "#f38ba8"
                        radius: 12
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⏻"
                            font.pointSize: 18
                            color: "white"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.scale = 1.1
                            onExited: parent.scale = 1.0
                            onClicked: Quickshell.exec("wlogout")
                            
                            Behavior on scale {
                                NumberAnimation { duration: 150 }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Top Right System Monitor Widget
    PanelWindow {
        id: systemWidget
        anchors {
            top: true
            right: true
        }
        
        width: 280
        height: 200
        margins: 16
        color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            color: "$bg"
            radius: 16
            border.color: "$accent"
            border.width: 2
            opacity: 0.95
            
            Column {
                anchors.centerIn: parent
                spacing: 16
                
                Text {
                    text: "System Monitor"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pointSize: 14
                    color: "$accent"
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // CPU Usage
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: "󰻠"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 16
                        color: "$accent"
                    }
                    
                    Column {
                        Text {
                            text: "CPU Usage"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 10
                            color: "$text"
                        }
                        Text {
                            text: "45%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 12
                            color: "$accent"
                            font.bold: true
                        }
                    }
                }
                
                // Memory Usage
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: "󰍛"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 16
                        color: "$accent"
                    }
                    
                    Column {
                        Text {
                            text: "Memory"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 10
                            color: "$text"
                        }
                        Text {
                            text: "6.2GB / 16GB"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 12
                            color: "$accent"
                            font.bold: true
                        }
                    }
                }
                
                // Uptime
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        text: "󰔟"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pointSize: 16
                        color: "$accent"
                    }
                    
                    Column {
                        Text {
                            text: "Uptime"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 10
                            color: "$text"
                        }
                        Text {
                            text: "2h 34m"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: 12
                            color: "$accent"
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
EOF

    success "Quickshell configuration created for $theme theme"
}

# Create Rofi configuration for each theme
create_rofi_config() {
    local theme="$1"
    local bg="$2"
    local text="$3"
    local accent="$4"
    
    log "Creating Rofi configuration for $theme theme..."
    
    # Main Rofi config
    cat > "$HOME/.config/rofi/config.rasi" << EOF
configuration {
    font: "JetBrainsMono Nerd Font 12";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{icon} {name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "   Apps ";
    display-run: "   Run ";
    display-window: " 﩯  Window";
    display-network: " 󰤨  Network";
    sidebar-mode: true;
    hover-select: true;
    eh: 1;
    auto-select: false;
    parse-hosts: true;
    parse-known-hosts: true;
    combi-modi: "window,drun,ssh";
    matching: "fuzzy";
    scroll-method: 0;
    window-format: "{w}    {c}   {t}";
    click-to-exit: true;
    show-match: true;
    theme: "$theme-theme";
    modes: "window,drun,run,ssh";
    kb-primary-paste: "Control+V,Shift+Insert";
    kb-secondary-paste: "Control+v,Insert";
    kb-clear-line: "Control+l";
    kb-move-front: "Control+a";
    kb-move-end: "Control+e";
    kb-move-word-back: "Alt+b,Control+Left";
    kb-move-word-forward: "Alt+f,Control+Right";
    kb-move-char-back: "Left,Control+b";
    kb-move-char-forward: "Right,Control+f";
    kb-remove-word-back: "Control+Alt+h,Control+BackSpace";
    kb-remove-word-forward: "Control+Alt+d";
    kb-remove-char-forward: "Delete,Control+d";
    kb-remove-char-back: "BackSpace,Shift+BackSpace,Control+h";
    kb-remove-to-eol: "Control+k";
    kb-remove-to-sol: "Control+u";
    kb-accept-entry: "Control+j,Control+m,Return,KP_Enter";
    kb-accept-custom: "Control+Return";
    kb-accept-custom-alt: "Control+Shift+Return";
    kb-accept-alt: "Shift+Return";
    kb-delete-entry: "Shift+Delete";
    kb-mode-next: "Shift+Right,Control+Tab";
    kb-mode-previous: "Shift+Left,Control+ISO_Left_Tab";
    kb-row-left: "Control+Page_Up";
    kb-row-right: "Control+Page_Down";
    kb-row-up: "Up,Control+p,ISO_Left_Tab";
    kb-row-down: "Down,Control+n";
    kb-row-tab: "Tab";
    kb-page-prev: "Page_Up";
    kb-page-next: "Page_Down";
    kb-row-first: "Home,KP_Home";
    kb-row-last: "End,KP_End";
    kb-row-select: "Control+space";
    kb-screenshot: "Alt+S";
    kb-ellipsize: "Alt+period";
    kb-toggle-case-sensitivity: "grave,dead_grave";
    kb-toggle-sort: "Alt+grave";
    kb-cancel: "Escape,Control+g,Control+bracketleft";
    kb-custom-1: "Alt+1";
    kb-custom-2: "Alt+2";
    kb-custom-3: "Alt+3";
    kb-custom-4: "Alt+4";
    kb-custom-5: "Alt+5";
    kb-custom-6: "Alt+6";
    kb-custom-7: "Alt+7";
    kb-custom-8: "Alt+8";
    kb-custom-9: "Alt+9";
    kb-custom-10: "Alt+0";
    kb-custom-11: "Alt+exclam";
    kb-custom-12: "Alt+at";
    kb-custom-13: "Alt+numbersign";
    kb-custom-14: "Alt+dollar";
    kb-custom-15: "Alt+percent";
    kb-custom-16: "Alt+dead_circumflex";
    kb-custom-17: "Alt+ampersand";
    kb-custom-18: "Alt+asterisk";
    kb-custom-19: "Alt+parenleft";
    kb-select-1: "Super+1";
    kb-select-2: "Super+2";
    kb-select-3: "Super+3";
    kb-select-4: "Super+4";
    kb-select-5: "Super+5";
    kb-select-6: "Super+6";
    kb-select-7: "Super+7";
    kb-select-8: "Super+8";
    kb-select-9: "Super+9";
    kb-select-10: "Super+0";
    ml-row-left: "ScrollLeft";
    ml-row-right: "ScrollRight";
    ml-row-up: "ScrollUp";
    ml-row-down: "ScrollDown";
    me-select-entry: "MousePrimary";
    me-accept-entry: "MouseDPrimary";
    me-accept-custom: "Control+MouseDPrimary";
}

@theme "$theme-theme"
EOF

    # Create theme-specific styling
    create_rofi_theme "$theme" "$bg" "$text" "$accent"
    
    success "Rofi configuration created for $theme theme"
}

# Create theme-specific Rofi styling
create_rofi_theme() {
    local theme="$1"
    local bg="$2"
    local text="$3"
    local accent="$4"
    
    # Convert hex colors to rgba
    local bg_r=$(printf "%d" 0x${bg:1:2})
    local bg_g=$(printf "%d" 0x${bg:3:2})
    local bg_b=$(printf "%d" 0x${bg:5:2})
    
    local text_r=$(printf "%d" 0x${text:1:2})
    local text_g=$(printf "%d" 0x${text:3:2})
    local text_b=$(printf "%d" 0x${text:5:2})
    
    local accent_r=$(printf "%d" 0x${accent:1:2})
    local accent_g=$(printf "%d" 0x${accent:3:2})
    local accent_b=$(printf "%d" 0x${accent:5:2})
    
    cat > "$HOME/.config/rofi/themes/$theme-theme.rasi" << EOF
/**
 * $theme Theme for Rofi
 * Generated by Hyprland Dotfiles Setup
 */

* {
    bg-col: rgba($bg_r, $bg_g, $bg_b, 0.95);
    bg-col-light: rgba($bg_r, $bg_g, $bg_b, 0.8);
    border-col: rgba($accent_r, $accent_g, $accent_b, 0.8);
    selected-col: rgba($accent_r, $accent_g, $accent_b, 0.2);
    accent: rgba($accent_r, $accent_g, $accent_b, 1.0);
    fg-col: rgba($text_r, $text_g, $text_b, 1.0);
    fg-col2: rgba($text_r, $text_g, $text_b, 0.7);
    grey: rgba($text_r, $text_g, $text_b, 0.4);
    
    width: 800;
    height: 600;
    font: "JetBrainsMono Nerd Font 14";
}

element-text, element-icon, mode-switcher {
    background-color: inherit;
    text-color: inherit;
}

window {
    border: 3px;
    border-color: @border-col;
    background-color: @bg-col;
    border-radius: 16px;
}

mainbox {
    background-color: @bg-col;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col;
    border-radius: 8px;
    padding: 2px;
    margin: 20px 20px 0px 20px;
}

prompt {
    background-color: @accent;
    padding: 12px;
    text-color: @bg-col;
    border-radius: 8px;
    margin: 0px 0px 0px 0px;
    font: "JetBrainsMono Nerd Font Bold 14";
}

textbox-prompt-colon {
    expand: false;
    str: ":";
}

entry {
    padding: 12px;
    margin: 0px 0px 0px 10px;
    text-color: @fg-col;
    background-color: @bg-col;
    placeholder-color: @grey;
    placeholder: "Search applications...";
    font: "JetBrainsMono Nerd Font 14";
}

listview {
    border: 0px 0px 0px;
    padding: 6px 0px 0px;
    margin: 20px 20px 20px 20px;
    columns: 3;
    lines: 8;
    background-color: @bg-col;
    fixed-height: true;
    fixed-columns: true;
    spacing: 8px;
}

element {
    padding: 12px;
    background-color: @bg-col;
    text-color: @fg-col;
    border-radius: 12px;
    border: 2px solid transparent;
    orientation: vertical;
}

element-icon {
    size: 48px;
    horizontal-align: 0.5;
    vertical-align: 0.5;
    margin: 0px 0px 8px 0px;
}

element-text {
    horizontal-align: 0.5;
    vertical-align: 0.5;
    font: "JetBrainsMono Nerd Font 11";
    text-color: @fg-col;
}

element selected {
    background-color: @selected-col;
    text-color: @accent;
    border: 2px solid @accent;
    transform: scale(1.02);
}

element selected element-text {
    text-color: @accent;
    font: "JetBrainsMono Nerd Font Bold 11";
}

element selected element-icon {
    scale: 1.1;
}

mode-switcher {
    spacing: 0;
    margin: 20px 20px 0px 20px;
}

button {
    padding: 12px;
    background-color: @bg-col-light;
    text-color: @grey;
    vertical-align: 0.5;
    horizontal-align: 0.5;
    border-radius: 8px;
    margin: 0px 4px;
    font: "JetBrainsMono Nerd Font 12";
}

button selected {
    background-color: @accent;
    text-color: @bg-col;
    font: "JetBrainsMono Nerd Font Bold 12";
}

scrollbar {
    width: 4px;
    border: 0;
    handle-width: 4px;
    padding: 0;
    handle-color: @accent;
}

message {
    margin: 20px;
    padding: 12px;
    border-radius: 8px;
    background-color: @selected-col;
    text-color: @fg-col;
}

textbox {
    padding: 8px;
    margin: 0px;
    text-color: @fg-col;
    background-color: transparent;
    font: "JetBrainsMono Nerd Font 12";
}
EOF
}

# Create Kitty configuration for each theme
create_kitty_config() {
    local theme="$1"
    
    log "Creating Kitty configuration for $theme theme..."
    
    case $theme in
        "mocha")
            create_kitty_catppuccin_mocha
            ;;
        "macchiato")
            create_kitty_catppuccin_macchiato
            ;;
        "tokyonight")
            create_kitty_tokyonight
            ;;
        "gruvbox")
            create_kitty_gruvbox
            ;;
        "nord")
            create_kitty_nord
            ;;
        "rosepine")
            create_kitty_rosepine
            ;;
    esac
    
    success "Kitty configuration created for $theme theme"
}

# Kitty Catppuccin Mocha
create_kitty_catppuccin_mocha() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - Catppuccin Mocha Theme

# Font
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Window
initial_window_width  1200
initial_window_height 800
window_padding_width 12
window_margin_width 0
single_window_margin_width -1
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 12
hide_window_decorations no

# Tabs
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}

# Colors - Catppuccin Mocha
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC

# Cursor colors
cursor                  #F5E0DC
cursor_text_color       #1E1E2E

# URL underline color when hovering
url_color               #F5E0DC

# Kitty window border colors
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Colors for marks (marked text in the terminal)
mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC

# The 16 terminal colors

# normal
color0 #45475A
color1 #F38BA8
color2 #A6E3A1
color3 #F9E2AF
color4 #89B4FA
color5 #F5C2E7
color6 #94E2D5
color7 #BAC2DE

# bright
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Mouse
mouse_hide_wait 3.0
url_style curly
open_url_with default
url_prefixes http https file ftp gemini irc gopher mailto news git
detect_urls yes
copy_on_select no
strip_trailing_spaces never
select_by_word_characters @-./_~?&=%+#

# Advanced
shell .
editor .
close_on_child_death no
allow_remote_control no
update_check_interval 24
startup_session none
clipboard_control write-clipboard write-primary
allow_hyperlinks yes
shell_integration enabled
EOF
}

# Kitty Catppuccin Macchiato
create_kitty_catppuccin_macchiato() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - Catppuccin Macchiato Theme

# Font
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Window
initial_window_width  1200
initial_window_height 800
window_padding_width 12
window_margin_width 0
single_window_margin_width -1
window_border_width 0.5pt
draw_minimal_borders yes
hide_window_decorations no

# Tabs
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted

# Colors - Catppuccin Macchiato
foreground              #CAD3F5
background              #24273A
selection_foreground    #24273A
selection_background    #F4DBD6

cursor                  #F4DBD6
cursor_text_color       #24273A

url_color               #F4DBD6

active_border_color     #B7BDF8
inactive_border_color   #6E738D
bell_border_color       #EED49F

active_tab_foreground   #181926
active_tab_background   #C6A0F6
inactive_tab_foreground #CAD3F5
inactive_tab_background #1E2030
tab_bar_background      #181926

# The 16 terminal colors
color0 #494D64
color1 #ED8796
color2 #A6DA95
color3 #EED49F
color4 #8AADF4
color5 #F5BDE6
color6 #8BD5CA
color7 #B8C0E0
color8 #5B6078
color9 #ED8796
color10 #A6DA95
color11 #EED49F
color12 #8AADF4
color13 #F5BDE6
color14 #8BD5CA
color15 #A5ADCB

# Performance and settings
repaint_delay 10
input_delay 3
sync_to_monitor yes
enable_audio_bell no
visual_bell_duration 0.0
mouse_hide_wait 3.0
url_style curly
open_url_with default
detect_urls yes
copy_on_select no
shell_integration enabled
EOF
}

# I'll continue with the other Kitty themes...
create_kitty_tokyonight() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - TokyoNight Theme

font_family      JetBrainsMono Nerd Font
font_size 12.0
cursor_shape block
window_padding_width 12

# TokyoNight colors
foreground #c0caf5
background #1a1b26
selection_foreground #1a1b26
selection_background #c0caf5

cursor #c0caf5
cursor_text_color #1a1b26

url_color #7aa2f7

active_border_color #7aa2f7
inactive_border_color #414868
bell_border_color #e0af68

active_tab_foreground #1a1b26
active_tab_background #7aa2f7
inactive_tab_foreground #c0caf5
inactive_tab_background #24283b
tab_bar_background #1a1b26

# Terminal colors
color0 #15161e
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6
color8 #414868
color9 #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5

tab_bar_edge bottom
tab_bar_style powerline
enable_audio_bell no
shell_integration enabled
EOF
}

create_kitty_gruvbox() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - Gruvbox Theme

font_family      JetBrainsMono Nerd Font
font_size 12.0
cursor_shape block
window_padding_width 12

# Gruvbox colors
foreground #ebdbb2
background #282828
selection_foreground #282828
selection_background #ebdbb2

cursor #ebdbb2
cursor_text_color #282828

url_color #fe8019

active_border_color #d79921
inactive_border_color #504945
bell_border_color #fabd2f

active_tab_foreground #282828
active_tab_background #d79921
inactive_tab_foreground #ebdbb2
inactive_tab_background #3c3836
tab_bar_background #282828

# Terminal colors
color0 #282828
color1 #cc241d
color2 #98971a
color3 #d79921
color4 #458588
color5 #b16286
color6 #689d6a
color7 #a89984
color8 #928374
color9 #fb4934
color10 #b8bb26
color11 #fabd2f
color12 #83a598
color13 #d3869b
color14 #8ec07c
color15 #ebdbb2

tab_bar_edge bottom
tab_bar_style powerline
enable_audio_bell no
shell_integration enabled
EOF
}

create_kitty_nord() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - Nord Theme

font_family      JetBrainsMono Nerd Font
font_size 12.0
cursor_shape block
window_padding_width 12

# Nord colors
foreground #d8dee9
background #2e3440
selection_foreground #2e3440
selection_background #d8dee9

cursor #d8dee9
cursor_text_color #2e3440

url_color #88c0d0

active_border_color #88c0d0
inactive_border_color #4c566a
bell_border_color #ebcb8b

active_tab_foreground #2e3440
active_tab_background #88c0d0
inactive_tab_foreground #d8dee9
inactive_tab_background #3b4252
tab_bar_background #2e3440

# Terminal colors
color0 #3b4252
color1 #bf616a
color2 #a3be8c
color3 #ebcb8b
color4 #81a1c1
color5 #b48ead
color6 #88c0d0
color7 #e5e9f0
color8 #4c566a
color9 #bf616a
color10 #a3be8c
color11 #ebcb8b
color12 #81a1c1
color13 #b48ead
color14 #8fbcbb
color15 #eceff4

tab_bar_edge bottom
tab_bar_style powerline
enable_audio_bell no
shell_integration enabled
EOF
}

create_kitty_rosepine() {
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Kitty Configuration - Rose Pine Theme

font_family      JetBrainsMono Nerd Font
font_size 12.0
cursor_shape block
window_padding_width 12

# Rose Pine colors
foreground #e0def4
background #191724
selection_foreground #191724
selection_background #e0def4

cursor #e0def4
cursor_text_color #191724

url_color #ebbcba

active_border_color #ebbcba
inactive_border_color #26233a
bell_border_color #f6c177

active_tab_foreground #191724
active_tab_background #ebbcba
inactive_tab_foreground #e0def4
inactive_tab_background #1f1d2e
tab_bar_background #191724

# Terminal colors
color0 #26233a
color1 #eb6f92
color2 #31748f
color3 #f6c177
color4 #9ccfd8
color5 #c4a7e7
color6 #ebbcba
color7 #e0def4
color8 #6e6a86
color9 #eb6f92
color10 #31748f
color11 #f6c177
color12 #9ccfd8
color13 #c4a7e7
color14 #ebbcba
color15 #e0def4

tab_bar_edge bottom
tab_bar_style powerline
enable_audio_bell no
shell_integration enabled
EOF
}

# Create Dunst configuration for each theme
create_dunst_config() {
    local theme="$1"
    local bg="$2"
    local text="$3"
    local accent="$4"
    
    log "Creating Dunst configuration for $theme theme..."
    
    cat > "$HOME/.config/dunst/dunstrc" << EOF
[global]
    monitor = 0
    follow = mouse
    geometry = "350x5-15+49"
    indicate_hidden = yes
    shrink = yes
    transparency = 10
    notification_height = 0
    separator_height = 3
    padding = 12
    horizontal_padding = 12
    frame_width = 2
    frame_color = "$accent"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    
    # Text
    font = JetBrainsMono Nerd Font 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    
    # Icons
    icon_position = left
    min_icon_size = 32
    max_icon_size = 64
    icon_path = /usr/share/icons/Papirus/16x16/status/:/usr/share/icons/Papirus/16x16/devices/:/usr/share/icons/Papirus/16x16/apps/
    
    # History
    sticky_history = yes
    history_length = 20
    
    # Misc/Advanced
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    verbosity = mesg
    corner_radius = 12
    ignore_dbusclose = false
    force_xwayland = false
    force_xinerama = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[urgency_low]
    background = "$bg"
    foreground = "$text"
    timeout = 5
    icon = dialog-information

[urgency_normal]
    background = "$bg"
    foreground = "$text"
    timeout = 8
    icon = dialog-warning

[urgency_critical]
    background = "$bg"
    foreground = "$text"
    frame_color = "#f38ba8"
    timeout = 0
    icon = dialog-error

# Application-specific rules
[discord]
    appname = discord
    format = "<b>Discord</b>\\n%b"
    urgency = low

[spotify]
    appname = Spotify
    format = "<b>♪ Spotify</b>\\n%b"
    urgency = low

[volume]
    summary = "Volume*"
    format = "<b>🔊 Volume</b>\\n%b"
    urgency = low
    timeout = 2

[brightness]
    summary = "Brightness*"
    format = "<b>☀ Brightness</b>\\n%b"
    urgency = low
    timeout = 2

[network]
    appname = NetworkManager
    format = "<b>🌐 Network</b>\\n%b"
    urgency = low

[battery]
    summary = "*attery*"
    format = "<b>🔋 Battery</b>\\n%b"
    urgency = normal

[screenshot]
    appname = grim
    format = "<b>📷 Screenshot</b>\\n%b"
    urgency = low
    timeout = 3
EOF

    success "Dunst configuration created for $theme theme"
}
