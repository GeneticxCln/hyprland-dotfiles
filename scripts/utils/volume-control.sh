#!/bin/bash
# Advanced Volume Control with Device Switching
# Comprehensive audio management for Hyprland

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
STEP="${VOLUME_STEP:-5}"
MAX_VOLUME="${VOLUME_MAX:-100}"

# Logging
log() { echo -e "${BLUE}[VOLUME]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Get current volume and mute status
get_volume_info() {
    local sink=$(pactl get-default-sink)
    local volume=$(pactl get-sink-volume "$sink" | grep -o '[0-9]\+%' | head -1 | tr -d '%')
    local muted=$(pactl get-sink-mute "$sink" | grep -o 'yes\|no')
    echo "$volume $muted"
}

# Show OSD notification
show_osd() {
    local volume="$1"
    local muted="$2"
    local icon="🔊"
    local message="Volume: $volume%"
    
    if [ "$muted" = "yes" ]; then
        icon="🔇"
        message="Volume: Muted"
    elif [ "$volume" -eq 0 ]; then
        icon="🔇"
    elif [ "$volume" -le 33 ]; then
        icon="🔈"
    elif [ "$volume" -le 66 ]; then
        icon="🔉"
    fi
    
    local bar_length=20
    local filled=$((volume * bar_length / 100))
    local empty=$((bar_length - filled))
    
    local bar=""
    if [ "$muted" = "yes" ]; then
        for ((i=0; i<bar_length; i++)); do bar+="▪"; done
    else
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
    fi
    
    notify-send "$icon $message" "[$bar]" \
        -h int:value:$volume \
        -h string:x-canonical-private-synchronous:volume \
        -t 2000 2>/dev/null || true
}

# Increase volume
increase() {
    local step="${1:-$STEP}"
    local sink=$(pactl get-default-sink)
    
    pactl set-sink-volume "$sink" "+${step}%"
    
    # Ensure we don't exceed max volume
    local new_volume=$(pactl get-sink-volume "$sink" | grep -o '[0-9]\+%' | head -1 | tr -d '%')
    if [ "$new_volume" -gt "$MAX_VOLUME" ]; then
        pactl set-sink-volume "$sink" "${MAX_VOLUME}%"
        new_volume="$MAX_VOLUME"
    fi
    
    # Unmute if muted
    pactl set-sink-mute "$sink" no
    
    show_osd "$new_volume" "no"
    success "Volume increased to $new_volume%"
}

# Decrease volume
decrease() {
    local step="${1:-$STEP}"
    local sink=$(pactl get-default-sink)
    
    pactl set-sink-volume "$sink" "-${step}%"
    
    local info=($(get_volume_info))
    show_osd "${info[0]}" "${info[1]}"
    success "Volume decreased to ${info[0]}%"
}

# Set specific volume
set_volume() {
    local percent="$1"
    if [[ ! "$percent" =~ ^[0-9]+$ ]] || [ "$percent" -lt 0 ] || [ "$percent" -gt "$MAX_VOLUME" ]; then
        warning "Invalid volume value. Use 0-$MAX_VOLUME"
        return 1
    fi
    
    local sink=$(pactl get-default-sink)
    pactl set-sink-volume "$sink" "${percent}%"
    pactl set-sink-mute "$sink" no
    
    show_osd "$percent" "no"
    success "Volume set to $percent%"
}

# Toggle mute
toggle_mute() {
    local sink=$(pactl get-default-sink)
    pactl set-sink-mute "$sink" toggle
    
    local info=($(get_volume_info))
    show_osd "${info[0]}" "${info[1]}"
    
    if [ "${info[1]}" = "yes" ]; then
        success "Audio muted"
    else
        success "Audio unmuted"
    fi
}

# Get current status
get_status() {
    local sink=$(pactl get-default-sink)
    local sink_info=$(pactl list short sinks | grep "$sink")
    local sink_name=$(echo "$sink_info" | awk '{print $2}')
    local info=($(get_volume_info))
    
    echo -e "${GREEN}Current Audio Status:${NC}"
    echo -e "${GREEN}Device:${NC} $sink_name"
    echo -e "${GREEN}Volume:${NC} ${info[0]}%"
    echo -e "${GREEN}Muted:${NC} ${info[1]}"
}

# List available audio devices
list_devices() {
    echo -e "${GREEN}Available Audio Devices:${NC}"
    echo
    echo "Sinks (Output):"
    pactl list short sinks | while read -r line; do
        local id=$(echo "$line" | awk '{print $1}')
        local name=$(echo "$line" | awk '{print $2}')
        local desc=$(pactl list sinks | grep -A 20 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
        local default=""
        if [ "$name" = "$(pactl get-default-sink)" ]; then
            default=" ${GREEN}[DEFAULT]${NC}"
        fi
        echo -e "  $id: $desc$default"
    done
    
    echo
    echo "Sources (Input):"
    pactl list short sources | while read -r line; do
        local id=$(echo "$line" | awk '{print $1}')
        local name=$(echo "$line" | awk '{print $2}')
        local desc=$(pactl list sources | grep -A 20 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
        local default=""
        if [ "$name" = "$(pactl get-default-source)" ]; then
            default=" ${GREEN}[DEFAULT]${NC}"
        fi
        echo -e "  $id: $desc$default"
    done
}

# Switch audio device
switch_device() {
    local device_id="$1"
    local device_type="${2:-sink}"
    
    if [ -z "$device_id" ]; then
        warning "Device ID required"
        return 1
    fi
    
    if [ "$device_type" = "sink" ]; then
        pactl set-default-sink "$device_id"
        success "Default sink switched to device $device_id"
    else
        pactl set-default-source "$device_id"
        success "Default source switched to device $device_id"
    fi
}

# Microphone controls
mic_toggle() {
    local source=$(pactl get-default-source)
    pactl set-source-mute "$source" toggle
    
    local muted=$(pactl get-source-mute "$source" | grep -o 'yes\|no')
    if [ "$muted" = "yes" ]; then
        notify-send "🎤" "Microphone Muted" -t 2000 2>/dev/null || true
        success "Microphone muted"
    else
        notify-send "🎤" "Microphone Active" -t 2000 2>/dev/null || true
        success "Microphone unmuted"
    fi
}

# Show help
show_help() {
    echo "Usage: volume-control [command] [value]"
    echo
    echo "Volume Commands:"
    echo "  up, + [step]       Increase volume (default: 5%)"
    echo "  down, - [step]     Decrease volume (default: 5%)"
    echo "  set [percent]      Set specific volume (0-$MAX_VOLUME%)"
    echo "  mute, toggle       Toggle mute"
    echo "  get, status        Show current volume status"
    echo
    echo "Device Commands:"
    echo "  list               List available audio devices"
    echo "  switch [id] [type] Switch device (type: sink/source)"
    echo
    echo "Microphone Commands:"
    echo "  mic-toggle         Toggle microphone mute"
    echo
    echo "  help               Show this help message"
    echo
}

# Main execution
case "${1:-help}" in
    up|+) increase "$2" ;;
    down|-) decrease "$2" ;;
    set) set_volume "$2" ;;
    mute|toggle) toggle_mute ;;
    get|status) get_status ;;
    list) list_devices ;;
    switch) switch_device "$2" "$3" ;;
    mic-toggle) mic_toggle ;;
    help|*) show_help ;;
esac
