// WorkloadIndicator.qml - AI-Enhanced Workload Indicator Widget
// Displays current workload type with visual indicators and performance metrics

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell 1.0
import Quickshell.Io 1.0

ShellWindow {
    id: workloadIndicator
    
    property string currentWorkload: "idle"
    property real confidence: 0.0
    property var workloadMetrics: ({})
    property bool animationsEnabled: true
    property bool showDetails: false
    property color baseColor: "#1e1e2e"
    property color accentColor: "#cba6f7"
    
    // Workload-specific configurations
    property var workloadConfig: ({
        "gaming": {
            "color": "#f38ba8",
            "icon": "🎮",
            "name": "Gaming",
            "priority": "high"
        },
        "development": {
            "color": "#a6e3a1", 
            "icon": "💻",
            "name": "Development",
            "priority": "medium"
        },
        "media": {
            "color": "#fab387",
            "icon": "🎬",
            "name": "Media",
            "priority": "high"
        },
        "productivity": {
            "color": "#89b4fa",
            "icon": "📊",
            "name": "Productivity", 
            "priority": "medium"
        },
        "idle": {
            "color": "#6c7086",
            "icon": "💤",
            "name": "Idle",
            "priority": "low"
        }
    })
    
    // Window properties
    width: showDetails ? 280 : 120
    height: showDetails ? 140 : 40
    visible: true
    
    // Position (top-right corner)
    anchor {
        top: true
        right: true
        margins: {
            top: 60
            right: 20
        }
    }
    
    // Background with blur effect
    Rectangle {
        id: background
        anchors.fill: parent
        color: baseColor
        opacity: 0.95
        radius: 12
        
        // Subtle border based on workload
        border.color: getCurrentWorkloadColor()
        border.width: 2
        
        // Gradient overlay for depth
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
            }
        }
    }
    
    // Main content layout
    RowLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 8
        
        // Workload icon with pulse animation
        Rectangle {
            id: iconContainer
            width: 24
            height: 24
            color: "transparent"
            
            Text {
                id: workloadIcon
                anchors.centerIn: parent
                text: getCurrentWorkloadIcon()
                font.pixelSize: 16
                color: getCurrentWorkloadColor()
                
                // Pulse animation for high-priority workloads
                SequentialAnimation on scale {
                    running: workloadIndicator.animationsEnabled && 
                            (currentWorkload === "gaming" || currentWorkload === "media")
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                }
            }
            
            Layout.alignment: Qt.AlignVCenter
        }
        
        // Workload information
        ColumnLayout {
            id: infoLayout
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            
            // Workload name and confidence
            RowLayout {
                spacing: 4
                Layout.fillWidth: true
                
                Text {
                    id: workloadName
                    text: getCurrentWorkloadName()
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#cdd6f4"
                    Layout.fillWidth: true
                }
                
                // Confidence indicator
                Rectangle {
                    id: confidenceBar
                    width: 30
                    height: 3
                    color: "#313244"
                    radius: 1.5
                    visible: !showDetails
                    Layout.alignment: Qt.AlignVCenter
                    
                    Rectangle {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width * Math.max(0.1, confidence)
                        height: parent.height
                        color: getCurrentWorkloadColor()
                        radius: parent.radius
                        
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
            
            // Priority indicator
            Rectangle {
                id: priorityIndicator
                width: 4
                height: 12
                radius: 2
                color: getPriorityColor()
                visible: !showDetails
                Layout.alignment: Qt.AlignLeft
                
                // Breathing animation for high priority
                SequentialAnimation on opacity {
                    running: workloadIndicator.animationsEnabled && 
                            getCurrentWorkloadPriority() === "high"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }
        }
        
        // Toggle details button
        Rectangle {
            id: toggleButton
            width: 16
            height: 16
            color: "transparent"
            radius: 8
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                anchors.centerIn: parent
                text: showDetails ? "−" : "+"
                font.pixelSize: 12
                color: "#6c7086"
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    showDetails = !showDetails
                }
                
                onEntered: parent.color = Qt.rgba(1, 1, 1, 0.1)
                onExited: parent.color = "transparent"
            }
        }
    }
    
    // Detailed view (shown when expanded)
    Column {
        id: detailsView
        anchors {
            top: mainLayout.bottom
            left: parent.left
            right: parent.right
            margins: 8
        }
        spacing: 6
        visible: showDetails
        
        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: "#313244"
        }
        
        // Performance metrics
        Grid {
            id: metricsGrid
            width: parent.width
            columns: 2
            columnSpacing: 12
            rowSpacing: 4
            
            // CPU Usage
            Text {
                text: "CPU:"
                font.pixelSize: 9
                color: "#6c7086"
            }
            Text {
                text: (workloadMetrics.cpu || 0) + "%"
                font.pixelSize: 9
                color: "#cdd6f4"
            }
            
            // Memory Usage
            Text {
                text: "RAM:"
                font.pixelSize: 9
                color: "#6c7086"
            }
            Text {
                text: (workloadMetrics.memory || 0) + "%"
                font.pixelSize: 9
                color: "#cdd6f4"
            }
            
            // GPU Usage (if available)
            Text {
                text: "GPU:"
                font.pixelSize: 9
                color: "#6c7086"
                visible: (workloadMetrics.gpu || 0) > 0
            }
            Text {
                text: (workloadMetrics.gpu || 0) + "%"
                font.pixelSize: 9
                color: "#cdd6f4"
                visible: (workloadMetrics.gpu || 0) > 0
            }
            
            // Confidence
            Text {
                text: "Confidence:"
                font.pixelSize: 9
                color: "#6c7086"
            }
            Text {
                text: Math.round(confidence * 100) + "%"
                font.pixelSize: 9
                color: getCurrentWorkloadColor()
            }
        }
        
        // Quick actions
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Force workload button
            Rectangle {
                width: 60
                height: 20
                radius: 10
                color: "#313244"
                
                Text {
                    anchors.centerIn: parent
                    text: "Force"
                    font.pixelSize: 8
                    color: "#cdd6f4"
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: forceCurrentWorkload()
                    onEntered: parent.color = Qt.lighter(parent.color, 1.2)
                    onExited: parent.color = "#313244"
                }
            }
            
            // Reset button
            Rectangle {
                width: 60
                height: 20
                radius: 10
                color: "#313244"
                
                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    font.pixelSize: 8
                    color: "#cdd6f4"
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: resetToIdle()
                    onEntered: parent.color = Qt.lighter(parent.color, 1.2)
                    onExited: parent.color = "#313244"
                }
            }
        }
    }
    
    // Animation properties
    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    Behavior on height {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Workload update process
    Process {
        id: workloadProcess
        command: ["/bin/bash", "-c", `
            if [ -f "$HOME/.config/hypr/scripts/ai/workload-automation.sh" ]; then
                "$HOME/.config/hypr/scripts/ai/workload-automation.sh" detect
            else
                echo '{"workload": "idle", "confidence": 0, "metrics": {"cpu": 0, "memory": 0, "gpu": 0}}'
            fi
        `]
        
        onFinished: {
            if (exitCode === 0) {
                try {
                    var result = JSON.parse(stdout)
                    updateWorkloadData(result)
                } catch (e) {
                    console.log("Failed to parse workload data:", e)
                }
            }
        }
    }
    
    // Update timer
    Timer {
        id: updateTimer
        interval: 5000 // Update every 5 seconds
        running: true
        repeat: true
        
        onTriggered: {
            workloadProcess.start()
        }
    }
    
    // Notification process for workload changes
    Process {
        id: notificationProcess
        command: ["notify-send", "-t", "3000", "-i", "system-monitor"]
    }
    
    // Functions
    function getCurrentWorkloadColor() {
        return workloadConfig[currentWorkload]?.color || "#6c7086"
    }
    
    function getCurrentWorkloadIcon() {
        return workloadConfig[currentWorkload]?.icon || "💤"
    }
    
    function getCurrentWorkloadName() {
        return workloadConfig[currentWorkload]?.name || "Unknown"
    }
    
    function getCurrentWorkloadPriority() {
        return workloadConfig[currentWorkload]?.priority || "low"
    }
    
    function getPriorityColor() {
        var priority = getCurrentWorkloadPriority()
        switch(priority) {
            case "high": return "#f38ba8"
            case "medium": return "#fab387"
            default: return "#6c7086"
        }
    }
    
    function updateWorkloadData(data) {
        var oldWorkload = currentWorkload
        
        currentWorkload = data.workload || "idle"
        confidence = data.confidence || 0
        workloadMetrics = data.metrics || {}
        
        // Show notification on workload change
        if (oldWorkload !== currentWorkload && oldWorkload !== "") {
            showWorkloadChangeNotification(oldWorkload, currentWorkload)
        }
        
        // Emit signal for parent components
        workloadChanged(currentWorkload, confidence, workloadMetrics)
    }
    
    function showWorkloadChangeNotification(oldWorkload, newWorkload) {
        var oldName = workloadConfig[oldWorkload]?.name || oldWorkload
        var newName = workloadConfig[newWorkload]?.name || newWorkload
        var newIcon = workloadConfig[newWorkload]?.icon || "💤"
        
        notificationProcess.command = [
            "notify-send", 
            "-t", "3000", 
            "-i", "system-monitor",
            `${newIcon} Workload Changed`,
            `Switched from ${oldName} to ${newName}`
        ]
        notificationProcess.start()
    }
    
    function forceCurrentWorkload() {
        // Force apply current workload profile
        var forceProcess = Qt.createQmlObject(`
            import Quickshell.Io 1.0;
            Process {
                command: ["/bin/bash", "-c", 
                    "if [ -f '$HOME/.config/hypr/scripts/ai/workload-automation.sh' ]; then " +
                    "'$HOME/.config/hypr/scripts/ai/workload-automation.sh' apply '${currentWorkload}'; fi"]
            }
        `, workloadIndicator)
        
        forceProcess.finished.connect(function() {
            if (forceProcess.exitCode === 0) {
                showWorkloadChangeNotification(currentWorkload, currentWorkload)
            }
            forceProcess.destroy()
        })
        forceProcess.start()
    }
    
    function resetToIdle() {
        // Reset to idle workload
        var resetProcess = Qt.createQmlObject(`
            import Quickshell.Io 1.0;
            Process {
                command: ["/bin/bash", "-c", 
                    "if [ -f '$HOME/.config/hypr/scripts/ai/workload-automation.sh' ]; then " +
                    "'$HOME/.config/hypr/scripts/ai/workload-automation.sh' reset; fi"]
            }
        `, workloadIndicator)
        
        resetProcess.finished.connect(function() {
            if (resetProcess.exitCode === 0) {
                currentWorkload = "idle"
                confidence = 1.0
                workloadMetrics = {"cpu": 0, "memory": 0, "gpu": 0}
                showWorkloadChangeNotification("", "idle")
            }
            resetProcess.destroy()
        })
        resetProcess.start()
    }
    
    // Hover effects
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            background.border.width = 3
            if (animationsEnabled) {
                workloadIcon.scale = 1.1
            }
        }
        
        onExited: {
            background.border.width = 2
            if (animationsEnabled) {
                workloadIcon.scale = 1.0
            }
        }
        
        // Double click to toggle details
        onDoubleClicked: {
            showDetails = !showDetails
        }
    }
    
    // Signals
    signal workloadChanged(string workload, real confidence, var metrics)
    
    // Initialization
    Component.onCompleted: {
        console.log("WorkloadIndicator initialized")
        
        // Initial workload detection
        workloadProcess.start()
        
        // Start update timer with slight delay
        updateTimer.start()
    }
    
    // Cleanup
    Component.onDestruction: {
        updateTimer.stop()
        workloadProcess.kill()
    }
}
