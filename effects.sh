#!/bin/bash

# Advanced Transparency and Blur Effects for Hyprland
# This module provides customizable transparency and blur settings for all themes

# Default blur parameters
BLUR_ENABLED=true
BLUR_SIZE=8
BLUR_PASSES=3
BLUR_VIBRANCY=0.4
BLUR_NOISE=0.0
BLUR_CONTRAST=1.0
BLUR_BRIGHTNESS=1.0
BLUR_XRAY=true

# Default transparency parameters (0.0 = fully transparent, 1.0 = fully opaque)
TRANSPARENCY_ACTIVE=0.92    # Active window transparency
TRANSPARENCY_INACTIVE=0.85  # Inactive window transparency
TRANSPARENCY_DESKTOP=0.70   # Desktop elements transparency
TRANSPARENCY_PANEL=0.80     # Panels transparency
TRANSPARENCY_MENU=0.90      # Menus and popups transparency
TRANSPARENCY_TERMINAL=0.85  # Terminal transparency

# Global transparency toggle
ENABLE_TRANSPARENCY=true

# Apply blur effect based on theme
apply_blur_theme() {
    local theme="$1"
    
    case $theme in
        # Dark themes get more blur
        "Catppuccin-Mocha"|"TokyoNight-Night"|"Dracula"|"Nord"|"Rose-Pine"|"Gruvbox-Dark"|"Solarized-Dark"|"Everforest-Dark"|"Monokai-Pro")
            BLUR_SIZE=8
            BLUR_PASSES=3
            BLUR_VIBRANCY=0.4
            BLUR_CONTRAST=1.1
            ;;
        # Light themes get more subtle blur
        "Catppuccin-Latte"|"TokyoNight-Day"|"Rose-Pine-Dawn"|"Gruvbox-Light"|"Solarized-Light"|"Everforest-Light"|"Nord-Light")
            BLUR_SIZE=6
            BLUR_PASSES=2
            BLUR_VIBRANCY=0.2
            BLUR_CONTRAST=0.9
            ;;
        # Medium themes get balanced blur
        *)
            BLUR_SIZE=7
            BLUR_PASSES=2
            BLUR_VIBRANCY=0.3
            BLUR_CONTRAST=1.0
            ;;
    esac
}

# Apply transparency based on theme
apply_transparency_theme() {
    local theme="$1"
    
    case $theme in
        # Dark themes look better with more transparency
        "Catppuccin-Mocha"|"TokyoNight-Night"|"Dracula"|"Nord"|"Rose-Pine")
            TRANSPARENCY_ACTIVE=0.95
            TRANSPARENCY_INACTIVE=0.85
            TRANSPARENCY_DESKTOP=0.70
            TRANSPARENCY_PANEL=0.85
            TRANSPARENCY_MENU=0.92
            TRANSPARENCY_TERMINAL=0.87
            ;;
        # Light themes need less transparency to maintain contrast
        "Catppuccin-Latte"|"TokyoNight-Day"|"Rose-Pine-Dawn"|"Gruvbox-Light"|"Solarized-Light"|"Everforest-Light"|"Nord-Light")
            TRANSPARENCY_ACTIVE=0.97
            TRANSPARENCY_INACTIVE=0.92
            TRANSPARENCY_DESKTOP=0.85
            TRANSPARENCY_PANEL=0.92
            TRANSPARENCY_MENU=0.95
            TRANSPARENCY_TERMINAL=0.95
            ;;
        # Medium themes get balanced transparency
        *)
            TRANSPARENCY_ACTIVE=0.96
            TRANSPARENCY_INACTIVE=0.88
            TRANSPARENCY_DESKTOP=0.75
            TRANSPARENCY_PANEL=0.90
            TRANSPARENCY_MENU=0.93
            TRANSPARENCY_TERMINAL=0.90
            ;;
    esac
}

# Generate Hyprland blur and transparency configuration
generate_hyprland_blur_config() {
    local theme="$1"
    
    apply_blur_theme "$theme"
    apply_transparency_theme "$theme"
    
    # Generate the Hyprland blur configuration
    if [ "$BLUR_ENABLED" = true ]; then
        cat << EOF
# Blur and transparency configuration for $theme
decoration {
    blur {
        enabled = true
        size = $BLUR_SIZE
        passes = $BLUR_PASSES
        new_optimizations = true
        xray = $BLUR_XRAY
        noise = $BLUR_NOISE
        contrast = $BLUR_CONTRAST
        brightness = $BLUR_BRIGHTNESS
        vibrancy = $BLUR_VIBRANCY
    }
}

# Transparency configuration
general {
    # ...other settings...
    col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.inactive_border = rgba(6c708680)
}

# Window transparency rules
windowrulev2 = opacity $TRANSPARENCY_ACTIVE $TRANSPARENCY_INACTIVE,class:^((?!.*firefox).*)\$
windowrulev2 = opacity $TRANSPARENCY_TERMINAL $TRANSPARENCY_TERMINAL,class:^(kitty|alacritty)$
windowrulev2 = opacity $TRANSPARENCY_MENU $TRANSPARENCY_MENU,class:^(rofi|wofi|dmenu)$
windowrulev2 = opacity $TRANSPARENCY_PANEL $TRANSPARENCY_PANEL,class:^(waybar|quickshell)$

# No transparency for specific apps
windowrulev2 = opacity 1.0 1.0,class:^(firefox|chromium|brave-browser)$
windowrulev2 = opacity 1.0 1.0,class:^(vlc|mpv|org.videolan.VLC)$
windowrulev2 = opacity 1.0 1.0,class:^(gimp|inkscape|krita)$
windowrulev2 = opacity 1.0 1.0,class:^(virt-manager|virtualbox)$
EOF
    else
        cat << EOF
# Blur disabled for $theme
decoration {
    blur {
        enabled = false
    }
}

# No transparency - all windows are opaque
general {
    # ...other settings...
    col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.inactive_border = rgba(6c708680)
}
EOF
    fi
}

# Apply blur to waybar config
apply_waybar_blur() {
    local theme="$1"
    local bg="$2"
    local surface0="$3"
    
    # Extract transparency values based on theme
    apply_transparency_theme "$theme"
    
    # Convert hex bg to rgba with transparency
    local r=$(printf "%d" 0x${bg:1:2})
    local g=$(printf "%d" 0x${bg:3:2})
    local b=$(printf "%d" 0x${bg:5:2})
    
    # Different transparency for panel
    local panel_alpha=$TRANSPARENCY_PANEL
    
    # Return the RGBA background color with transparency
    echo "rgba($r, $g, $b, $panel_alpha)"
}

# Apply blur to rofi config
apply_rofi_blur() {
    local theme="$1"
    local bg="$2"
    
    # Extract transparency values based on theme
    apply_transparency_theme "$theme"
    
    # Convert hex bg to rgba with transparency
    local r=$(printf "%d" 0x${bg:1:2})
    local g=$(printf "%d" 0x${bg:3:2})
    local b=$(printf "%d" 0x${bg:5:2})
    
    # Use menu transparency for rofi
    local menu_alpha=$TRANSPARENCY_MENU
    
    # Return the RGBA background color with transparency
    echo "rgba($r, $g, $b, $menu_alpha)"
}

# Apply blur to quickshell components
apply_quickshell_blur() {
    local theme="$1"
    local component="$2"  # panel, widget, etc.
    local bg="$3"
    
    # Extract transparency values based on theme
    apply_transparency_theme "$theme"
    
    # Convert hex bg to rgba with transparency
    local r=$(printf "%d" 0x${bg:1:2})
    local g=$(printf "%d" 0x${bg:3:2})
    local b=$(printf "%d" 0x${bg:5:2})
    
    # Different alpha for different components
    local alpha
    case $component in
        "panel") 
            alpha=$TRANSPARENCY_PANEL
            ;;
        "widget")
            alpha=$TRANSPARENCY_DESKTOP
            ;;
        "menu")
            alpha=$TRANSPARENCY_MENU
            ;;
        *)
            alpha=$TRANSPARENCY_DESKTOP
            ;;
    esac
    
    # Return the RGBA background color with transparency
    echo "rgba($r, $g, $b, $alpha)"
}

# Apply Kitty terminal transparency
apply_kitty_transparency() {
    local theme="$1"
    
    # Extract transparency values based on theme
    apply_transparency_theme "$theme"
    
    # Calculate opacity from transparency (inverse)
    local opacity=$(echo "scale=2; 1 - $TRANSPARENCY_TERMINAL" | bc)
    
    # Return the opacity setting for kitty
    echo "background_opacity $opacity"
}

# Apply dunst transparency
apply_dunst_transparency() {
    local theme="$1"
    local bg="$2"
    
    # Extract transparency values based on theme
    apply_transparency_theme "$theme"
    
    # Use a value suitable for dunst (0-100)
    local dunst_transparency=$(echo "scale=0; (1 - $TRANSPARENCY_MENU) * 100 / 1" | bc)
    
    # Return the transparency setting for dunst
    echo "$dunst_transparency"
}

# Helper to create blur effect shader for QML
create_blur_effect_qml() {
    local strength="$1"
    
    cat << EOF
ShaderEffect {
    property real blurRadius: $strength
    property variant source: effectSource
    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform sampler2D source;
        uniform lowp float qt_Opacity;
        uniform highp float blurRadius;
        void main() {
            highp vec2 offset = vec2(0.0, 0.0);
            lowp vec4 col = texture2D(source, qt_TexCoord0);
            if (blurRadius > 0.0) {
                for (highp float x = -blurRadius; x <= blurRadius; x += 1.0) {
                    for (highp float y = -blurRadius; y <= blurRadius; y += 1.0) {
                        offset = vec2(x, y) / 100.0;
                        col += texture2D(source, qt_TexCoord0 + offset);
                    }
                }
                col /= pow(2.0 * blurRadius + 1.0, 2.0);
            }
            gl_FragColor = col * qt_Opacity;
        }
    "
}
EOF
}

# Main function to initialize blur and transparency
init_effects() {
    local theme="$1"
    
    log "Initializing transparency and blur effects for theme: $theme"
    
    # Apply theme-specific blur and transparency settings
    apply_blur_theme "$theme"
    apply_transparency_theme "$theme"
    
    success "Effects initialized for theme: $theme"
}
