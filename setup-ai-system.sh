#!/bin/bash

# AI System Setup and Configuration
# Sets up the AI components to work with your current project structure

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_SCRIPTS_DIR="$PROJECT_DIR/scripts/ai"
HOME_AI_DIR="$HOME/.config/hypr/scripts/ai"

log() { echo -e "${BLUE}[AI-SETUP]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                  🤖 AI SYSTEM SETUP 🤖                          ║
║                                                                  ║
║  Setting up intelligent desktop automation                       ║
║  • Smart System Optimizer                                       ║
║  • Predictive Maintenance                                       ║
║  • Workload Automation                                          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Check dependencies
check_dependencies() {
    log "Checking AI system dependencies..."
    
    local missing_deps=()
    
    # Essential tools
    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v bc &>/dev/null; then
        missing_deps+=("bc")
    fi
    
    if ! command -v iostat &>/dev/null; then
        missing_deps+=("sysstat")
    fi
    
    # Optional but useful
    if ! command -v sensors &>/dev/null; then
        log "lm_sensors not found - temperature monitoring will be limited"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}\nInstall with: sudo pacman -S ${missing_deps[*]}"
    fi
    
    success "All dependencies satisfied"
}

# Setup AI directories and symlinks
setup_ai_directories() {
    log "Setting up AI system directories..."
    
    # Create config directory structure
    mkdir -p "$HOME/.config/hypr/ai-manager"
    mkdir -p "$HOME/.config/hypr/ai-optimizer"
    mkdir -p "$HOME/.config/hypr/predictive-maintenance"
    mkdir -p "$HOME/.config/hypr/workload-automation"
    mkdir -p "$(dirname "$HOME_AI_DIR")"
    
    # Create symlinks to project scripts
    if [ -d "$HOME_AI_DIR" ]; then
        rm -rf "$HOME_AI_DIR"
    fi
    
    ln -sf "$AI_SCRIPTS_DIR" "$HOME_AI_DIR"
    success "AI directories and symlinks created"
}

# Initialize AI systems
initialize_ai_systems() {
    log "Initializing AI systems..."
    
    # Initialize each system
    "$HOME_AI_DIR/ai-manager.sh" configure <<< "y
y
y
y
y"
    
    success "AI systems initialized with default configuration"
}

# Create AI system service files (optional)
create_system_services() {
    log "Creating systemd user service files..."
    
    mkdir -p "$HOME/.config/systemd/user"
    
    # AI Manager service
    cat > "$HOME/.config/systemd/user/ai-manager.service" << EOF
[Unit]
Description=AI System Manager
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$HOME_AI_DIR/ai-manager.sh start
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF

    # Smart Optimizer Timer
    cat > "$HOME/.config/systemd/user/smart-optimizer.timer" << EOF
[Unit]
Description=Smart Optimizer Timer
Requires=smart-optimizer.service

[Timer]
OnCalendar=*:0/30
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > "$HOME/.config/systemd/user/smart-optimizer.service" << EOF
[Unit]
Description=Smart System Optimizer
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$HOME_AI_DIR/smart-optimizer.sh collect
ExecStart=$HOME_AI_DIR/smart-optimizer.sh analyze
EOF

    # Predictive Maintenance Timer
    cat > "$HOME/.config/systemd/user/predictive-maintenance.timer" << EOF
[Unit]
Description=Predictive Maintenance Timer
Requires=predictive-maintenance.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > "$HOME/.config/systemd/user/predictive-maintenance.service" << EOF
[Unit]
Description=Predictive Maintenance Monitor
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$HOME_AI_DIR/predictive-maintenance.sh health
ExecStart=$HOME_AI_DIR/predictive-maintenance.sh predict
EOF

    # Workload Automation Timer  
    cat > "$HOME/.config/systemd/user/workload-automation.timer" << EOF
[Unit]
Description=Workload Automation Timer
Requires=workload-automation.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > "$HOME/.config/systemd/user/workload-automation.service" << EOF
[Unit]
Description=Workload Automation Engine
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$HOME_AI_DIR/workload-automation.sh detect
ExecStart=$HOME_AI_DIR/workload-automation.sh auto-apply
EOF

    # Reload systemd user services
    systemctl --user daemon-reload
    
    success "Systemd service files created"
}

# Enable AI services (optional)
enable_ai_services() {
    log "Do you want to enable automatic AI system startup?"
    read -p "Enable AI services on login? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl --user enable ai-manager.service
        systemctl --user enable smart-optimizer.timer
        systemctl --user enable predictive-maintenance.timer
        systemctl --user enable workload-automation.timer
        
        log "Starting AI services now..."
        systemctl --user start ai-manager.service
        systemctl --user start smart-optimizer.timer
        systemctl --user start predictive-maintenance.timer
        systemctl --user start workload-automation.timer
        
        success "AI services enabled and started"
    else
        log "AI services not enabled - you can run manually with ai-manager commands"
    fi
}

# Create convenience wrapper script
create_ai_wrapper() {
    log "Creating AI management wrapper script..."
    
    cat > "$HOME/.local/bin/ai-manager" << EOF
#!/bin/bash
# AI Manager wrapper script
exec "$HOME_AI_DIR/ai-manager.sh" "\$@"
EOF
    
    chmod +x "$HOME/.local/bin/ai-manager"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    success "AI manager wrapper created at ~/.local/bin/ai-manager"
}

# Test AI systems
test_ai_systems() {
    log "Testing AI systems..."
    
    # Test AI manager
    if "$HOME_AI_DIR/ai-manager.sh" health; then
        success "AI Manager health check passed"
    else
        warning "AI Manager health check issues detected"
    fi
    
    # Test smart optimizer
    log "Testing Smart Optimizer..."
    "$HOME_AI_DIR/smart-optimizer.sh" collect || warning "Smart Optimizer test had issues"
    
    # Test predictive maintenance
    log "Testing Predictive Maintenance..."
    "$HOME_AI_DIR/predictive-maintenance.sh" health || warning "Predictive Maintenance test had issues"
    
    # Test workload automation
    log "Testing Workload Automation..."
    "$HOME_AI_DIR/workload-automation.sh" detect || warning "Workload Automation test had issues"
    
    success "AI system testing completed"
}

# Show final status
show_final_status() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  AI SETUP COMPLETE                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${GREEN}✅ AI Systems Ready:${NC}"
    echo "  • Smart Optimizer - Learning system usage patterns"
    echo "  • Predictive Maintenance - Monitoring system health"
    echo "  • Workload Automation - Auto-detecting workloads"
    
    echo -e "\n${GREEN}Usage Commands:${NC}"
    echo "  ai-manager dashboard    # Show AI status"
    echo "  ai-manager optimize     # Run coordinated optimization"
    echo "  ai-manager start        # Start all AI systems"
    echo "  ai-manager configure    # Configure AI systems"
    
    echo -e "\n${GREEN}Individual Systems:${NC}"
    echo "  ai-manager smart dashboard        # Smart optimizer status"
    echo "  ai-manager maintenance dashboard  # Health monitoring"
    echo "  ai-manager workload dashboard     # Workload automation"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "1. Run: ai-manager dashboard"
    echo "2. Let it learn for a day to build patterns"
    echo "3. Check ai-manager optimize for recommendations"
    
    echo -e "\n🤖 Your desktop now has AI-powered automation!"
}

# Main installation
main() {
    show_banner
    
    log "Setting up AI system for your Hyprland configuration..."
    
    check_dependencies
    setup_ai_directories
    initialize_ai_systems
    create_system_services
    enable_ai_services
    create_ai_wrapper
    test_ai_systems
    show_final_status
}

# Handle arguments
case "${1:-install}" in
    install)
        main
        ;;
    test)
        test_ai_systems
        ;;
    status)
        "$HOME_AI_DIR/ai-manager.sh" dashboard
        ;;
    help)
        echo "AI System Setup Script"
        echo "Usage: $0 [install|test|status|help]"
        echo
        echo "  install  - Full AI system setup (default)"
        echo "  test     - Test existing AI systems"
        echo "  status   - Show AI system status"
        echo "  help     - Show this help"
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
