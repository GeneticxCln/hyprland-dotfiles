#!/bin/bash

# AI System Demonstration
# Shows all AI features and capabilities

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPTS_DIR="$(dirname "$0")"

demo_header() {
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                 🤖 AI System Demonstration               ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
}

demo_section() {
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${PURPLE}${'─'*60}${NC}"
}

demo_step() {
    echo -e "${YELLOW}  → $1${NC}"
}

demo_result() {
    echo -e "${GREEN}    ✓ $1${NC}"
}

demo_info() {
    echo -e "${CYAN}    ℹ $1${NC}"
}

wait_for_user() {
    echo -e "${BOLD}${YELLOW}Press Enter to continue...${NC}"
    read -r
}

demo_header

demo_section "1. AI Learning System - Data Collection"
demo_step "Collecting current system usage data..."
python3 "$SCRIPTS_DIR/learning-system.py" collect
demo_result "Usage patterns recorded for current time slot"
echo

demo_section "2. AI Recommendations Engine"
demo_step "Generating intelligent recommendations based on context..."
echo
python3 "$SCRIPTS_DIR/learning-system.py" recommend
echo
demo_info "The AI detected your workload and suggested optimal settings"
wait_for_user

demo_section "3. Intelligent Theme Switching"
demo_step "Testing context-aware theme selection..."
"$SCRIPTS_DIR/ai-enhancements.sh" theme
demo_result "Theme selected based on time and detected workload"
echo

demo_section "4. Smart System Cleanup"
demo_step "Analyzing system for cleanup opportunities..."
"$SCRIPTS_DIR/ai-enhancements.sh" cleanup
demo_result "System analyzed - cleanup performed where needed"
echo

demo_section "5. Performance Optimization"
demo_step "Optimizing system performance for current workload..."
"$SCRIPTS_DIR/ai-enhancements.sh" optimize
demo_result "Performance settings adjusted based on usage patterns"
echo

demo_section "6. Smart Notifications System"
demo_step "Testing intelligent notification system..."
"$SCRIPTS_DIR/ai-enhancements.sh" notify
demo_result "System health checked - notifications sent if needed"
echo

demo_section "7. System Status Report"
demo_step "Generating comprehensive system status..."
"$SCRIPTS_DIR/ai-scheduler.sh" status
echo
demo_result "Detailed system health report generated"
wait_for_user

demo_section "8. AI Learning Data Analysis"
demo_step "Examining collected learning data..."
echo

if [ -f "$HOME/.config/hypr/ai-enhancements/learning_data.json" ]; then
    echo -e "${CYAN}Usage Patterns Detected:${NC}"
    if command -v jq >/dev/null 2>&1; then
        jq -r '.usage_patterns | to_entries[] | "  • \(.key): \(.value.count) data points collected"' "$HOME/.config/hypr/ai-enhancements/learning_data.json"
    else
        echo "  • Learning data file exists and is collecting patterns"
    fi
    echo
    
    echo -e "${CYAN}Applications Tracked:${NC}"
    if command -v jq >/dev/null 2>&1; then
        jq -r '.app_usage | to_entries[] | "  • \(.key): \(.value.total_time) usage sessions"' "$HOME/.config/hypr/ai-enhancements/learning_data.json"
    else
        echo "  • Application usage patterns being recorded"
    fi
else
    demo_info "Learning data will accumulate over time as the system is used"
fi
echo

demo_section "9. AI Recommendations Analysis"
demo_step "Examining current AI recommendations..."
echo

if [ -f "$HOME/.config/hypr/ai-enhancements/recommendations.json" ]; then
    if command -v jq >/dev/null 2>&1; then
        echo -e "${CYAN}Current Recommendations:${NC}"
        echo -e "${YELLOW}Theme:${NC} $(jq -r '.theme_recommendation.theme' "$HOME/.config/hypr/ai-enhancements/recommendations.json")"
        echo -e "${YELLOW}Reason:${NC} $(jq -r '.theme_recommendation.reason' "$HOME/.config/hypr/ai-enhancements/recommendations.json")"
        echo -e "${YELLOW}Performance:${NC} $(jq -r '.performance_recommendation.reason' "$HOME/.config/hypr/ai-enhancements/recommendations.json")"
        echo -e "${YELLOW}Cleanup Priority:${NC} $(jq -r '.cleanup_recommendation.priority' "$HOME/.config/hypr/ai-enhancements/recommendations.json")"
        echo -e "${YELLOW}Confidence:${NC} $(jq -r '(.confidence_score * 100 | round)' "$HOME/.config/hypr/ai-enhancements/recommendations.json")%"
        echo
        echo -e "${CYAN}Workload Optimizations:${NC}"
        jq -r '.workload_optimization.suggestions[] | "  • \(.)"' "$HOME/.config/hypr/ai-enhancements/recommendations.json"
    else
        echo "  • Recommendations generated and available"
    fi
else
    demo_info "No recommendations file found"
fi
echo

wait_for_user

demo_section "10. Feedback Learning System"
demo_step "Demonstrating AI feedback learning..."
python3 "$SCRIPTS_DIR/learning-system.py" feedback --feedback-action "theme_switch" --feedback-value "positive"
demo_result "AI learned from positive feedback on theme switching"
echo

demo_section "11. All AI Features Combined"
demo_step "Running all AI enhancement features together..."
"$SCRIPTS_DIR/ai-enhancements.sh" all
demo_result "Complete AI system optimization cycle completed"
echo

demo_section "🎉 Demonstration Complete"
echo -e "${GREEN}${BOLD}AI System Features Demonstrated:${NC}"
echo -e "${GREEN}  ✓ Intelligent data collection and learning${NC}"
echo -e "${GREEN}  ✓ Context-aware recommendations${NC}"
echo -e "${GREEN}  ✓ Smart theme switching${NC}"
echo -e "${GREEN}  ✓ Automated system optimization${NC}"
echo -e "${GREEN}  ✓ Performance tuning based on workload${NC}"
echo -e "${GREEN}  ✓ Intelligent notifications${NC}"
echo -e "${GREEN}  ✓ System health monitoring${NC}"
echo -e "${GREEN}  ✓ Feedback-based learning${NC}"
echo

echo -e "${CYAN}${BOLD}Production Deployment:${NC}"
echo -e "${CYAN}  • Use: ./ai-scheduler.sh setup   (for automated operation)${NC}"
echo -e "${CYAN}  • Use: ./ai-enhancements.sh all  (for manual optimization)${NC}"
echo -e "${CYAN}  • Use: python3 learning-system.py collect  (for data collection)${NC}"
echo

echo -e "${YELLOW}${BOLD}The AI system learns and improves over time based on:${NC}"
echo -e "${YELLOW}  • Your daily usage patterns${NC}"
echo -e "${YELLOW}  • Application preferences${NC}"
echo -e "${YELLOW}  • System performance metrics${NC}"
echo -e "${YELLOW}  • User feedback${NC}"
echo

echo -e "${PURPLE}${BOLD}Thank you for exploring the AI system! 🚀${NC}"
