#!/bin/bash
# Simple Workload Detection Test

echo "🎯 Simple Workload Detection Test"
echo "=================================="

# Get system metrics
echo "Getting system metrics..."
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}' || echo "0")
memory_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}' || echo "0")
gpu_usage=0

echo "CPU Usage: ${cpu_usage}%"
echo "Memory Usage: ${memory_usage}%"
echo "GPU Usage: ${gpu_usage}%"

# Get process info
echo ""
echo "Active processes (top 10 by CPU):"
ps aux --sort=-%cpu | head -10 | awk '{print $11}' | sed 's|.*/||' | tail -9

# Simple workload detection
if [ "$cpu_usage" -lt 15 ] && [ "$memory_usage" -lt 30 ]; then
    workload="idle"
    confidence=0.8
elif ps aux | grep -q -E "(code|vim|docker|python|node)"; then
    workload="development" 
    confidence=0.7
elif ps aux | grep -q -E "(steam|lutris|wine|heroic)"; then
    workload="gaming"
    confidence=0.9
elif ps aux | grep -q -E "(firefox|chrome|thunderbird|zoom)"; then
    workload="productivity"
    confidence=0.6
else
    workload="idle"
    confidence=0.5
fi

echo ""
echo "🎯 Detection Results:"
echo "===================="
echo "Detected Workload: $workload"
echo "Confidence: $(echo "scale=0; $confidence * 100" | bc -l)%"
echo ""

# Create JSON output for testing
cat << EOF
{
    "workload": "$workload",
    "confidence": $confidence,
    "metrics": {
        "cpu": $cpu_usage,
        "memory": $memory_usage,
        "gpu": $gpu_usage
    }
}
EOF
