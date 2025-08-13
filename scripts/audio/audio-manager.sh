#!/bin/bash
# Advanced Audio System Manager
# Comprehensive audio management with profiles, equalizer, and noise suppression

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
CONFIG_DIR="$HOME/.config/hypr/audio"
PROFILES_DIR="$CONFIG_DIR/profiles"
PRESETS_DIR="$CONFIG_DIR/presets"
RECORDINGS_DIR="$HOME/Music/Recordings"

# Logging
log() { echo -e "${BLUE}[AUDIO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Setup directories
setup_dirs() {
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR" "$PRESETS_DIR" "$RECORDINGS_DIR"
}

# Get audio device information
get_audio_info() {
    echo -e "${CYAN}=== Audio System Information ===${NC}"
    
    # PulseAudio/PipeWire info
    if command -v pactl >/dev/null 2>&1; then
        local server_info=$(pactl info 2>/dev/null)
        local server_name=$(echo "$server_info" | grep "Server Name" | cut -d: -f2- | sed 's/^ *//')
        local server_version=$(echo "$server_info" | grep "Server Version" | cut -d: -f2- | sed 's/^ *//')
        echo -e "${GREEN}Audio Server:${NC} $server_name"
        echo -e "${GREEN}Version:${NC} $server_version"
    fi
    
    echo
    echo -e "${GREEN}Output Devices:${NC}"
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
    echo -e "${GREEN}Input Devices:${NC}"
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

# Setup equalizer
setup_equalizer() {
    log "Setting up audio equalizer..."
    
    # Check for PulseEffects/EasyEffects
    if command -v easyeffects >/dev/null 2>&1; then
        log "Using EasyEffects (PipeWire)"
        setup_easyeffects
    elif command -v pulseeffects >/dev/null 2>&1; then
        log "Using PulseEffects (PulseAudio)"
        setup_pulseeffects
    else
        log "Installing audio effects software..."
        if command -v pacman >/dev/null 2>&1; then
            # Detect if using PipeWire or PulseAudio
            if pgrep -x "pipewire" > /dev/null; then
                sudo pacman -S --noconfirm easyeffects
                setup_easyeffects
            else
                sudo pacman -S --noconfirm pulseeffects
                setup_pulseeffects
            fi
        else
            warning "Please install PulseEffects or EasyEffects manually"
        fi
    fi
}

# Setup EasyEffects (PipeWire)
setup_easyeffects() {
    log "Configuring EasyEffects..."
    
    # Create configuration directory
    mkdir -p "$HOME/.config/easyeffects/output"
    mkdir -p "$HOME/.config/easyeffects/input"
    
    # Create basic preset
    cat > "$HOME/.config/easyeffects/output/Default.json" << 'EOF'
{
    "output": {
        "equalizer": {
            "bypass": false,
            "input-gain": 0.0,
            "output-gain": 0.0,
            "num-bands": 10,
            "split-channels": false,
            "left": {
                "band0": {
                    "frequency": 32.0,
                    "gain": 0.0,
                    "mode": "RLC (BT)",
                    "mute": false,
                    "q": 4.36,
                    "slope": "x1",
                    "solo": false,
                    "type": "Bell"
                }
            }
        }
    }
}
EOF
    
    # Enable autostart
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/easyeffects.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=easyeffects --gapplication-service
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=EasyEffects
Comment=Audio effects for PipeWire
EOF
    
    success "EasyEffects configured"
}

# Setup PulseEffects (PulseAudio)
setup_pulseeffects() {
    log "Configuring PulseEffects..."
    
    mkdir -p "$HOME/.config/PulseEffects"
    
    # Enable autostart
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/pulseeffects.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=pulseeffects --gapplication-service
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=PulseEffects
Comment=Audio effects for PulseAudio
EOF
    
    success "PulseEffects configured"
}

# Create audio profile
create_audio_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        read -p "Enter profile name: " profile_name
    fi
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    log "Creating audio profile: $profile_name"
    
    # Get current audio settings
    local default_sink=$(pactl get-default-sink)
    local default_source=$(pactl get-default-source)
    local sink_volume=$(pactl get-sink-volume "$default_sink" | grep -o '[0-9]\+%' | head -1)
    local source_volume=$(pactl get-source-volume "$default_source" | grep -o '[0-9]\+%' | head -1 2>/dev/null || echo "50%")
    local sink_mute=$(pactl get-sink-mute "$default_sink" | awk '{print $2}')
    local source_mute=$(pactl get-source-mute "$default_source" | awk '{print $2}' 2>/dev/null || echo "no")
    
    # Create profile configuration
    cat > "$profile_file" << EOF
# Audio Profile: $profile_name
# Created: $(date)

DEFAULT_SINK="$default_sink"
DEFAULT_SOURCE="$default_source"
SINK_VOLUME="$sink_volume"
SOURCE_VOLUME="$source_volume"
SINK_MUTE="$sink_mute"
SOURCE_MUTE="$source_mute"

# Additional settings
SAMPLE_RATE="48000"
SAMPLE_FORMAT="s16le"
CHANNELS="2"

# Effects settings (if using EasyEffects/PulseEffects)
EQUALIZER_ENABLED="true"
NOISE_SUPPRESSION="false"
ECHO_CANCELLATION="true"
COMPRESSOR_ENABLED="false"
EOF
    
    success "Audio profile '$profile_name' created: $profile_file"
}

# Load audio profile
load_audio_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        list_audio_profiles
        read -p "Enter profile name: " profile_name
    fi
    
    if [ -z "$profile_name" ]; then
        error "Profile name required"
        return 1
    fi
    
    local profile_file="$PROFILES_DIR/${profile_name}.conf"
    
    if [ ! -f "$profile_file" ]; then
        error "Audio profile '$profile_name' not found"
        return 1
    fi
    
    log "Loading audio profile: $profile_name"
    
    # Source the profile
    source "$profile_file"
    
    # Apply audio settings
    if [ -n "$DEFAULT_SINK" ]; then
        pactl set-default-sink "$DEFAULT_SINK"
        log "Set default sink: $DEFAULT_SINK"
    fi
    
    if [ -n "$DEFAULT_SOURCE" ]; then
        pactl set-default-source "$DEFAULT_SOURCE"
        log "Set default source: $DEFAULT_SOURCE"
    fi
    
    if [ -n "$SINK_VOLUME" ]; then
        pactl set-sink-volume "$DEFAULT_SINK" "$SINK_VOLUME"
        log "Set sink volume: $SINK_VOLUME"
    fi
    
    if [ -n "$SOURCE_VOLUME" ]; then
        pactl set-source-volume "$DEFAULT_SOURCE" "$SOURCE_VOLUME"
        log "Set source volume: $SOURCE_VOLUME"
    fi
    
    if [ -n "$SINK_MUTE" ]; then
        pactl set-sink-mute "$DEFAULT_SINK" "$SINK_MUTE"
        log "Set sink mute: $SINK_MUTE"
    fi
    
    if [ -n "$SOURCE_MUTE" ]; then
        pactl set-source-mute "$DEFAULT_SOURCE" "$SOURCE_MUTE"
        log "Set source mute: $SOURCE_MUTE"
    fi
    
    success "Audio profile '$profile_name' loaded successfully"
}

# List audio profiles
list_audio_profiles() {
    echo -e "${CYAN}=== Audio Profiles ===${NC}"
    
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR")" ]; then
        echo "No audio profiles found"
        return
    fi
    
    for profile in "$PROFILES_DIR"/*.conf; do
        if [ -f "$profile" ]; then
            local name=$(basename "$profile" .conf)
            local created=$(stat -c %y "$profile" | cut -d' ' -f1)
            echo -e "  ${GREEN}$name${NC} (created: $created)"
            
            # Show brief profile info
            local sink=$(grep "DEFAULT_SINK=" "$profile" | cut -d'"' -f2)
            local volume=$(grep "SINK_VOLUME=" "$profile" | cut -d'"' -f2)
            echo "    Sink: $(basename "$sink") | Volume: $volume"
        fi
    done
}

# Setup noise suppression
setup_noise_suppression() {
    log "Setting up noise suppression..."
    
    # Check if RNNoise is available
    if ! find /usr -name "*rnnoise*" 2>/dev/null | grep -q rnnoise; then
        log "Installing RNNoise..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm rnnoise
        elif command -v apt >/dev/null 2>&1; then
            sudo apt install -y librnnoise0
        fi
    fi
    
    # Create noise suppression module configuration
    local pulse_config="$HOME/.config/pulse/default.pa"
    mkdir -p "$(dirname "$pulse_config")"
    
    if ! grep -q "rnnoise" "$pulse_config" 2>/dev/null; then
        cat >> "$pulse_config" << 'EOF'

# Noise suppression using RNNoise
.include /etc/pulse/default.pa

load-module module-null-sink sink_name=mic_denoised_out rate=48000
load-module module-ladspa-sink sink_name=mic_raw_in sink_master=mic_denoised_out label=noise_suppressor_mono plugin=librnnoise_ladspa.so control=0.5
load-module module-loopback source=@DEFAULT_SOURCE@ sink=mic_raw_in channels=1 latency_msec=1
set-default-source mic_denoised_out.monitor
EOF
        
        # Restart PulseAudio
        pulseaudio -k
        sleep 2
        pulseaudio --start
        
        success "Noise suppression configured"
    else
        log "Noise suppression already configured"
    fi
}

# Setup echo cancellation
setup_echo_cancellation() {
    log "Setting up echo cancellation..."
    
    local pulse_config="$HOME/.config/pulse/default.pa"
    mkdir -p "$(dirname "$pulse_config")"
    
    if ! grep -q "echo-cancel" "$pulse_config" 2>/dev/null; then
        cat >> "$pulse_config" << 'EOF'

# Echo cancellation
load-module module-echo-cancel source_name=echocancel_source sink_name=echocancel_sink
set-default-source echocancel_source
set-default-sink echocancel_sink
EOF
        
        pulseaudio -k
        sleep 2
        pulseaudio --start
        
        success "Echo cancellation configured"
    else
        log "Echo cancellation already configured"
    fi
}

# Audio recording utility
record_audio() {
    local output_file="$1"
    local duration="$2"
    local quality="${3:-high}"
    
    if [ -z "$output_file" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="$RECORDINGS_DIR/recording_$timestamp.wav"
    fi
    
    # Create recordings directory
    mkdir -p "$(dirname "$output_file")"
    
    log "Recording audio to: $output_file"
    
    # Set recording parameters based on quality
    local sample_rate format channels
    case "$quality" in
        low)
            sample_rate="22050"
            format="s16le"
            channels="1"
            ;;
        medium)
            sample_rate="44100"
            format="s16le"
            channels="2"
            ;;
        high)
            sample_rate="48000"
            format="s24le"
            channels="2"
            ;;
    esac
    
    # Start recording
    if [ -n "$duration" ]; then
        timeout "${duration}s" parecord --format="$format" --rate="$sample_rate" --channels="$channels" "$output_file"
    else
        log "Press Ctrl+C to stop recording..."
        parecord --format="$format" --rate="$sample_rate" --channels="$channels" "$output_file"
    fi
    
    success "Recording saved: $output_file"
}

# Audio testing
test_audio() {
    local test_type="${1:-speakers}"
    
    case "$test_type" in
        speakers|output)
            log "Testing speakers/output..."
            if command -v speaker-test >/dev/null 2>&1; then
                speaker-test -t sine -f 1000 -l 1
            else
                paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null || \
                echo "Test sound not found. Install alsa-utils or check audio files."
            fi
            ;;
        microphone|input)
            log "Testing microphone/input (10 seconds)..."
            local test_file="/tmp/mic_test.wav"
            timeout 10s parecord --format=s16le --rate=44100 --channels=1 "$test_file"
            log "Playing back microphone test..."
            paplay "$test_file"
            rm -f "$test_file"
            ;;
        *)
            error "Unknown test type. Use 'speakers' or 'microphone'"
            ;;
    esac
}

# Audio format conversion
convert_audio() {
    local input_file="$1"
    local output_file="$2"
    local format="${3:-mp3}"
    
    if [ -z "$input_file" ] || [ ! -f "$input_file" ]; then
        error "Input file required and must exist"
        return 1
    fi
    
    if [ -z "$output_file" ]; then
        local basename=$(basename "$input_file" | sed 's/\.[^.]*$//')
        output_file="${basename}.${format}"
    fi
    
    log "Converting $input_file to $output_file..."
    
    if command -v ffmpeg >/dev/null 2>&1; then
        case "$format" in
            mp3)
                ffmpeg -i "$input_file" -codec:a libmp3lame -b:a 192k "$output_file"
                ;;
            flac)
                ffmpeg -i "$input_file" -codec:a flac "$output_file"
                ;;
            ogg)
                ffmpeg -i "$input_file" -codec:a libvorbis -q:a 5 "$output_file"
                ;;
            wav)
                ffmpeg -i "$input_file" -codec:a pcm_s16le "$output_file"
                ;;
            *)
                error "Unsupported format: $format"
                return 1
                ;;
        esac
        success "Conversion complete: $output_file"
    else
        error "ffmpeg not found. Install with: sudo pacman -S ffmpeg"
    fi
}

# Audio visualization
show_audio_levels() {
    local device="${1:-@DEFAULT_SOURCE@}"
    
    log "Showing audio levels for: $device"
    log "Press Ctrl+C to stop monitoring..."
    
    if command -v pactl >/dev/null 2>&1; then
        pactl subscribe | grep --line-buffered "Event 'change' on source" | \
        while read -r line; do
            local volume=$(pactl get-source-volume "$device" 2>/dev/null | grep -o '[0-9]\+%' | head -1)
            local muted=$(pactl get-source-mute "$device" 2>/dev/null | awk '{print $2}')
            
            if [ "$muted" = "yes" ]; then
                echo -e "${RED}[MUTED]${NC} $device"
            else
                echo -e "${GREEN}[$volume]${NC} $device"
            fi
        done
    else
        error "PulseAudio/PipeWire tools not available"
    fi
}

# Show help
show_help() {
    echo "Usage: audio-manager [command] [options]"
    echo
    echo "System Commands:"
    echo "  info                     Show audio system information"
    echo "  setup-equalizer          Setup audio equalizer (PulseEffects/EasyEffects)"
    echo "  setup-noise-suppression  Setup noise suppression (RNNoise)"
    echo "  setup-echo-cancel        Setup echo cancellation"
    echo
    echo "Profile Commands:"
    echo "  create-profile [name]    Create audio profile from current settings"
    echo "  load-profile [name]      Load audio profile"
    echo "  list-profiles            List audio profiles"
    echo
    echo "Recording Commands:"
    echo "  record [file] [duration] [quality]  Record audio (quality: low/medium/high)"
    echo "  convert [input] [output] [format]    Convert audio format"
    echo
    echo "Testing Commands:"
    echo "  test [speakers|microphone]  Test audio input/output"
    echo "  show-levels [device]        Show real-time audio levels"
    echo
    echo "Examples:"
    echo "  audio-manager info"
    echo "  audio-manager create-profile gaming"
    echo "  audio-manager record ~/recording.wav 60 high"
    echo "  audio-manager convert song.wav song.mp3 mp3"
    echo "  audio-manager test microphone"
    echo
    echo "Features:"
    echo "  • Audio profiles for different scenarios"
    echo "  • Equalizer setup (PulseEffects/EasyEffects)"
    echo "  • Noise suppression using RNNoise"
    echo "  • Echo cancellation configuration"
    echo "  • High-quality audio recording"
    echo "  • Audio format conversion"
    echo "  • Real-time audio monitoring"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    info) get_audio_info ;;
    setup-equalizer) setup_equalizer ;;
    setup-noise-suppression) setup_noise_suppression ;;
    setup-echo-cancel) setup_echo_cancellation ;;
    create-profile) create_audio_profile "$2" ;;
    load-profile) load_audio_profile "$2" ;;
    list-profiles) list_audio_profiles ;;
    record) record_audio "$2" "$3" "$4" ;;
    convert) convert_audio "$2" "$3" "$4" ;;
    test) test_audio "$2" ;;
    show-levels) show_audio_levels "$2" ;;
    help|*) show_help ;;
esac
