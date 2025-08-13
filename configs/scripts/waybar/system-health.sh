#!/bin/bash
# System Health Module for Waybar
# Real-time system health monitoring with color-coded status

# Thresholds
CPU_WARN=70
CPU_CRITICAL=85
MEMORY_WARN=75
MEMORY_CRITICAL=90
DISK_WARN=80
DISK_CRITICAL=90
TEMP_WARN=65
TEMP_CRITICAL=75

# Get system metrics
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
DISK_USAGE=$(df / | awk 'NR==2{print int($5)}' | sed 's/%//')

# Get temperature (try multiple sources)
TEMP=0
if command -v sensors >/dev/null 2>&1; then
    TEMP=$(sensors 2>/dev/null | grep -o '+[0-9]\+\.[0-9]\+°C' | sed 's/+\|°C//g' | sort -n | tail -1 | cut -d'.' -f1)
fi
[ -z "$TEMP" ] && TEMP=0

# Determine overall health status
CRITICAL_ISSUES=0
WARNING_ISSUES=0

# Check CPU
if [ "$CPU_USAGE" -ge "$CPU_CRITICAL" ]; then
    ((CRITICAL_ISSUES++))
elif [ "$CPU_USAGE" -ge "$CPU_WARN" ]; then
    ((WARNING_ISSUES++))
fi

# Check Memory
if [ "$MEMORY_USAGE" -ge "$MEMORY_CRITICAL" ]; then
    ((CRITICAL_ISSUES++))
elif [ "$MEMORY_USAGE" -ge "$MEMORY_WARN" ]; then
    ((WARNING_ISSUES++))
fi

# Check Disk
if [ "$DISK_USAGE" -ge "$DISK_CRITICAL" ]; then
    ((CRITICAL_ISSUES++))
elif [ "$DISK_USAGE" -ge "$DISK_WARN" ]; then
    ((WARNING_ISSUES++))
fi

# Check Temperature
if [ "$TEMP" -ge "$TEMP_CRITICAL" ]; then
    ((CRITICAL_ISSUES++))
elif [ "$TEMP" -ge "$TEMP_WARN" ]; then
    ((WARNING_ISSUES++))
fi

# Generate output based on health status
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    ICON="🔴"
    STATUS="CRITICAL"
    CLASS="critical"
elif [ "$WARNING_ISSUES" -gt 0 ]; then
    ICON="🟡"
    STATUS="WARNING"
    CLASS="warning"
else
    ICON="🟢"
    STATUS="HEALTHY"
    CLASS="healthy"
fi

# Create tooltip with detailed info
TOOLTIP="System Health: $STATUS\\n"
TOOLTIP+="CPU: ${CPU_USAGE}%\\n"
TOOLTIP+="Memory: ${MEMORY_USAGE}%\\n"
TOOLTIP+="Disk: ${DISK_USAGE}%"
if [ "$TEMP" -gt 0 ]; then
    TOOLTIP+="\\nTemp: ${TEMP}°C"
fi

# Output JSON for Waybar
echo "{\"text\": \"$ICON $STATUS\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
