#!/bin/bash
# Gaming Status Module for Waybar
# Real-time gaming mode status with visual indicators

GAMING_STATE_FILE="$HOME/.config/hypr/gaming/gaming_state"

# Check if gaming mode is active
if [ -f "$GAMING_STATE_FILE" ] && grep -q "ACTIVE=true" "$GAMING_STATE_FILE"; then
    # Gaming mode is active
    if grep -q "GAME_PID=" "$GAMING_STATE_FILE"; then
        # Game is running
        GAME_PID=$(grep "GAME_PID=" "$GAMING_STATE_FILE" | cut -d'=' -f2)
        if kill -0 "$GAME_PID" 2>/dev/null; then
            echo '{"text": "🎮 GAMING", "class": "active gaming", "tooltip": "Gaming mode active with running game"}'
        else
            echo '{"text": "🎮 READY", "class": "active", "tooltip": "Gaming mode active, ready to launch games"}'
        fi
    else
        echo '{"text": "🎮 READY", "class": "active", "tooltip": "Gaming mode active, ready to launch games"}'
    fi
else
    # Gaming mode is inactive
    echo '{"text": "🎮", "class": "inactive", "tooltip": "Gaming mode inactive - Click to enable"}'
fi
