#!/bin/bash
# Workspace Overview Module for Waybar
# Smart workspace detection with visual indicators

# Check if Hyprland is running
if ! command -v hyprctl >/dev/null 2>&1; then
    echo '{"text": "🖥️", "class": "inactive", "tooltip": "Hyprland not available"}'
    exit 0
fi

# Get workspace data
CURRENT_WORKSPACE=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
WORKSPACE_DATA=$(hyprctl workspaces -j 2>/dev/null)
CLIENT_DATA=$(hyprctl clients -j 2>/dev/null)

if [ -z "$WORKSPACE_DATA" ]; then
    echo '{"text": "🖥️ ERR", "class": "error", "tooltip": "Failed to get workspace data"}'
    exit 0
fi

# Count active workspaces (with windows)
ACTIVE_WORKSPACES=$(echo "$WORKSPACE_DATA" | jq '[.[] | select(.windows > 0)] | length')
TOTAL_WINDOWS=$(echo "$WORKSPACE_DATA" | jq 'map(.windows) | add // 0')

# Workspace type detection based on apps
WORKSPACE_TYPES=(
    [1]="🏠 Main"
    [2]="💻 Code" 
    [3]="🌐 Web"
    [4]="🎬 Media"
    [5]="🎮 Game"
    [6]="💬 Chat"
    [7]="🔧 Tools"
    [8]="🎵 Music"
    [9]="📁 Files"
    [10]="📦 Misc"
)

# Determine current workspace type
CURRENT_WS_TYPE="${WORKSPACE_TYPES[$CURRENT_WORKSPACE]}"
if [ -z "$CURRENT_WS_TYPE" ]; then
    CURRENT_WS_TYPE="🖥️ WS$CURRENT_WORKSPACE"
fi

# Smart workspace detection
detect_workspace_activity() {
    local workspace_id=$1
    local clients=$(echo "$CLIENT_DATA" | jq --argjson ws "$workspace_id" '[.[] | select(.workspace.id == $ws)]')
    local client_count=$(echo "$clients" | jq 'length')
    
    if [ "$client_count" -eq 0 ]; then
        echo "idle"
        return
    fi
    
    # Check for specific app types
    local has_gaming=$(echo "$clients" | jq '[.[] | select(.class | test("steam|lutris|heroic|game"; "i"))] | length')
    local has_dev=$(echo "$clients" | jq '[.[] | select(.class | test("code|vim|emacs|terminal|jetbrains"; "i"))] | length')
    local has_media=$(echo "$clients" | jq '[.[] | select(.class | test("vlc|mpv|obs|gimp|blender"; "i"))] | length')
    local has_browser=$(echo "$clients" | jq '[.[] | select(.class | test("firefox|chrome|browser"; "i"))] | length')
    
    if [ "$has_gaming" -gt 0 ]; then
        echo "gaming"
    elif [ "$has_dev" -gt 0 ]; then
        echo "development"
    elif [ "$has_media" -gt 0 ]; then
        echo "media"
    elif [ "$has_browser" -gt 0 ]; then
        echo "productivity"
    else
        echo "active"
    fi
}

# Get activity type for current workspace
CURRENT_ACTIVITY=$(detect_workspace_activity "$CURRENT_WORKSPACE")

# Create workspace summary
WORKSPACE_SUMMARY=""
for ws in {1..10}; do
    WS_DATA=$(echo "$WORKSPACE_DATA" | jq --argjson ws "$ws" '.[] | select(.id == $ws)')
    if [ -n "$WS_DATA" ]; then
        WINDOW_COUNT=$(echo "$WS_DATA" | jq '.windows')
        if [ "$WINDOW_COUNT" -gt 0 ]; then
            if [ "$ws" -eq "$CURRENT_WORKSPACE" ]; then
                WORKSPACE_SUMMARY+="[$ws:$WINDOW_COUNT] "
            else
                WORKSPACE_SUMMARY+="$ws:$WINDOW_COUNT "
            fi
        fi
    fi
done

# Create tooltip
TOOLTIP="Workspace Overview\\n"
TOOLTIP+="Current: WS$CURRENT_WORKSPACE ($CURRENT_ACTIVITY)\\n"
TOOLTIP+="Active Workspaces: $ACTIVE_WORKSPACES\\n"
TOOLTIP+="Total Windows: $TOTAL_WINDOWS\\n"
if [ -n "$WORKSPACE_SUMMARY" ]; then
    TOOLTIP+="\\nWorkspace Windows:\\n$WORKSPACE_SUMMARY"
fi
TOOLTIP+="\\n\\nClick: Desktop Overview | Right-click: Next Empty"

# Determine display based on activity and workspace count
if [ "$ACTIVE_WORKSPACES" -eq 1 ] && [ "$CURRENT_WORKSPACE" -eq 1 ]; then
    # Single workspace mode
    echo "{\"text\": \"🖥️ SINGLE\", \"class\": \"single\", \"tooltip\": \"$TOOLTIP\"}"
elif [ "$ACTIVE_WORKSPACES" -le 3 ]; then
    # Few workspaces
    WS_ICON=$(echo "$CURRENT_WS_TYPE" | cut -d' ' -f1)
    echo "{\"text\": \"$WS_ICON WS$CURRENT_WORKSPACE\", \"class\": \"$CURRENT_ACTIVITY\", \"tooltip\": \"$TOOLTIP\"}"
elif [ "$ACTIVE_WORKSPACES" -le 6 ]; then
    # Medium number of workspaces
    echo "{\"text\": \"🖥️ $ACTIVE_WORKSPACES/$CURRENT_WORKSPACE\", \"class\": \"medium\", \"tooltip\": \"$TOOLTIP\"}"
else
    # Many workspaces
    echo "{\"text\": \"🖥️ $ACTIVE_WORKSPACES WS\", \"class\": \"busy\", \"tooltip\": \"$TOOLTIP\"}"
fi
