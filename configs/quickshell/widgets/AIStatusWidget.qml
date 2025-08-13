// AIStatusWidget.qml - Advanced AI System Status and Control Panel
// Comprehensive AI system monitoring, recommendations, and quick actions

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell 1.0
import Quickshell.Io 1.0

ShellWindow {
    id: aiStatusWidget
    
    // Widget properties
    property real confidence: 0.0
    property string currentWorkload: "idle"
    property bool aiActive: true
    property var lastRecommendation: null
    property string status: "initializing"
    property int learningDataPoints: 0
    property real systemHealth: 1.0
    property bool expandedView: false
    
    // Window properties
    width: 280
    height: 120
    visible: true
    
    // Position on screen (top-right corner)
    anchor {
        right: true
        top: true
        margins: {
            right: 20
            top: 60
        }
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        color: parent.color.alpha(0.9)
        radius: 12
        border.color: Qt.rgba(0.8, 0.8, 0.8, 0.3)
        border.width: 1
        
        // Background blur effect (simulated)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.1, 0.1, 0.1, 0.3)
            radius: parent.radius
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: aiActive ? "#a6e3a1" : "#f38ba8"
                    
                    // Pulsing animation when active
                    SequentialAnimation on opacity {
                        running: aiActive
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }
                }
                
                Text {
                    text: "AI System"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#cdd6f4"
                    Layout.fillWidth: true
                }
                
                Text {
                    text: status
                    font.pixelSize: 12
                    color: "#a6adc8"
                }
            }
            
            // Workload and confidence
            RowLayout {
                Layout.fillWidth: true
                
                // Workload indicator
                Rectangle {
                    width: 60
                    height: 24
                    radius: 12
                    color: getWorkloadColor(currentWorkload)
                    
                    Text {
                        anchors.centerIn: parent
                        text: getWorkloadIcon(currentWorkload)
                        font.pixelSize: 12
                        color: "#1e1e2e"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        ToolTip {
                            visible: parent.containsMouse
                            text: `Current workload: ${currentWorkload}`
                            delay: 500
                        }
                    }
                }
                
                // Spacer
                Item { Layout.fillWidth: true }
                
                // Confidence indicator
                Column {
                    Text {
                        text: "Confidence"
                        font.pixelSize: 10
                        color: "#a6adc8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: Math.round(confidence * 100) + "%"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: getConfidenceColor(confidence)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            // Progress bar for confidence
            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Qt.rgba(0.5, 0.5, 0.5, 0.3)
                
                Rectangle {
                    width: parent.width * confidence
                    height: parent.height
                    radius: parent.radius
                    color: getConfidenceColor(confidence)
                    
                    Behavior on width {
                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            // Quick actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Button {
                    text: "🎨"
                    font.pixelSize: 14
                    width: 30
                    height: 24
                    
                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#313244" : "transparent"
                        border.color: "#585b70"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#cdd6f4"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: requestThemeChange()
                    
                    ToolTip {
                        visible: parent.hovered
                        text: "Apply AI theme recommendation"
                    }
                }
                
                Button {
                    text: "⚡"
                    font.pixelSize: 14
                    width: 30
                    height: 24
                    
                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#313244" : "transparent"
                        border.color: "#585b70"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#cdd6f4"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: requestOptimization()
                    
                    ToolTip {
                        visible: parent.hovered
                        text: "Run system optimization"
                    }
                }
                
                Button {
                    text: "🧹"
                    font.pixelSize: 14
                    width: 30
                    height: 24
                    
                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#313244" : "transparent"
                        border.color: "#585b70"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#cdd6f4"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: requestCleanup()
                    
                    ToolTip {
                        visible: parent.hovered
                        text: "Run system cleanup"
                    }
                }
                
                // Spacer
                Item { Layout.fillWidth: true }
                
                Button {
                    text: aiActive ? "⏸" : "▶"
                    font.pixelSize: 12
                    width: 30
                    height: 24
                    
                    background: Rectangle {
                        radius: 6
                        color: parent.hovered ? "#313244" : "transparent"
                        border.color: aiActive ? "#a6e3a1" : "#f38ba8"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: aiActive ? "#a6e3a1" : "#f38ba8"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: toggleAI()
                    
                    ToolTip {
                        visible: parent.hovered
                        text: aiActive ? "Pause AI system" : "Resume AI system"
                    }
                }
            }
        }
    }
    
    // Signals
    signal themeChangeRequested()
    signal optimizationRequested()
    signal cleanupRequested()
    signal aiToggleRequested(bool enabled)
    
    // Functions
    function updateStatus() {
        // This would be called by the main shell to update status
        status = aiActive ? (confidence > 0.5 ? "learning" : "analyzing") : "paused"
    }
    
    function updateConfidence(newConfidence) {
        confidence = Math.max(0, Math.min(1, newConfidence))
    }
    
    function updateWorkload(workload) {
        currentWorkload = workload
    }
    
    function setRecommendation(recommendation) {
        lastRecommendation = recommendation
        if (recommendation && recommendation.confidence) {
            updateConfidence(recommendation.confidence)
        }
    }
    
    function requestThemeChange() {
        themeChangeRequested()
    }
    
    function requestOptimization() {
        optimizationRequested()
    }
    
    function requestCleanup() {
        cleanupRequested()
    }
    
    function toggleAI() {
        aiActive = !aiActive
        aiToggleRequested(aiActive)
    }
    
    function getWorkloadColor(workload) {
        switch(workload) {
            case "gaming": return "#f38ba8"
            case "development": return "#89b4fa"
            case "media": return "#f9e2af"
            case "productivity": return "#a6e3a1"
            default: return "#cba6f7"
        }
    }
    
    function getWorkloadIcon(workload) {
        switch(workload) {
            case "gaming": return "🎮"
            case "development": return "💻"
            case "media": return "🎨"
            case "productivity": return "📊"
            default: return "⚙️"
        }
    }
    
    function getConfidenceColor(conf) {
        if (conf >= 0.8) return "#a6e3a1"      // High confidence - green
        else if (conf >= 0.5) return "#f9e2af"  // Medium confidence - yellow
        else return "#f38ba8"                   // Low confidence - red
    }
    
    // Animation when showing
    Component.onCompleted: {
        // Fade in animation
        opacity = 0
        visible = true
        
        NumberAnimation {
            target: aiStatusWidget
            property: "opacity"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
