#!/bin/bash
# Advanced Screenshot and Screen Recording
# Comprehensive screen capture for Hyprland

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
RECORDINGS_DIR="$HOME/Videos/Recordings"
TEMP_DIR="/tmp/hyprland-capture"

# Logging
log() { echo -e "${BLUE}[SCREENSHOT]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Setup directories
setup_dirs() {
    mkdir -p "$SCREENSHOT_DIR" "$RECORDINGS_DIR" "$TEMP_DIR"
}

# Generate filename
generate_filename() {
    local prefix="$1"
    local extension="$2"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    echo "${prefix}_${timestamp}.${extension}"
}

# Show notification with image preview
show_notification() {
    local file="$1"
    local message="$2"
    local icon="$3"
    
    if [ -f "$file" ]; then
        notify-send "$icon $message" "Saved to: $(basename "$file")" \
            -i "$file" \
            -t 5000 \
            -a "Screenshot Tool" 2>/dev/null || true
    else
        notify-send "$icon $message" "File: $(basename "$file")" \
            -t 3000 \
            -a "Screenshot Tool" 2>/dev/null || true
    fi
}

# Copy to clipboard
copy_to_clipboard() {
    local file="$1"
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$file"
        log "Copied to clipboard"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -t image/png < "$file"
        log "Copied to clipboard"
    else
        warning "No clipboard tool found (wl-copy/xclip)"
    fi
}

# Screenshot full screen
screenshot_full() {
    local filename=$(generate_filename "fullscreen" "png")
    local filepath="$SCREENSHOT_DIR/$filename"
    
    if command -v grim >/dev/null 2>&1; then
        grim "$filepath"
    elif command -v scrot >/dev/null 2>&1; then
        scrot "$filepath"
    else
        error "No screenshot tool found (grim/scrot)"
    fi
    
    copy_to_clipboard "$filepath"
    show_notification "$filepath" "Full screen captured" "📸"
    success "Screenshot saved: $filepath"
}

# Screenshot selection
screenshot_selection() {
    local filename=$(generate_filename "selection" "png")
    local filepath="$SCREENSHOT_DIR/$filename"
    
    if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
        local geometry=$(slurp)
        if [ $? -eq 0 ] && [ -n "$geometry" ]; then
            grim -g "$geometry" "$filepath"
        else
            warning "Selection cancelled"
            return 0
        fi
    elif command -v scrot >/dev/null 2>&1; then
        scrot -s "$filepath"
    else
        error "No screenshot selection tools found (grim+slurp/scrot)"
    fi
    
    copy_to_clipboard "$filepath"
    show_notification "$filepath" "Selection captured" "✂️"
    success "Screenshot saved: $filepath"
}

# Screenshot active window
screenshot_window() {
    local filename=$(generate_filename "window" "png")
    local filepath="$SCREENSHOT_DIR/$filename"
    
    if command -v grim >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
        local active_window=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        if [ -n "$active_window" ] && [ "$active_window" != "null" ]; then
            grim -g "$active_window" "$filepath"
        else
            warning "No active window found"
            return 1
        fi
    elif command -v scrot >/dev/null 2>&1; then
        scrot -u "$filepath"
    else
        error "No window screenshot tools found"
    fi
    
    copy_to_clipboard "$filepath"
    show_notification "$filepath" "Window captured" "🖼️"
    success "Screenshot saved: $filepath"
}

# Screenshot with delay
screenshot_delayed() {
    local delay="${1:-5}"
    local type="${2:-full}"
    
    notify-send "📸 Screenshot" "Taking screenshot in ${delay} seconds..." -t $((delay * 1000)) 2>/dev/null || true
    
    for ((i=delay; i>0; i--)); do
        log "Screenshot in $i seconds..."
        sleep 1
    done
    
    case "$type" in
        full) screenshot_full ;;
        selection) screenshot_selection ;;
        window) screenshot_window ;;
        *) screenshot_full ;;
    esac
}

# Start screen recording
start_recording() {
    local output_type="${1:-full}"
    local filename=$(generate_filename "recording" "mp4")
    local filepath="$RECORDINGS_DIR/$filename"
    local pidfile="$TEMP_DIR/recording.pid"
    
    if [ -f "$pidfile" ]; then
        warning "Recording already in progress"
        return 1
    fi
    
    log "Starting screen recording..."
    
    if command -v wf-recorder >/dev/null 2>&1; then
        case "$output_type" in
            selection)
                local geometry=$(slurp)
                if [ $? -eq 0 ] && [ -n "$geometry" ]; then
                    wf-recorder -g "$geometry" -f "$filepath" &
                else
                    warning "Selection cancelled"
                    return 0
                fi
                ;;
            *)
                wf-recorder -f "$filepath" &
                ;;
        esac
        echo $! > "$pidfile"
    elif command -v ffmpeg >/dev/null 2>&1; then
        # Fallback to ffmpeg for X11
        ffmpeg -f x11grab -s 1920x1080 -i :0.0 "$filepath" &
        echo $! > "$pidfile"
    else
        error "No recording tool found (wf-recorder/ffmpeg)"
    fi
    
    notify-send "🎬 Recording Started" "Recording to: $(basename "$filepath")" -t 3000 2>/dev/null || true
    success "Recording started: $filepath"
}

# Stop screen recording
stop_recording() {
    local pidfile="$TEMP_DIR/recording.pid"
    
    if [ ! -f "$pidfile" ]; then
        warning "No recording in progress"
        return 1
    fi
    
    local pid=$(cat "$pidfile")
    
    if kill -TERM "$pid" 2>/dev/null; then
        rm -f "$pidfile"
        notify-send "🎬 Recording Stopped" "Recording saved successfully" -t 3000 2>/dev/null || true
        success "Recording stopped"
    else
        warning "Failed to stop recording (PID: $pid)"
        rm -f "$pidfile"
    fi
}

# Record GIF
record_gif() {
    local duration="${1:-10}"
    local filename=$(generate_filename "recording" "gif")
    local filepath="$RECORDINGS_DIR/$filename"
    local temp_mp4="$TEMP_DIR/temp_recording.mp4"
    
    log "Recording GIF for $duration seconds..."
    
    if command -v wf-recorder >/dev/null 2>&1; then
        local geometry=$(slurp)
        if [ $? -eq 0 ] && [ -n "$geometry" ]; then
            timeout "${duration}s" wf-recorder -g "$geometry" -f "$temp_mp4"
        else
            warning "Selection cancelled"
            return 0
        fi
    else
        error "wf-recorder not found"
    fi
    
    # Convert to GIF
    if command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -i "$temp_mp4" -vf "fps=15,scale=720:-1:flags=lanczos" "$filepath" -y
        rm -f "$temp_mp4"
        
        show_notification "$filepath" "GIF created" "🎞️"
        success "GIF saved: $filepath"
    else
        error "ffmpeg not found for GIF conversion"
    fi
}

# Screenshot OCR (text extraction)
screenshot_ocr() {
    local temp_file="$TEMP_DIR/ocr_temp.png"
    
    if ! command -v tesseract >/dev/null 2>&1; then
        error "tesseract not found. Install with: sudo pacman -S tesseract"
    fi
    
    log "Select area for text extraction..."
    
    if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
        local geometry=$(slurp)
        if [ $? -eq 0 ] && [ -n "$geometry" ]; then
            grim -g "$geometry" "$temp_file"
        else
            warning "Selection cancelled"
            return 0
        fi
    else
        error "grim and slurp not found"
    fi
    
    # Extract text
    local extracted_text=$(tesseract "$temp_file" stdout 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')
    
    if [ -n "$extracted_text" ]; then
        # Copy to clipboard
        if command -v wl-copy >/dev/null 2>&1; then
            echo "$extracted_text" | wl-copy
        elif command -v xclip >/dev/null 2>&1; then
            echo "$extracted_text" | xclip -selection clipboard
        fi
        
        notify-send "🔍 Text Extracted" "$extracted_text" -t 10000 2>/dev/null || true
        success "Text copied to clipboard: $extracted_text"
    else
        warning "No text found in selection"
    fi
    
    rm -f "$temp_file"
}

# Edit screenshot
edit_screenshot() {
    local latest_screenshot=$(ls -t "$SCREENSHOT_DIR"/*.png 2>/dev/null | head -1)
    
    if [ -z "$latest_screenshot" ]; then
        warning "No screenshots found"
        return 1
    fi
    
    if command -v gimp >/dev/null 2>&1; then
        gimp "$latest_screenshot" &
        log "Opening in GIMP: $(basename "$latest_screenshot")"
    elif command -v krita >/dev/null 2>&1; then
        krita "$latest_screenshot" &
        log "Opening in Krita: $(basename "$latest_screenshot")"
    else
        warning "No image editor found (gimp/krita)"
    fi
}

# Show help
show_help() {
    echo "Usage: screenshot [command] [options]"
    echo
    echo "Screenshot Commands:"
    echo "  full               Take full screen screenshot"
    echo "  selection          Take selection screenshot"
    echo "  window             Take active window screenshot"
    echo "  delay [seconds] [type]  Take screenshot with delay (default: 5s, full)"
    echo
    echo "Recording Commands:"
    echo "  record [type]      Start recording (full/selection)"
    echo "  stop               Stop current recording"
    echo "  gif [duration]     Record selection as GIF (default: 10s)"
    echo
    echo "Utility Commands:"
    echo "  ocr                Extract text from selection"
    echo "  edit               Edit latest screenshot"
    echo "  help               Show this help message"
    echo
    echo "Files are saved to:"
    echo "  Screenshots: $SCREENSHOT_DIR"
    echo "  Recordings:  $RECORDINGS_DIR"
    echo
}

# Main execution
setup_dirs

case "${1:-help}" in
    full) screenshot_full ;;
    selection|select) screenshot_selection ;;
    window|win) screenshot_window ;;
    delay) screenshot_delayed "$2" "$3" ;;
    record|rec) start_recording "$2" ;;
    stop) stop_recording ;;
    gif) record_gif "$2" ;;
    ocr) screenshot_ocr ;;
    edit) edit_screenshot ;;
    help|*) show_help ;;
esac
