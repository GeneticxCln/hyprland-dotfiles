// WorkspaceDetection.qml - Smart Workspace Detection with Desktop View Animation
// Intelligent workspace monitoring with animated desktop previews

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell 1.0
import Quickshell.Io 1.0

ShellWindow {
    id: workspaceDetector
    
    // Window properties
    width: showDesktopView ? 1000 : 200
    height: showDesktopView ? 600 : 50
    visible: true
    
    // Position (top-left for compact, center for expanded)
    anchor {
        left: !showDesktopView
        top: !showDesktopView
        margins: {
            left: showDesktopView ? 0 : 20
            top: showDesktopView ? 0 : 100
        }
    }
    
    // Properties
    property int currentWorkspace: 1
    property var workspaces: []
    property bool showDesktopView: false
    property var workspaceData: ({})
    property bool animationsEnabled: true
    property string detectionMode: "smart"
    
    // Workspace type detection
    property var workspaceTypes: ({
        1: { name: "Main", type: "productivity", apps: [], color: "#89b4fa", icon: "🏠" },
        2: { name: "Code", type: "development", apps: [], color: "#a6e3a1", icon: "💻" },
        3: { name: "Web", type: "productivity", apps: [], color: "#89b4fa", icon: "🌐" },
        4: { name: "Media", type: "media", apps: [], color: "#fab387", icon: "🎬" },
        5: { name: "Game", type: "gaming", apps: [], color: "#f38ba8", icon: "🎮" },
        6: { name: "Chat", type: "productivity", apps: [], color: "#cba6f7", icon: "💬" },
        7: { name: "Tools", type: "development", apps: [], color: "#a6e3a1", icon: "🔧" },
        8: { name: "Music", type: "media", apps: [], color: "#fab387", icon: "🎵" },
        9: { name: "Files", type: "productivity", apps: [], color: "#89b4fa", icon: "📁" },
        10: { name: "Misc", type: "idle", apps: [], color: "#6c7086", icon: "📦" }
    })
    
    // Background
    Rectangle {
        id: background
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: showDesktopView ? 0.95 : 0.8
        radius: showDesktopView ? 20 : 12
        border.color: getCurrentWorkspaceColor()
        border.width: 2
        
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.3) }
            }
        }
    }
    
    // Compact view
    Rectangle {
        id: compactView
        anchors.fill: parent
        anchors.margins: 8
        color: "transparent"
        visible: !showDesktopView
        
        RowLayout {
            anchors.fill: parent
            spacing: 12
            
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: getCurrentWorkspaceColor()
                
                Text {
                    anchors.centerIn: parent
                    text: getCurrentWorkspaceIcon()
                    font.pixelSize: 16
                    color: "#1e1e2e"
                }
            }
            
            Column {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    text: getCurrentWorkspaceName()
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#cdd6f4"
                }
                
                Text {
                    text: getWorkspaceAppCount() + " apps • " + getCurrentWorkspaceType()
                    font.pixelSize: 9
                    color: "#a6adc8"
                }
            }
            
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                border.color: "#6c7086"
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: "◉"
                    font.pixelSize: 12
                    color: "#6c7086"
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showDesktopView = true
                    onEntered: parent.border.color = "#cdd6f4"
                    onExited: parent.border.color = "#6c7086"
                }
            }
        }
    }
    
    // Desktop view
    Rectangle {
        id: desktopView
        anchors.fill: parent
        anchors.margins: 20
        color: "transparent"
        visible: showDesktopView
        
        // Header
        RowLayout {
            id: header
            width: parent.width
            height: 60
            anchors.top: parent.top
            anchors.margins: 16
            
            Text {
                text: "🖥️ Workspace Overview"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: "#cdd6f4"
                Layout.fillWidth: true
            }
            
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: "#f38ba8"
                
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#1e1e2e"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: showDesktopView = false
                }
            }
        }
        
        // Workspace grid
        GridView {
            id: workspaceGrid
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: smartInfo.top
                margins: 16
            }
            
            cellWidth: 180
            cellHeight: 140
            model: 10
            
            delegate: Rectangle {
                width: 170
                height: 130
                radius: 12
                color: getWorkspaceColor(index + 1)
                opacity: currentWorkspace === (index + 1) ? 1.0 : 0.7
                border.color: currentWorkspace === (index + 1) ? "#cdd6f4" : "transparent"
                border.width: currentWorkspace === (index + 1) ? 2 : 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Rectangle {
                        width: 50
                        height: 50
                        radius: 25
                        color: "#1e1e2e"
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: getWorkspaceIcon(index + 1)
                            font.pixelSize: 24
                        }
                    }
                    
                    Text {
                        text: getWorkspaceName(index + 1)
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#1e1e2e"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: getWorkspaceApps(index + 1).length + " apps"
                        font.pixelSize: 9
                        color: "#1e1e2e"
                        opacity: 0.7
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: switchToWorkspace(index + 1)
                    onEntered: parent.scale = 1.05
                    onExited: parent.scale = 1.0
                }
                
                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }
        
        // Smart info
        Row {
            id: smartInfo
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                margins: 16
            }
            spacing: 16
            
            Text {
                text: "🤖 Smart Detection: ON"
                font.pixelSize: 10
                color: "#a6adc8"
            }
            
            Text {
                text: "📊 Active: " + getActiveWorkspaceCount()
                font.pixelSize: 10
                color: "#a6adc8"
            }
            
            Text {
                text: "⚡ Current: WS" + currentWorkspace
                font.pixelSize: 10
                color: getCurrentWorkspaceColor()
            }
        }
    }
    
    // Animations
    Behavior on width {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    Behavior on height {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    // Processes
    Process {
        id: activeWorkspaceProcess
        command: ["hyprctl", "activeworkspace", "-j"]
        onFinished: {
            if (exitCode === 0) {
                try {
                    var data = JSON.parse(stdout)
                    currentWorkspace = data.id
                } catch (e) {}
            }
        }
    }
    
    Process {
        id: clientsProcess
        command: ["hyprctl", "clients", "-j"]
        onFinished: {
            if (exitCode === 0) {
                try {
                    var data = JSON.parse(stdout)
                    updateClientData(data)
                } catch (e) {}
            }
        }
    }
    
    // Timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            activeWorkspaceProcess.start()
            if (showDesktopView) {
                clientsProcess.start()
            }
        }
    }
    
    // Functions
    function getCurrentWorkspaceColor() {
        return workspaceTypes[currentWorkspace]?.color || "#6c7086"
    }
    
    function getCurrentWorkspaceIcon() {
        return workspaceTypes[currentWorkspace]?.icon || "📦"
    }
    
    function getCurrentWorkspaceName() {
        return workspaceTypes[currentWorkspace]?.name || "Workspace " + currentWorkspace
    }
    
    function getCurrentWorkspaceType() {
        return workspaceTypes[currentWorkspace]?.type || "idle"
    }
    
    function getWorkspaceColor(id) {
        return workspaceTypes[id]?.color || "#6c7086"
    }
    
    function getWorkspaceIcon(id) {
        return workspaceTypes[id]?.icon || "📦"
    }
    
    function getWorkspaceName(id) {
        return workspaceTypes[id]?.name || "Workspace " + id
    }
    
    function getWorkspaceApps(id) {
        return workspaceTypes[id]?.apps || []
    }
    
    function getWorkspaceAppCount() {
        return workspaceTypes[currentWorkspace]?.apps.length || 0
    }
    
    function getActiveWorkspaceCount() {
        var count = 0
        for (var i = 1; i <= 10; i++) {
            if (workspaceTypes[i]?.apps.length > 0) {
                count++
            }
        }
        return count
    }
    
    function updateClientData(data) {
        for (var i = 1; i <= 10; i++) {
            if (workspaceTypes[i]) {
                workspaceTypes[i].apps = []
            }
        }
        
        for (var j = 0; j < data.length; j++) {
            var client = data[j]
            var wsId = client.workspace.id
            
            if (workspaceTypes[wsId] && client.class) {
                workspaceTypes[wsId].apps.push({
                    class: client.class,
                    title: client.title
                })
            }
        }
    }
    
    function switchToWorkspace(id) {
        var switchProcess = Qt.createQmlObject(`
            import Quickshell.Io 1.0;
            Process {
                command: ["hyprctl", "dispatch", "workspace", "${id}"]
            }
        `, workspaceDetector)
        
        switchProcess.finished.connect(function() {
            currentWorkspace = id
            showDesktopView = false
            switchProcess.destroy()
        })
        
        switchProcess.start()
    }
    
    // Shortcuts
    Shortcut {
        sequence: "Meta+Tab"
        onActivated: showDesktopView = !showDesktopView
    }
    
    Component.onCompleted: {
        console.log("WorkspaceDetection initialized")
        activeWorkspaceProcess.start()
        clientsProcess.start()
    }
}
