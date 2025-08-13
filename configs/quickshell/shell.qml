// Quickshell Configuration - AI-Enhanced Modern Shell
// Main entry point for Quickshell panels and widgets with AI integration

import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell 1.0
import Quickshell.Io 1.0
import Quickshell.Wayland 1.0
import "components" as Components
import "panels" as Panels
import "widgets" as Widgets

ShellRoot {
    id: root
    
    // AI System Integration
    property var aiSystem: Components.AIIntegration {
        id: aiIntegration
        onRecommendationReceived: (recommendation) => {
            console.log("AI Recommendation:", recommendation)
            handleAIRecommendation(recommendation)
        }
        onThemeChangeRequested: (themeName) => {
            themeManager.applyTheme(themeName)
        }
        onWorkloadDetected: (workload) => {
            console.log("Workload detected:", workload)
            topPanel.updateWorkloadIndicator(workload)
        }
    }
    
    // Global theme properties (dynamically updated by AI)
    property color accentColor: "#cba6f7"
    property color backgroundColor: "#1e1e2e"
    property color foregroundColor: "#cdd6f4"
    property color surfaceColor: "#313244"
    property color warningColor: "#f9e2af"
    property color errorColor: "#f38ba8"
    property color successColor: "#a6e3a1"
    property real globalOpacity: 0.95
    property int animationDuration: 200
    property string currentWorkload: "general"
    property bool aiOptimizationsEnabled: true
    
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
        aiEnabled: root.aiOptimizationsEnabled
    }
    
    // AI-specific widgets
    Widgets.AIStatusWidget {
        id: aiStatusWidget
        screen: Quickshell.screens[0]
        visible: aiOptimizationsEnabled
    }
    
    Widgets.WorkloadIndicator {
        id: workloadIndicator
        screen: Quickshell.screens[0]
        currentWorkload: root.currentWorkload
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
    
    // Smart workspace detection with desktop view animation
    Components.WorkspaceDetection {
        id: workspaceDetection
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
    
    // AI recommendation timer
    Timer {
        id: aiRecommendationTimer
        interval: 300000 // 5 minutes
        running: aiOptimizationsEnabled
        repeat: true
        
        onTriggered: {
            aiIntegration.requestRecommendations()
        }
    }
    
    // Performance monitor
    Timer {
        interval: 1000
        running: true
        repeat: true
        
        onTriggered: {
            sysMonitor.update()
            if (aiOptimizationsEnabled) {
                aiStatusWidget.updateStatus()
            }
        }
    }
    
    // Workload detection timer
    Timer {
        id: workloadDetectionTimer
        interval: 30000 // 30 seconds
        running: aiOptimizationsEnabled
        repeat: true
        
        onTriggered: {
            aiIntegration.detectCurrentWorkload()
        }
    }
    
    // AI recommendation handler
    function handleAIRecommendation(recommendation) {
        switch(recommendation.type) {
            case "theme":
                if (recommendation.confidence > 0.7) {
                    themeManager.applyTheme(recommendation.theme)
                    notificationHandler.showNotification(
                        "AI Theme Switch", 
                        `Applied ${recommendation.theme} theme for ${recommendation.workload} workload`
                    )
                }
                break
            case "performance":
                console.log("Performance recommendation:", recommendation.settings)
                break
            case "cleanup":
                if (recommendation.priority === "high") {
                    notificationHandler.showNotification(
                        "System Cleanup", 
                        "AI recommends system cleanup - high priority"
                    )
                }
                break
            case "break":
                if (recommendation.recommend_break) {
                    notificationHandler.showNotification(
                        "Break Reminder", 
                        `You've been active for ${recommendation.session_duration} hours. Consider taking a break!`
                    )
                }
                break
        }
    }
    
    // Toggle AI optimizations
    function toggleAIOptimizations() {
        aiOptimizationsEnabled = !aiOptimizationsEnabled
        console.log("AI optimizations", aiOptimizationsEnabled ? "enabled" : "disabled")
    }
    
    // Apply AI theme recommendation
    function applyAITheme(themeName, reason) {
        themeManager.applyTheme(themeName)
        notificationHandler.showNotification("AI Theme Applied", reason)
    }
    
    // Update workload indicator
    function updateWorkload(workload) {
        root.currentWorkload = workload
        workloadIndicator.currentWorkload = workload
        topPanel.updateWorkloadIndicator(workload)
    }
    
    // Startup animation and AI initialization
    Component.onCompleted: {
        console.log("Quickshell with AI integration initialized")
        topPanel.show()
        if (dockEnabled) {
            dockPanel.show()
        }
        clockWidget.show()
        sysMonitor.show()
        
        // Initialize AI system
        if (aiOptimizationsEnabled) {
            aiIntegration.initialize()
            aiStatusWidget.show()
            workloadIndicator.show()
            console.log("AI system ready")
        }
    }
}
