#!/bin/bash
# AI Workload Status Module for Waybar
# Real-time workload detection with visual indicators

WORKLOAD_AUTOMATION="$HOME/hyprland-project/scripts/ai/workload-automation.sh"

# Check if workload automation script exists
if [ ! -f "$WORKLOAD_AUTOMATION" ]; then
    echo '{"text": "🤖", "class": "inactive", "tooltip": "AI workload detection not available"}'
    exit 0
fi

# Get current workload detection
WORKLOAD_DATA=$("$WORKLOAD_AUTOMATION" detect 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$WORKLOAD_DATA" ]; then
    echo '{"text": "🤖 ERR", "class": "error", "tooltip": "AI workload detection failed"}'
    exit 0
fi

# Parse JSON data
WORKLOAD=$(echo "$WORKLOAD_DATA" | jq -r '.workload // "idle"')
CONFIDENCE=$(echo "$WORKLOAD_DATA" | jq -r '.confidence // 0')
CPU_USAGE=$(echo "$WORKLOAD_DATA" | jq -r '.metrics.cpu // 0')
MEMORY_USAGE=$(echo "$WORKLOAD_DATA" | jq -r '.metrics.memory // 0')
GPU_USAGE=$(echo "$WORKLOAD_DATA" | jq -r '.metrics.gpu // 0')

# Convert confidence to percentage
CONFIDENCE_PERCENT=$(echo "$CONFIDENCE * 100" | bc -l | cut -d'.' -f1)

# Workload icons and display names
case "$WORKLOAD" in
    "gaming")
        ICON="🎮"
        DISPLAY_NAME="GAMING"
        CLASS="gaming"
        ;;
    "development")
        ICON="💻"
        DISPLAY_NAME="DEV"
        CLASS="development"
        ;;
    "media")
        ICON="🎬"
        DISPLAY_NAME="MEDIA"
        CLASS="media"
        ;;
    "productivity")
        ICON="📊"
        DISPLAY_NAME="WORK"
        CLASS="productivity"
        ;;
    "idle")
        ICON="💤"
        DISPLAY_NAME="IDLE"
        CLASS="idle"
        ;;
    *)
        ICON="🤖"
        DISPLAY_NAME="AUTO"
        CLASS="unknown"
        ;;
esac

# Create tooltip with detailed information
TOOLTIP="AI Workload Detection\\n"
TOOLTIP+="Current: $WORKLOAD ($CONFIDENCE_PERCENT% confidence)\\n"
TOOLTIP+="CPU: ${CPU_USAGE}% | Memory: ${MEMORY_USAGE}%"
if [ "$GPU_USAGE" -gt 0 ]; then
    TOOLTIP+=" | GPU: ${GPU_USAGE}%"
fi
TOOLTIP+="\\n\\nClick: Dashboard | Right-click: Apply"

# Output for Waybar
if [ "$CONFIDENCE_PERCENT" -ge 70 ]; then
    # High confidence - show full display
    echo "{\"text\": \"$ICON $DISPLAY_NAME\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
elif [ "$CONFIDENCE_PERCENT" -ge 40 ]; then
    # Medium confidence - show icon and abbreviated name
    echo "{\"text\": \"$ICON $(echo $DISPLAY_NAME | cut -c1-3)\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
else
    # Low confidence - show just icon
    echo "{\"text\": \"$ICON\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
fi
