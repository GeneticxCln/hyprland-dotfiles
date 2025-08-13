#!/bin/bash

# 20 Complete Theme Deployment Functions
# Each theme includes Hyprland, Waybar, Quickshell, Rofi, Kitty, Dunst configurations

# CATPPUCCIN THEMES (4 variants)
deploy_catppuccin_mocha() {
    local bg="#1e1e2e" surface0="#313244" text="#cdd6f4" accent="#cba6f7" accent2="#89b4fa"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "catppuccin-mocha" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "catppuccin-mocha" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "catppuccin-mocha" "$bg" "$text" "$accent"
    create_kitty_config "catppuccin-mocha"
    create_dunst_config "catppuccin-mocha" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "mocha"
}

deploy_catppuccin_macchiato() {
    local bg="#24273a" surface0="#363a4f" text="#cad3f5" accent="#c6a0f6" accent2="#8aadf4"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "catppuccin-macchiato" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "catppuccin-macchiato" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "catppuccin-macchiato" "$bg" "$text" "$accent"
    create_kitty_config "catppuccin-macchiato"
    create_dunst_config "catppuccin-macchiato" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "macchiato"
}

deploy_catppuccin_latte() {
    local bg="#eff1f5" surface0="#e6e9ef" text="#4c4f69" accent="#8839ef" accent2="#1e66f5"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "catppuccin-latte" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "catppuccin-latte" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "catppuccin-latte" "$bg" "$text" "$accent"
    create_kitty_config "catppuccin-latte"
    create_dunst_config "catppuccin-latte" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "latte"
}

deploy_catppuccin_frappe() {
    local bg="#303446" surface0="#414559" text="#c6d0f5" accent="#ca9ee6" accent2="#8caaee"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "catppuccin-frappe" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "catppuccin-frappe" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "catppuccin-frappe" "$bg" "$text" "$accent"
    create_kitty_config "catppuccin-frappe"
    create_dunst_config "catppuccin-frappe" "$bg" "$text" "$accent2"
    download_wallpapers_catppuccin "frappe"
}

# TOKYONIGHT THEMES (3 variants)
deploy_tokyonight_night() {
    local bg="#1a1b26" surface0="#24283b" text="#c0caf5" accent="#7aa2f7" accent2="#bb9af7"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight-night" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-night" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-night" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-night"
    create_dunst_config "tokyonight-night" "$bg" "$text" "$accent"
    download_wallpapers_tokyonight "night"
}

deploy_tokyonight_storm() {
    local bg="#24283b" surface0="#414868" text="#c0caf5" accent="#7aa2f7" accent2="#bb9af7"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight-storm" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-storm" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-storm" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-storm"
    create_dunst_config "tokyonight-storm" "$bg" "$text" "$accent"
    download_wallpapers_tokyonight "storm"
}

deploy_tokyonight_day() {
    local bg="#e1e2e7" surface0="#e9e9ed" text="#3760bf" accent="#2e7de9" accent2="#188092"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "tokyonight-day" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "tokyonight-day" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "tokyonight-day" "$bg" "$text" "$accent"
    create_kitty_config "tokyonight-day"
    create_dunst_config "tokyonight-day" "$bg" "$text" "$accent"
    download_wallpapers_tokyonight "day"
}

# GRUVBOX THEMES (2 variants)
deploy_gruvbox_dark() {
    local bg="#282828" surface0="#3c3836" text="#ebdbb2" accent="#d79921" accent2="#458588"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "gruvbox-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "gruvbox-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "gruvbox-dark" "$bg" "$text" "$accent"
    create_kitty_config "gruvbox-dark"
    create_dunst_config "gruvbox-dark" "$bg" "$text" "$accent2"
    download_wallpapers_gruvbox "dark"
}

deploy_gruvbox_light() {
    local bg="#fbf1c7" surface0="#f2e5bc" text="#3c3836" accent="#b57614" accent2="#076678"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "gruvbox-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "gruvbox-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "gruvbox-light" "$bg" "$text" "$accent"
    create_kitty_config "gruvbox-light"
    create_dunst_config "gruvbox-light" "$bg" "$text" "$accent2"
    download_wallpapers_gruvbox "light"
}

# NORD THEMES (2 variants)
deploy_nord() {
    local bg="#2e3440" surface0="#3b4252" text="#eceff4" accent="#88c0d0" accent2="#8fbcbb"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "nord" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "nord" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "nord" "$bg" "$text" "$accent"
    create_kitty_config "nord"
    create_dunst_config "nord" "$bg" "$text" "$accent"
    download_wallpapers_nord "dark"
}

deploy_nord_light() {
    local bg="#eceff4" surface0="#e5e9f0" text="#2e3440" accent="#5e81ac" accent2="#81a1c1"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "nord-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "nord-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "nord-light" "$bg" "$text" "$accent"
    create_kitty_config "nord-light"
    create_dunst_config "nord-light" "$bg" "$text" "$accent"
    download_wallpapers_nord "light"
}

# ROSE PINE THEMES (3 variants)
deploy_rose_pine() {
    local bg="#191724" surface0="#1f1d2e" text="#e0def4" accent="#ebbcba" accent2="#c4a7e7"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rose-pine" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rose-pine" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rose-pine" "$bg" "$text" "$accent"
    create_kitty_config "rose-pine"
    create_dunst_config "rose-pine" "$bg" "$text" "$accent2"
    download_wallpapers_rosepine "base"
}

deploy_rose_pine_moon() {
    local bg="#232136" surface0="#2a273f" text="#e0def4" accent="#ea9a97" accent2="#c4a7e7"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rose-pine-moon" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rose-pine-moon" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rose-pine-moon" "$bg" "$text" "$accent"
    create_kitty_config "rose-pine-moon"
    create_dunst_config "rose-pine-moon" "$bg" "$text" "$accent2"
    download_wallpapers_rosepine "moon"
}

deploy_rose_pine_dawn() {
    local bg="#faf4ed" surface0="#f2e9de" text="#575279" accent="#d7827e" accent2="#907aa9"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "rose-pine-dawn" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "rose-pine-dawn" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "rose-pine-dawn" "$bg" "$text" "$accent"
    create_kitty_config "rose-pine-dawn"
    create_dunst_config "rose-pine-dawn" "$bg" "$text" "$accent2"
    download_wallpapers_rosepine "dawn"
}

# DRACULA THEME
deploy_dracula() {
    local bg="#282a36" surface0="#44475a" text="#f8f8f2" accent="#bd93f9" accent2="#8be9fd"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "dracula" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "dracula" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "dracula" "$bg" "$text" "$accent"
    create_kitty_config "dracula"
    create_dunst_config "dracula" "$bg" "$text" "$accent2"
    download_wallpapers_dracula
}

# MONOKAI PRO THEME
deploy_monokai_pro() {
    local bg="#2d2a2e" surface0="#403e41" text="#fcfcfa" accent="#ff6188" accent2="#78dce8"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "monokai-pro" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "monokai-pro" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "monokai-pro" "$bg" "$text" "$accent"
    create_kitty_config "monokai-pro"
    create_dunst_config "monokai-pro" "$bg" "$text" "$accent2"
    download_wallpapers_monokai
}

# SOLARIZED THEMES (2 variants)
deploy_solarized_dark() {
    local bg="#002b36" surface0="#073642" text="#839496" accent="#268bd2" accent2="#2aa198"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "solarized-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "solarized-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "solarized-dark" "$bg" "$text" "$accent"
    create_kitty_config "solarized-dark"
    create_dunst_config "solarized-dark" "$bg" "$text" "$accent"
    download_wallpapers_solarized "dark"
}

deploy_solarized_light() {
    local bg="#fdf6e3" surface0="#eee8d5" text="#657b83" accent="#268bd2" accent2="#2aa198"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "solarized-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "solarized-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "solarized-light" "$bg" "$text" "$accent"
    create_kitty_config "solarized-light"
    create_dunst_config "solarized-light" "$bg" "$text" "$accent"
    download_wallpapers_solarized "light"
}

# EVERFOREST THEMES (2 variants)
deploy_everforest_dark() {
    local bg="#2d353b" surface0="#343f44" text="#d3c6aa" accent="#a7c080" accent2="#7fbbb3"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "everforest-dark" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "everforest-dark" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "everforest-dark" "$bg" "$text" "$accent"
    create_kitty_config "everforest-dark"
    create_dunst_config "everforest-dark" "$bg" "$text" "$accent2"
    download_wallpapers_everforest "dark"
}

deploy_everforest_light() {
    local bg="#f3ead3" surface0="#e6ddc2" text="#5c6a72" accent="#8da101" accent2="#35a77c"
    create_hyprland_config "$bg" "$surface0" "$accent" "$accent2" "$text"
    create_waybar_config "everforest-light" "$bg" "$surface0" "$text" "$accent"
    create_quickshell_config "everforest-light" "$bg" "$surface0" "$text" "$accent"
    create_rofi_config "everforest-light" "$bg" "$text" "$accent"
    create_kitty_config "everforest-light"
    create_dunst_config "everforest-light" "$bg" "$text" "$accent2"
    download_wallpapers_everforest "light"
}

# WALLPAPER FUNCTIONS FOR NEW THEMES
download_wallpapers_dracula() {
    log "Setting up Dracula wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#282a36"-"#44475a" "$HOME/Pictures/Wallpapers/dracula-1.jpg"
        convert -size 1920x1080 radial-gradient:"#bd93f9"-"#282a36" "$HOME/Pictures/Wallpapers/dracula-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/dracula-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_monokai() {
    log "Setting up Monokai Pro wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:"#2d2a2e"-"#403e41" "$HOME/Pictures/Wallpapers/monokai-1.jpg"
        convert -size 1920x1080 radial-gradient:"#ff6188"-"#2d2a2e" "$HOME/Pictures/Wallpapers/monokai-2.jpg"
        ln -sf "$HOME/Pictures/Wallpapers/monokai-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
    fi
}

download_wallpapers_solarized() {
    log "Setting up Solarized wallpapers ($1 variant)..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        case $1 in
            "dark")
                convert -size 1920x1080 gradient:"#002b36"-"#073642" "$HOME/Pictures/Wallpapers/solarized-dark-1.jpg"
                convert -size 1920x1080 radial-gradient:"#268bd2"-"#002b36" "$HOME/Pictures/Wallpapers/solarized-dark-2.jpg"
                ln -sf "$HOME/Pictures/Wallpapers/solarized-dark-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
                ;;
            "light")
                convert -size 1920x1080 gradient:"#fdf6e3"-"#eee8d5" "$HOME/Pictures/Wallpapers/solarized-light-1.jpg"
                convert -size 1920x1080 radial-gradient:"#268bd2"-"#fdf6e3" "$HOME/Pictures/Wallpapers/solarized-light-2.jpg"
                ln -sf "$HOME/Pictures/Wallpapers/solarized-light-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
                ;;
        esac
    fi
}

download_wallpapers_everforest() {
    log "Setting up Everforest wallpapers ($1 variant)..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    if command -v convert &> /dev/null; then
        case $1 in
            "dark")
                convert -size 1920x1080 gradient:"#2d353b"-"#343f44" "$HOME/Pictures/Wallpapers/everforest-dark-1.jpg"
                convert -size 1920x1080 radial-gradient:"#a7c080"-"#2d353b" "$HOME/Pictures/Wallpapers/everforest-dark-2.jpg"
                ln -sf "$HOME/Pictures/Wallpapers/everforest-dark-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
                ;;
            "light")
                convert -size 1920x1080 gradient:"#f3ead3"-"#e6ddc2" "$HOME/Pictures/Wallpapers/everforest-light-1.jpg"
                convert -size 1920x1080 radial-gradient:"#8da101"-"#f3ead3" "$HOME/Pictures/Wallpapers/everforest-light-2.jpg"
                ln -sf "$HOME/Pictures/Wallpapers/everforest-light-1.jpg" "$HOME/Pictures/Wallpapers/default.jpg"
                ;;
        esac
    fi
}
