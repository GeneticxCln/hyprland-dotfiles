#!/bin/bash
# Enhanced Rofi Launcher for Hyprland Dotfiles
# Beautiful application launcher with system integration

# Configuration
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
THEME="$HOME/.config/rofi/themes/launcher.rasi"

# Ensure rofi config exists
mkdir -p "$HOME/.config/rofi/themes"

# Create launcher theme if it doesn't exist
if [ ! -f "$THEME" ]; then
    cat > "$THEME" << 'EOF'
// Enhanced Launcher Theme for Hyprland Dotfiles
configuration {
    modi: "drun,run,window,ssh,combi";
    font: "JetBrainsMono Nerd Font 12";
    combi-modi: "drun,run";
    display-drun: "Applications";
    display-run: "Commands";
    display-window: "Windows";
    display-combi: "All";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    drun-display-format: "{name}";
    disable-history: false;
    hide-scrollbar: true;
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
    width: 50%;
    background-color: @bg;
    border: 2px solid @bg-selected;
    border-radius: 12px;
    padding: 20px;
}

mainbox {
    children: [inputbar, listview];
    spacing: 20px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 8px;
    padding: 12px;
    spacing: 10px;
}

prompt {
    text-color: @bg-selected;
    font: "JetBrainsMono Nerd Font Bold 14";
}

entry {
    placeholder: "Search applications...";
    text-color: @fg;
    placeholder-color: @fg-alt;
    cursor: text;
}

listview {
    lines: 8;
    columns: 1;
    fixed-height: false;
    scrollbar: false;
    spacing: 5px;
    padding: 5px 0;
}

element {
    children: [element-icon, element-text];
    orientation: horizontal;
    padding: 12px;
    spacing: 12px;
    border-radius: 8px;
    text-color: @fg;
}

element selected {
    background-color: @bg-selected;
    text-color: @bg;
}

element-icon {
    size: 32px;
    cursor: pointer;
}

element-text {
    cursor: pointer;
    font: "JetBrainsMono Nerd Font 11";
}
EOF
fi

# Launch rofi with custom theme and options
rofi -no-lazy-grab -show drun \
    -theme "$THEME" \
    -drun-categories "AudioVideo,Audio,Video,Development,Education,Game,Graphics,Network,Office,Science,Settings,System,Utility" \
    -drun-match-fields "name,generic,exec,categories,keywords" \
    -drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]" \
    -kb-primary-paste "Control+V,Shift+Insert" \
    -kb-secondary-paste "Control+v" \
    -kb-clear-line "Control+c" \
    -kb-move-front "Control+a" \
    -kb-move-end "Control+e" \
    -kb-move-word-back "Alt+b,Control+Left" \
    -kb-move-word-forward "Alt+f,Control+Right" \
    -kb-move-char-back "Left,Control+b" \
    -kb-move-char-forward "Right,Control+f" \
    -kb-remove-word-back "Control+Alt+h,Control+BackSpace" \
    -kb-remove-word-forward "Control+Alt+d" \
    -kb-remove-char-forward "Delete,Control+d" \
    -kb-remove-char-back "BackSpace,Shift+BackSpace,Control+h" \
    -kb-accept-entry "Control+j,Control+m,Return,KP_Enter" \
    -kb-accept-custom "Control+Return" \
    -kb-accept-alt "Shift+Return" \
    -kb-delete-entry "Shift+Delete" \
    -kb-mode-next "Shift+Right,Control+Tab" \
    -kb-mode-previous "Shift+Left,Control+ISO_Left_Tab" \
    -kb-row-left "Control+Page_Up" \
    -kb-row-right "Control+Page_Down" \
    -kb-row-up "Up,Control+p,ISO_Left_Tab" \
    -kb-row-down "Down,Control+n" \
    -kb-row-tab "Tab" \
    -kb-page-prev "Page_Up" \
    -kb-page-next "Page_Down" \
    -kb-row-first "Home,KP_Home" \
    -kb-row-last "End,KP_End" \
    -kb-row-select "Control+space" \
    -kb-screenshot "Alt+S" \
    -kb-ellipsize "Alt+period" \
    -kb-toggle-case-sensitivity "grave,dead_grave" \
    -kb-toggle-sort "Alt+grave" \
    -kb-cancel "Escape,Control+g,Control+bracketleft" \
    -kb-custom-1 "Alt+1" \
    -kb-custom-2 "Alt+2" \
    -kb-custom-3 "Alt+3" \
    -kb-custom-4 "Alt+4" \
    -kb-custom-5 "Alt+5" \
    -kb-custom-6 "Alt+6" \
    -kb-custom-7 "Alt+7" \
    -kb-custom-8 "Alt+8" \
    -kb-custom-9 "Alt+9" \
    -kb-custom-10 "Alt+0" \
    -kb-custom-11 "Alt+exclam" \
    -kb-custom-12 "Alt+at" \
    -kb-custom-13 "Alt+numbersign" \
    -kb-custom-14 "Alt+dollar" \
    -kb-custom-15 "Alt+percent" \
    -kb-custom-16 "Alt+dead_circumflex" \
    -kb-custom-17 "Alt+ampersand" \
    -kb-custom-18 "Alt+asterisk" \
    -kb-custom-19 "Alt+parenleft"
