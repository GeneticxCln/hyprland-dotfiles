// SystemMonitor.qml - Real-time System Resource Monitoring
// Provides system metrics for AI workload detection and optimization

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell 1.0
import Quickshell.Io 1.0

ShellWindow {
    id: systemMonitor
    
    // Widget properties
    property bool aiEnabled: true
    property real cpuUsage: 0.0
    property real memoryUsage: 0.0
    property real gpuUsage: 0.0
    property real diskUsage: 0.0
    property real networkUpload: 0.0
    property real networkDownload: 0.0
    property real temperature: 0.0
    property int processCount: 0
    property bool showDetails: false
    
    // Historical data for trends
    property var cpuHistory: []
    property var memoryHistory: []
    property int maxHistoryLength: 60 // Keep 1 minute of data (1 update per second)
    
    // Thresholds for alerts
    property real cpuAlertThreshold: 80.0
    property real memoryAlertThreshold: 85.0
    property real tempAlertThreshold: 75.0
    
    // Window properties
    width: showDetails ? 320 : 180
    height: showDetails ? 200 : 80
    visible: true
    
    // Position (bottom-right corner)
    anchor {
        bottom: true
        right: true
        margins: {
            bottom: 20
            right: 20
        }
    }
    
    // Background
    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: 0.95
        radius: 12
        border.color: getAlertColor()
        border.width: 2
        
        // Gradient overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
            }
        }
    }
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "System Monitor"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#cdd6f4"
                Layout.fillWidth: true
            }
            
            // AI indicator
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: aiEnabled ? "#a6e3a1" : "#6c7086"
                visible: aiEnabled
                
                SequentialAnimation on opacity {
                    running: aiEnabled
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }
            
            // Toggle button
            Text {
                text: showDetails ? "−" : "+"
                font.pixelSize: 14
                color: "#6c7086"
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showDetails = !showDetails
                    onEntered: parent.color = "#cdd6f4"
                    onExited: parent.color = "#6c7086"
                }
            }
        }
        
        // Quick stats (always visible)
        Grid {
            id: quickStats
            columns: 2
            columnSpacing: 16
            rowSpacing: 4
            Layout.fillWidth: true
            
            // CPU
            Row {
                spacing: 4
                Text {
                    text: "CPU:"
                    font.pixelSize: 9
                    color: "#a6adc8"
                }
                Text {
                    text: Math.round(cpuUsage) + "%"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: getUsageColor(cpuUsage, cpuAlertThreshold)
                }
            }
            
            // Memory
            Row {
                spacing: 4
                Text {
                    text: "RAM:"
                    font.pixelSize: 9
                    color: "#a6adc8"
                }
                Text {
                    text: Math.round(memoryUsage) + "%"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: getUsageColor(memoryUsage, memoryAlertThreshold)
                }
            }
            
            // GPU (if available)
            Row {
                spacing: 4
                visible: gpuUsage > 0
                Text {
                    text: "GPU:"
                    font.pixelSize: 9
                    color: "#a6adc8"
                }
                Text {
                    text: Math.round(gpuUsage) + "%"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: getUsageColor(gpuUsage, 80)
                }
            }
            
            // Temperature
            Row {
                spacing: 4
                visible: temperature > 0
                Text {
                    text: "Temp:"
                    font.pixelSize: 9
                    color: "#a6adc8"
                }
                Text {
                    text: Math.round(temperature) + "°C"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: getUsageColor(temperature, tempAlertThreshold)
                }
            }
        }
        
        // Detailed view (expanded)
        Column {
            id: detailsView
            Layout.fillWidth: true
            spacing: 8
            visible: showDetails
            
            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: "#313244"
            }
            
            // Resource bars
            Column {
                width: parent.width
                spacing: 6
                
                // CPU bar
                Column {
                    width: parent.width
                    spacing: 2
                    
                    Row {
                        width: parent.width
                        Text {
                            text: "CPU Usage"
                            font.pixelSize: 9
                            color: "#a6adc8"
                            width: parent.width * 0.6
                        }
                        Text {
                            text: Math.round(cpuUsage) + "%"
                            font.pixelSize: 9
                            color: getUsageColor(cpuUsage, cpuAlertThreshold)
                            horizontalAlignment: Text.AlignRight
                            width: parent.width * 0.4
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 3
                        color: "#313244"
                        radius: 1.5
                        
                        Rectangle {
                            width: parent.width * (cpuUsage / 100)
                            height: parent.height
                            color: getUsageColor(cpuUsage, cpuAlertThreshold)
                            radius: parent.radius
                            
                            Behavior on width {
                                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
                
                // Memory bar
                Column {
                    width: parent.width
                    spacing: 2
                    
                    Row {
                        width: parent.width
                        Text {
                            text: "Memory Usage"
                            font.pixelSize: 9
                            color: "#a6adc8"
                            width: parent.width * 0.6
                        }
                        Text {
                            text: Math.round(memoryUsage) + "%"
                            font.pixelSize: 9
                            color: getUsageColor(memoryUsage, memoryAlertThreshold)
                            horizontalAlignment: Text.AlignRight
                            width: parent.width * 0.4
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 3
                        color: "#313244"
                        radius: 1.5
                        
                        Rectangle {
                            width: parent.width * (memoryUsage / 100)
                            height: parent.height
                            color: getUsageColor(memoryUsage, memoryAlertThreshold)
                            radius: parent.radius
                            
                            Behavior on width {
                                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
                
                // GPU bar (if available)
                Column {
                    width: parent.width
                    spacing: 2
                    visible: gpuUsage > 0
                    
                    Row {
                        width: parent.width
                        Text {
                            text: "GPU Usage"
                            font.pixelSize: 9
                            color: "#a6adc8"
                            width: parent.width * 0.6
                        }
                        Text {
                            text: Math.round(gpuUsage) + "%"
                            font.pixelSize: 9
                            color: getUsageColor(gpuUsage, 80)
                            horizontalAlignment: Text.AlignRight
                            width: parent.width * 0.4
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: 3
                        color: "#313244"
                        radius: 1.5
                        
                        Rectangle {
                            width: parent.width * (gpuUsage / 100)
                            height: parent.height
                            color: getUsageColor(gpuUsage, 80)
                            radius: parent.radius
                            
                            Behavior on width {
                                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }
            
            // Additional metrics
            Grid {
                columns: 2
                columnSpacing: 16
                rowSpacing: 4
                width: parent.width
                
                Text {
                    text: "Processes:"
                    font.pixelSize: 9
                    color: "#6c7086"
                }
                Text {
                    text: processCount.toString()
                    font.pixelSize: 9
                    color: "#cdd6f4"
                }
                
                Text {
                    text: "Disk:"
                    font.pixelSize: 9
                    color: "#6c7086"
                    visible: diskUsage > 0
                }
                Text {
                    text: Math.round(diskUsage) + "%"
                    font.pixelSize: 9
                    color: "#cdd6f4"
                    visible: diskUsage > 0
                }
                
                Text {
                    text: "Net ↑:"
                    font.pixelSize: 9
                    color: "#6c7086"
                    visible: networkUpload > 0
                }
                Text {
                    text: formatBytes(networkUpload) + "/s"
                    font.pixelSize: 9
                    color: "#cdd6f4"
                    visible: networkUpload > 0
                }
                
                Text {
                    text: "Net ↓:"
                    font.pixelSize: 9
                    color: "#6c7086"
                    visible: networkDownload > 0
                }
                Text {
                    text: formatBytes(networkDownload) + "/s"
                    font.pixelSize: 9
                    color: "#cdd6f4"
                    visible: networkDownload > 0
                }
            }
        }
    }
    
    // System metrics update process
    Process {
        id: metricsProcess
        command: ["/bin/bash", "-c", `
            # Get CPU usage
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print int($1)}')
            
            # Get memory usage  
            memory_info=$(free)
            memory_usage=$(echo "$memory_info" | awk '/Mem:/ {printf "%.1f", $3/$2 * 100.0}')
            
            # Get GPU usage (NVIDIA)
            gpu_usage=0
            if command -v nvidia-smi >/dev/null 2>&1; then
                gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
            elif command -v radeontop >/dev/null 2>&1; then
                gpu_usage=$(timeout 1s radeontop -d - -l 1 2>/dev/null | grep -o "gpu [0-9]*" | awk '{print $2}' | head -1)
            fi
            
            # Get temperature
            temp=0
            if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
                temp=$(cat /sys/class/thermal/thermal_zone0/temp)
                temp=$((temp / 1000))
            fi
            
            # Get process count
            proc_count=$(ps aux | wc -l)
            
            # Get disk usage for root partition
            disk_usage=$(df / | awk 'NR==2 {print int($5)}' | sed 's/%//')
            
            # Format as JSON
            echo "{\\"cpu\\":$cpu_usage,\\"memory\\":$memory_usage,\\"gpu\\":${gpu_usage:-0},\\"temperature\\":$temp,\\"processes\\":$proc_count,\\"disk\\":$disk_usage}"
        `]
        
        onFinished: {
            if (exitCode === 0) {
                try {
                    var data = JSON.parse(stdout)
                    updateMetrics(data)
                } catch (e) {
                    console.warn("Failed to parse system metrics:", e)
                }
            }
        }
    }
    
    // Update timer
    Timer {
        id: updateTimer
        interval: 2000 // Update every 2 seconds
        running: true
        repeat: true
        
        onTriggered: {
            metricsProcess.start()
        }
    }
    
    // Animations
    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    Behavior on height {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Functions
    function updateMetrics(data) {
        cpuUsage = data.cpu || 0
        memoryUsage = data.memory || 0
        gpuUsage = data.gpu || 0
        temperature = data.temperature || 0
        processCount = data.processes || 0
        diskUsage = data.disk || 0
        
        // Update history
        cpuHistory.push(cpuUsage)
        memoryHistory.push(memoryUsage)
        
        // Limit history length
        if (cpuHistory.length > maxHistoryLength) {
            cpuHistory = cpuHistory.slice(-maxHistoryLength)
        }
        if (memoryHistory.length > maxHistoryLength) {
            memoryHistory = memoryHistory.slice(-maxHistoryLength)
        }
        
        // Emit signal for AI system if enabled
        if (aiEnabled) {
            metricsUpdated({\n                "cpu": cpuUsage,\n                "memory": memoryUsage,\n                "gpu": gpuUsage,\n                "temperature": temperature,\n                "processes": processCount,\n                "disk": diskUsage\n            })
        }
    }
    
    function getUsageColor(usage, threshold) {
        if (usage >= threshold) return "#f38ba8"
        else if (usage >= threshold * 0.7) return "#fab387"
        else return "#a6e3a1"
    }
    
    function getAlertColor() {
        if (cpuUsage >= cpuAlertThreshold || memoryUsage >= memoryAlertThreshold || temperature >= tempAlertThreshold) {
            return "#f38ba8"
        } else if (cpuUsage >= cpuAlertThreshold * 0.7 || memoryUsage >= memoryAlertThreshold * 0.7) {
            return "#fab387"
        } else {
            return "#6c7086"
        }
    }
    
    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        var k = 1024
        var sizes = ["B", "KB", "MB", "GB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }
    
    function update() {
        // Called by parent to trigger manual update
        metricsProcess.start()
    }
    
    // Signals
    signal metricsUpdated(var metrics)
    signal alertTriggered(string type, real value)
    
    // Alert checking
    onCpuUsageChanged: {
        if (cpuUsage >= cpuAlertThreshold) {
            alertTriggered("cpu", cpuUsage)
        }
    }
    
    onMemoryUsageChanged: {
        if (memoryUsage >= memoryAlertThreshold) {
            alertTriggered("memory", memoryUsage)
        }
    }
    
    onTemperatureChanged: {
        if (temperature >= tempAlertThreshold) {
            alertTriggered("temperature", temperature)
        }
    }
    
    // Hover effects
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            background.border.width = 3
        }
        
        onExited: {
            background.border.width = 2
        }
        
        onDoubleClicked: {
            showDetails = !showDetails
        }
    }
    
    // Component initialization
    Component.onCompleted: {
        console.log("SystemMonitor initialized")
        metricsProcess.start()
    }
    
    Component.onDestruction: {
        updateTimer.stop()
        metricsProcess.kill()
    }
}
