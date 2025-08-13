// AI System Integration Component
// Bridges Quickshell with the AI system scripts

import QtQuick 2.15
import Quickshell 1.0
import Quickshell.Io 1.0

QtObject {
    id: aiIntegration
    
    // Signals for AI events
    signal recommendationReceived(var recommendation)
    signal themeChangeRequested(string themeName)
    signal workloadDetected(string workload)
    signal systemHealthUpdated(var healthData)
    
    // Properties
    property bool initialized: false
    property string currentWorkload: "general"
    property var lastRecommendation: ({})
    property real confidence: 0.0
    property string aiScriptsPath: "~/.config/hypr/scripts/ai"
    
    // Process for running AI commands
    property var aiProcess: Process {
        id: aiProcess
        command: ["python3"]
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                try {
                    const result = JSON.parse(stdout)
                    handleAIResponse(result)
                } catch (e) {
                    console.warn("Failed to parse AI response:", e)
                }
            } else {
                console.warn("AI process failed:", stderr)
            }
        }
    }
    
    // Learning system process
    property var learningProcess: Process {
        id: learningProcess
        command: ["python3"]
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && stdout.length > 0) {
                try {
                    const data = JSON.parse(stdout)
                    processLearningData(data)
                } catch (e) {
                    console.warn("Failed to parse learning data:", e)
                }
            }
        }
    }
    
    // Enhancement script process
    property var enhancementProcess: Process {
        id: enhancementProcess
        command: ["/bin/bash"]
        
        onExited: (exitCode, exitStatus) => {
            console.log("AI enhancement completed:", exitCode === 0 ? "success" : "failed")
        }
    }
    
    // Initialize AI integration
    function initialize() {
        if (initialized) return
        
        console.log("Initializing AI integration...")
        
        // Start collecting data immediately
        collectUsageData()
        
        // Request initial recommendations
        requestRecommendations()
        
        initialized = true
        console.log("AI integration initialized")
    }
    
    // Collect current usage data
    function collectUsageData() {
        if (!initialized) return
        
        learningProcess.command = [
            "python3", 
            aiScriptsPath + "/learning-system.py", 
            "collect"
        ]
        learningProcess.start()
    }
    
    // Request AI recommendations
    function requestRecommendations() {
        if (!initialized) return
        
        learningProcess.command = [
            "python3", 
            aiScriptsPath + "/learning-system.py", 
            "recommend"
        ]
        learningProcess.start()
    }
    
    // Detect current workload
    function detectCurrentWorkload() {
        // This would typically analyze running processes
        // For now, we'll use a simple heuristic
        
        const processes = getRunningProcesses()
        let detectedWorkload = "general"
        
        // Gaming workload
        if (processes.some(p => ["steam", "lutris", "heroic", "wine"].includes(p.toLowerCase()))) {
            detectedWorkload = "gaming"
        }
        // Development workload  
        else if (processes.some(p => ["code", "nvim", "vim", "jetbrains"].includes(p.toLowerCase()))) {
            detectedWorkload = "development"
        }
        // Media workload
        else if (processes.some(p => ["vlc", "mpv", "gimp", "inkscape", "obs"].includes(p.toLowerCase()))) {
            detectedWorkload = "media"
        }
        // Productivity workload
        else if (processes.some(p => ["firefox", "chrome", "thunderbird", "discord"].includes(p.toLowerCase()))) {
            detectedWorkload = "productivity"
        }
        
        if (detectedWorkload !== currentWorkload) {
            currentWorkload = detectedWorkload
            workloadDetected(detectedWorkload)
        }
    }
    
    // Apply AI theme
    function applyTheme(themeName) {
        enhancementProcess.command = [
            "/bin/bash",
            aiScriptsPath + "/ai-enhancements.sh",
            "theme"
        ]
        enhancementProcess.start()
        themeChangeRequested(themeName)
    }
    
    // Trigger system optimization
    function optimizeSystem() {
        enhancementProcess.command = [
            "/bin/bash",
            aiScriptsPath + "/ai-enhancements.sh",
            "optimize"
        ]
        enhancementProcess.start()
    }
    
    // Trigger system cleanup
    function cleanupSystem() {
        enhancementProcess.command = [
            "/bin/bash",
            aiScriptsPath + "/ai-enhancements.sh",
            "cleanup"
        ]
        enhancementProcess.start()
    }
    
    // Send feedback to AI system
    function sendFeedback(action, value) {
        learningProcess.command = [
            "python3",
            aiScriptsPath + "/learning-system.py",
            "feedback",
            "--feedback-action", action,
            "--feedback-value", value
        ]
        learningProcess.start()
    }
    
    // Handle AI response data
    function handleAIResponse(data) {
        console.log("AI Response received:", JSON.stringify(data))
        
        if (data.theme_recommendation) {
            const themeRec = data.theme_recommendation
            recommendationReceived({
                type: "theme",
                theme: themeRec.theme,
                workload: themeRec.workload,
                reason: themeRec.reason,
                confidence: data.confidence_score || 0.5
            })
        }
        
        if (data.performance_recommendation) {
            recommendationReceived({
                type: "performance",
                settings: data.performance_recommendation,
                confidence: data.confidence_score || 0.5
            })
        }
        
        if (data.cleanup_recommendation) {
            recommendationReceived({
                type: "cleanup",
                priority: data.cleanup_recommendation.priority,
                actions: data.cleanup_recommendation.actions,
                confidence: data.confidence_score || 0.5
            })
        }
        
        if (data.break_recommendation) {
            recommendationReceived({
                type: "break",
                recommend_break: data.break_recommendation.recommend_break,
                session_duration: data.break_recommendation.session_duration,
                confidence: 1.0
            })
        }
        
        // Update confidence score
        confidence = data.confidence_score || 0.0
        lastRecommendation = data
    }
    
    // Process learning data updates
    function processingLearningData(data) {
        console.log("Learning data updated")
        // Could trigger UI updates based on learning progress
    }
    
    // Mock function to get running processes (would need actual implementation)
    function getRunningProcesses() {
        // In a real implementation, this would query the system
        // For now, return some common processes as examples
        return ["chrome", "code", "terminal", "discord"]
    }
    
    // Get system health data
    function getSystemHealth() {
        enhancementProcess.command = [
            "/bin/bash",
            aiScriptsPath + "/ai-scheduler.sh",
            "status"
        ]
        enhancementProcess.start()
    }
    
    // Periodic data collection timer
    Timer {
        id: dataCollectionTimer
        interval: 300000 // 5 minutes
        running: initialized
        repeat: true
        
        onTriggered: {
            collectUsageData()
        }
    }
    
    // Workload detection timer  
    Timer {
        id: workloadTimer
        interval: 30000 // 30 seconds
        running: initialized
        repeat: true
        
        onTriggered: {
            detectCurrentWorkload()
        }
    }
}
