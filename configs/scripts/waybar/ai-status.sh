#!/bin/bash
# AI Status Module for Waybar
# Real-time AI system status with health monitoring

AI_MANAGER="$HOME/hyprland-project/scripts/ai/ai-manager.sh"

# Check if AI manager exists
if [ ! -f "$AI_MANAGER" ]; then
    echo '{"text": "🤖", "class": "inactive", "tooltip": "AI system not available"}'
    exit 0
fi

# Get AI system status
AI_STATUS=$("$AI_MANAGER" status 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$AI_STATUS" ]; then
    echo '{"text": "🤖 OFF", "class": "error", "tooltip": "AI system error or offline"}'
    exit 0
fi

# Parse AI status
OVERALL_HEALTH=$(echo "$AI_STATUS" | jq -r '.global_settings.overall_health // "unknown"')
COORDINATION_ENABLED=$(echo "$AI_STATUS" | jq -r '.global_settings.coordination_enabled // false')

# Count active systems
SMART_OPTIMIZER_ENABLED=$(echo "$AI_STATUS" | jq -r '.ai_systems.smart_optimizer.enabled // false')
MAINTENANCE_ENABLED=$(echo "$AI_STATUS" | jq -r '.ai_systems.predictive_maintenance.enabled // false') 
WORKLOAD_ENABLED=$(echo "$AI_STATUS" | jq -r '.ai_systems.workload_automation.enabled // false')

ACTIVE_SYSTEMS=0
[ "$SMART_OPTIMIZER_ENABLED" = "true" ] && ((ACTIVE_SYSTEMS++))
[ "$MAINTENANCE_ENABLED" = "true" ] && ((ACTIVE_SYSTEMS++))
[ "$WORKLOAD_ENABLED" = "true" ] && ((ACTIVE_SYSTEMS++))

# Determine icon and class based on health
case "$OVERALL_HEALTH" in
    "healthy")
        if [ "$COORDINATION_ENABLED" = "true" ]; then
            ICON="🧠"
            STATUS_TEXT="AI"
            CLASS="active"
        else
            ICON="🤖"
            STATUS_TEXT="AI"
            CLASS="active"
        fi
        ;;
    "degraded")
        ICON="⚠️"
        STATUS_TEXT="WARN"
        CLASS="warning"
        ;;
    "critical")
        ICON="🔴"
        STATUS_TEXT="CRIT"
        CLASS="error"
        ;;
    *)
        ICON="❓"
        STATUS_TEXT="UNK"
        CLASS="unknown"
        ;;
esac

# Create detailed tooltip
TOOLTIP="AI System Status\\n"
TOOLTIP+="Health: $OVERALL_HEALTH\\n"
TOOLTIP+="Active Systems: $ACTIVE_SYSTEMS/3\\n"
TOOLTIP+="Coordination: $([ "$COORDINATION_ENABLED" = "true" ] && echo "Enabled" || echo "Disabled")\\n"
TOOLTIP+="\\nComponents:\\n"
TOOLTIP+="• Smart Optimizer: $([ "$SMART_OPTIMIZER_ENABLED" = "true" ] && echo "✓" || echo "✗")\\n"
TOOLTIP+="• Maintenance: $([ "$MAINTENANCE_ENABLED" = "true" ] && echo "✓" || echo "✗")\\n"  
TOOLTIP+="• Workload Auto: $([ "$WORKLOAD_ENABLED" = "true" ] && echo "✓" || echo "✗")\\n"
TOOLTIP+="\\nClick: Dashboard | Right-click: Optimize"

# Show different displays based on status
if [ "$OVERALL_HEALTH" = "healthy" ] && [ "$ACTIVE_SYSTEMS" -eq 3 ]; then
    # All systems healthy and active
    if [ "$COORDINATION_ENABLED" = "true" ]; then
        echo "{\"text\": \"$ICON COORD\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
    else
        echo "{\"text\": \"$ICON ACTIVE\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
    fi
elif [ "$ACTIVE_SYSTEMS" -gt 0 ]; then
    # Some systems active
    echo "{\"text\": \"$ICON $ACTIVE_SYSTEMS/3\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
else
    # No systems active
    echo "{\"text\": \"$ICON OFF\", \"class\": \"inactive\", \"tooltip\": \"$TOOLTIP\"}"
fi
