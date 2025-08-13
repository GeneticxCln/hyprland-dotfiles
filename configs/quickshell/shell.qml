// Quickshell Configuration - Modern Qt-based Shell
// Main entry point for Quickshell panels and widgets

import QtQuick 2.15
import Quickshell 1.0
import Quickshell.Io 1.0
import Quickshell.Wayland 1.0
import "components" as Components
import "panels" as Panels

ShellRoot {
    id: root
    
    // Global properties
    property color accentColor: "#cba6f7"
    property color backgroundColor: "#1e1e2e"
    property color foregroundColor: "#cdd6f4"
    property color surfaceColor: "#313244"
    property real globalOpacity: 0.95
    property int animationDuration: 200
    
    // System tray configuration
    SystemTray {
        id: systemTray
    }
    
    // Top Panel
    Panels.TopPanel {
        id: topPanel
        screen: Quickshell.screens[0]
    }
    
    // Dock Panel (optional, can be toggled)
    property bool dockEnabled: true
    
    Panels.DockPanel {
        id: dockPanel
        screen: Quickshell.screens[0]
        visible: dockEnabled
    }
    
    // Desktop widgets
    Components.ClockWidget {
        id: clockWidget
        screen: Quickshell.screens[0]
    }
    
    Components.SystemMonitor {
        id: sysMonitor
        screen: Quickshell.screens[0]
    }
    
    // Notification handler
    Components.NotificationHandler {
        id: notificationHandler
    }
    
    // Global shortcuts
    Shortcuts {
        // Toggle dock visibility
        Shortcut {
            sequence: "Meta+D"
            onActivated: root.dockEnabled = !root.dockEnabled
        }
        
        // Show app launcher
        Shortcut {
            sequence: "Meta+Space"
            onActivated: appLauncher.toggle()
        }
        
        // Show system menu
        Shortcut {
            sequence: "Meta+X"
            onActivated: systemMenu.toggle()
        }
    }
    
    // App Launcher overlay
    Components.AppLauncher {
        id: appLauncher
        screen: Quickshell.screens[0]
    }
    
    // System Menu overlay
    Components.SystemMenu {
        id: systemMenu
        screen: Quickshell.screens[0]
    }
    
    // Workspace indicator
    Components.WorkspaceIndicator {
        id: workspaceIndicator
        screen: Quickshell.screens[0]
    }
    
    // Window manager integration
    WaylandIntegration {
        id: waylandIntegration
        
        onWorkspaceChanged: {
            workspaceIndicator.currentWorkspace = workspace
        }
        
        onWindowFocused: {
            topPanel.updateWindowTitle(window.title)
        }
    }
    
    // Theme manager
    Components.ThemeManager {
        id: themeManager
        
        onThemeChanged: {
            root.accentColor = theme.accent
            root.backgroundColor = theme.background
            root.foregroundColor = theme.foreground
            root.surfaceColor = theme.surface
        }
    }
    
    // Performance monitor
    Timer {
        interval: 1000
        running: true
        repeat: true
        
        onTriggered: {
            sysMonitor.update()
        }
    }
    
    // Startup animation
    Component.onCompleted: {
        console.log("Quickshell initialized")
        topPanel.show()
        if (dockEnabled) {
            dockPanel.show()
        }
        clockWidget.show()
        sysMonitor.show()
    }
}
