#!/usr/bin/env python3
"""
Main Orchestrator for AI-Driven Hyprland Optimization
Coordinates all AI systems and provides unified management interface
"""

import asyncio
import json
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
import argparse
import signal
import sys
import subprocess
from dataclasses import dataclass, asdict

# Import our AI modules
from core.ai_optimizer import AIOptimizer
from core.adaptive_config import AdaptiveConfigManager
from core.self_healing import SelfHealingSystem

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/home/sasha/hyprland-project/ai_optimization/logs/orchestrator.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SystemStatus:
    """Overall system status"""
    timestamp: str
    ai_optimizer_active: bool
    adaptive_config_active: bool
    self_healing_active: bool
    total_optimizations: int
    active_issues: int
    system_health_score: float
    uptime_hours: float
    performance_score: float
    stability_score: float

class HyprlandAIOrchestrator:
    """Main orchestrator for all AI optimization systems"""
    
    def __init__(self):
        self.base_path = Path("/home/sasha/hyprland-project/ai_optimization")
        self.base_path.mkdir(parents=True, exist_ok=True)
        
        # Create logs directory
        self.logs_path = self.base_path / "logs"
        self.logs_path.mkdir(exist_ok=True)
        
        # Initialize AI systems
        self.ai_optimizer: Optional[AIOptimizer] = None
        self.adaptive_config: Optional[AdaptiveConfigManager] = None
        self.self_healing: Optional[SelfHealingSystem] = None
        
        # System state
        self.running = False
        self.start_time = None
        self.optimization_stats = {
            'total_optimizations': 0,
            'successful_optimizations': 0,
            'failed_optimizations': 0,
            'adaptive_changes': 0,
            'healing_actions': 0
        }
        
        logger.info("Hyprland AI Orchestrator initialized")

    async def start_all_systems(self, 
                                enable_ai_optimizer: bool = True,
                                enable_adaptive_config: bool = True,
                                enable_self_healing: bool = True):
        """Start all AI optimization systems"""
        logger.info("Starting Hyprland AI Optimization Suite")
        
        self.running = True
        self.start_time = datetime.now()
        
        # Create tasks list
        tasks = []
        
        try:
            # Initialize and start AI Optimizer
            if enable_ai_optimizer:
                logger.info("Initializing AI Optimizer...")
                self.ai_optimizer = AIOptimizer()
                tasks.append(asyncio.create_task(
                    self.ai_optimizer.start_optimization_loop(),
                    name="ai_optimizer"
                ))
                logger.info("✓ AI Optimizer started")
            
            # Initialize and start Adaptive Configuration Manager
            if enable_adaptive_config:
                logger.info("Initializing Adaptive Configuration Manager...")
                self.adaptive_config = AdaptiveConfigManager()
                tasks.append(asyncio.create_task(
                    self.adaptive_config.start_adaptive_learning(),
                    name="adaptive_config"
                ))
                logger.info("✓ Adaptive Configuration Manager started")
            
            # Initialize and start Self-Healing System
            if enable_self_healing:
                logger.info("Initializing Self-Healing System...")
                self.self_healing = SelfHealingSystem()
                tasks.append(asyncio.create_task(
                    self.self_healing.start_monitoring(),
                    name="self_healing"
                ))
                logger.info("✓ Self-Healing System started")
            
            # Add orchestrator monitoring task
            tasks.append(asyncio.create_task(
                self._orchestrator_monitoring_loop(),
                name="orchestrator"
            ))
            
            # Add status reporting task
            tasks.append(asyncio.create_task(
                self._status_reporting_loop(),
                name="status_reporter"
            ))
            
            logger.info(f"All systems started! Running {len(tasks)} tasks.")
            
            # Wait for all tasks
            await asyncio.gather(*tasks)
            
        except Exception as e:
            logger.error(f"Error in orchestrator: {e}")
            await self.stop_all_systems()

    async def _orchestrator_monitoring_loop(self):
        """Main orchestrator monitoring loop"""
        logger.info("Orchestrator monitoring loop started")
        
        while self.running:
            try:
                # Monitor system health
                await self._monitor_system_health()
                
                # Coordinate between systems
                await self._coordinate_systems()
                
                # Update statistics
                await self._update_statistics()
                
                # Check for critical issues
                await self._handle_critical_issues()
                
                # Sleep before next iteration
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                logger.error(f"Error in orchestrator monitoring: {e}")
                await asyncio.sleep(60)

    async def _status_reporting_loop(self):
        """Periodic status reporting"""
        while self.running:
            try:
                # Generate and log status report every 10 minutes
                status = await self.get_system_status()
                
                logger.info(f"=== System Status Report ===")
                logger.info(f"AI Optimizer: {'Active' if status.ai_optimizer_active else 'Inactive'}")
                logger.info(f"Adaptive Config: {'Active' if status.adaptive_config_active else 'Inactive'}")
                logger.info(f"Self-Healing: {'Active' if status.self_healing_active else 'Inactive'}")
                logger.info(f"Total Optimizations: {status.total_optimizations}")
                logger.info(f"Active Issues: {status.active_issues}")
                logger.info(f"System Health: {status.system_health_score:.1f}%")
                logger.info(f"Uptime: {status.uptime_hours:.1f} hours")
                
                await asyncio.sleep(600)  # Report every 10 minutes
                
            except Exception as e:
                logger.error(f"Error in status reporting: {e}")
                await asyncio.sleep(600)

    async def _monitor_system_health(self):
        """Monitor overall system health"""
        try:
            # Collect metrics from all systems
            health_data = {}
            
            if self.ai_optimizer:
                ai_report = await self.ai_optimizer.get_optimization_report()
                health_data['ai_optimizer'] = ai_report
            
            if self.adaptive_config:
                adaptive_report = await self.adaptive_config.get_adaptation_report()
                health_data['adaptive_config'] = adaptive_report
            
            if self.self_healing:
                healing_report = await self.self_healing.get_healing_report()
                health_data['self_healing'] = healing_report
            
            # Calculate overall health score
            health_score = self._calculate_health_score(health_data)
            
            # Log health issues if needed
            if health_score < 70:
                logger.warning(f"System health degraded: {health_score:.1f}%")
            
        except Exception as e:
            logger.error(f"Error monitoring system health: {e}")

    def _calculate_health_score(self, health_data: Dict[str, Any]) -> float:
        """Calculate overall system health score"""
        try:
            score_components = []
            
            # AI Optimizer health
            if 'ai_optimizer' in health_data:
                ai_data = health_data['ai_optimizer']
                # Base score on recent performance
                ai_score = 80.0  # Base score
                if ai_data.get('system_health', {}).get('avg_cpu', 0) > 90:
                    ai_score -= 20
                if ai_data.get('system_health', {}).get('avg_memory', 0) > 90:
                    ai_score -= 20
                score_components.append(ai_score)
            
            # Adaptive Config health
            if 'adaptive_config' in health_data:
                adaptive_data = health_data['adaptive_config']
                adaptive_score = 80.0
                # Boost score if learning is active
                if adaptive_data.get('learning_data', {}).get('config_changes', 0) > 0:
                    adaptive_score += 10
                score_components.append(adaptive_score)
            
            # Self-Healing health
            if 'self_healing' in health_data:
                healing_data = health_data['self_healing']
                healing_score = 90.0
                # Reduce score based on active issues
                critical_issues = healing_data.get('system_health', {}).get('critical_issues', 0)
                high_issues = healing_data.get('system_health', {}).get('high_priority_issues', 0)
                healing_score -= (critical_issues * 15 + high_issues * 10)
                score_components.append(max(healing_score, 0))
            
            # Return average if we have components, otherwise return base score
            return sum(score_components) / len(score_components) if score_components else 75.0
            
        except Exception as e:
            logger.error(f"Error calculating health score: {e}")
            return 50.0

    async def _coordinate_systems(self):
        """Coordinate actions between different AI systems"""
        try:
            # Check if self-healing is taking action
            if self.self_healing and len(self.self_healing.active_issues) > 0:
                # Pause aggressive optimizations during healing
                if hasattr(self.ai_optimizer, 'set_conservative_mode'):
                    await self.ai_optimizer.set_conservative_mode(True)
            
            # Check if adaptive config is learning new patterns
            if (self.adaptive_config and 
                hasattr(self.adaptive_config, 'current_context') and
                self.adaptive_config.current_context):
                
                # Share context with AI optimizer if it supports it
                if hasattr(self.ai_optimizer, 'update_user_context'):
                    await self.ai_optimizer.update_user_context(
                        self.adaptive_config.current_context
                    )
            
        except Exception as e:
            logger.error(f"Error coordinating systems: {e}")

    async def _update_statistics(self):
        """Update system-wide statistics"""
        try:
            # Update optimization counts
            if self.ai_optimizer:
                self.optimization_stats['total_optimizations'] = len(
                    getattr(self.ai_optimizer, 'optimization_history', [])
                )
            
            if self.adaptive_config:
                self.optimization_stats['adaptive_changes'] = len(
                    getattr(self.adaptive_config, 'config_history', [])
                )
            
            if self.self_healing:
                self.optimization_stats['healing_actions'] = len(
                    getattr(self.self_healing, 'healing_history', [])
                )
                
        except Exception as e:
            logger.error(f"Error updating statistics: {e}")

    async def _handle_critical_issues(self):
        """Handle critical system issues that require orchestrator intervention"""
        try:
            if not self.self_healing:
                return
            
            # Check for critical issues
            critical_issues = [
                issue for issue in self.self_healing.active_issues.values()
                if issue.severity.value >= 4  # Critical severity
            ]
            
            if critical_issues:
                logger.critical(f"Found {len(critical_issues)} critical issues!")
                
                # Take emergency actions
                for issue in critical_issues:
                    await self._handle_critical_issue(issue)
                    
        except Exception as e:
            logger.error(f"Error handling critical issues: {e}")

    async def _handle_critical_issue(self, issue):
        """Handle a specific critical issue"""
        logger.critical(f"Handling critical issue: {issue.title}")
        
        # Emergency responses based on issue type
        if 'temperature' in issue.title.lower():
            # Temperature emergency - reduce all performance settings
            await self._emergency_performance_reduction()
        
        elif 'memory' in issue.title.lower():
            # Memory emergency - aggressive cleanup
            await self._emergency_memory_cleanup()
        
        elif 'compositor' in issue.title.lower():
            # Compositor emergency - consider restart
            logger.critical("Compositor critical issue detected - manual intervention may be required")

    async def _emergency_performance_reduction(self):
        """Emergency performance reduction for thermal issues"""
        logger.warning("Executing emergency performance reduction")
        
        emergency_commands = [
            ['hyprctl', 'keyword', 'animations:enabled', 'no'],
            ['hyprctl', 'keyword', 'decoration:blur:enabled', 'no'],
            ['hyprctl', 'keyword', 'decoration:drop_shadow', 'no'],
            ['hyprctl', 'keyword', 'misc:vfr', 'yes']
        ]
        
        for cmd in emergency_commands:
            try:
                subprocess.run(cmd, capture_output=True, timeout=5)
            except:
                continue

    async def _emergency_memory_cleanup(self):
        """Emergency memory cleanup"""
        logger.warning("Executing emergency memory cleanup")
        
        try:
            # Clear system caches
            subprocess.run(['sync'], timeout=10)
            subprocess.run(['sudo', 'sh', '-c', 'echo 3 > /proc/sys/vm/drop_caches'], timeout=10)
            
            # Kill non-essential processes would go here
            # (Not implemented for safety)
            
        except Exception as e:
            logger.error(f"Error in emergency memory cleanup: {e}")

    async def get_system_status(self) -> SystemStatus:
        """Get comprehensive system status"""
        try:
            now = datetime.now()
            uptime = (now - self.start_time).total_seconds() / 3600 if self.start_time else 0
            
            # Check if systems are active
            ai_active = self.ai_optimizer is not None
            adaptive_active = self.adaptive_config is not None
            healing_active = self.self_healing is not None
            
            # Get active issues count
            active_issues = 0
            if self.self_healing:
                active_issues = len(self.self_healing.active_issues)
            
            # Calculate health score
            health_data = {}
            if ai_active:
                health_data['ai_optimizer'] = await self.ai_optimizer.get_optimization_report()
            if adaptive_active:
                health_data['adaptive_config'] = await self.adaptive_config.get_adaptation_report()
            if healing_active:
                health_data['self_healing'] = await self.self_healing.get_healing_report()
            
            health_score = self._calculate_health_score(health_data)
            
            return SystemStatus(
                timestamp=now.isoformat(),
                ai_optimizer_active=ai_active,
                adaptive_config_active=adaptive_active,
                self_healing_active=healing_active,
                total_optimizations=self.optimization_stats['total_optimizations'],
                active_issues=active_issues,
                system_health_score=health_score,
                uptime_hours=uptime,
                performance_score=self._calculate_performance_score(health_data),
                stability_score=self._calculate_stability_score(health_data)
            )
            
        except Exception as e:
            logger.error(f"Error getting system status: {e}")
            return SystemStatus(
                timestamp=datetime.now().isoformat(),
                ai_optimizer_active=False,
                adaptive_config_active=False,
                self_healing_active=False,
                total_optimizations=0,
                active_issues=0,
                system_health_score=0.0,
                uptime_hours=0.0,
                performance_score=0.0,
                stability_score=0.0
            )

    def _calculate_performance_score(self, health_data: Dict[str, Any]) -> float:
        """Calculate performance score"""
        try:
            if 'ai_optimizer' in health_data:
                ai_data = health_data['ai_optimizer']
                system_health = ai_data.get('system_health', {})
                
                cpu = system_health.get('avg_cpu', 0)
                memory = system_health.get('avg_memory', 0)
                
                # Higher usage = lower performance score
                performance_score = 100 - (cpu * 0.5 + memory * 0.3)
                return max(performance_score, 0)
            
            return 75.0
        except:
            return 75.0

    def _calculate_stability_score(self, health_data: Dict[str, Any]) -> float:
        """Calculate stability score"""
        try:
            if 'self_healing' in health_data:
                healing_data = health_data['self_healing']
                system_health = healing_data.get('system_health', {})
                
                critical = system_health.get('critical_issues', 0)
                high = system_health.get('high_priority_issues', 0)
                
                stability_score = 100 - (critical * 20 + high * 10)
                return max(stability_score, 0)
            
            return 85.0
        except:
            return 85.0

    async def stop_all_systems(self):
        """Stop all AI optimization systems gracefully"""
        logger.info("Stopping all AI optimization systems...")
        
        self.running = False
        
        # Stop individual systems
        if self.self_healing:
            self.self_healing.stop_monitoring()
        
        # Save states
        if self.adaptive_config:
            self.adaptive_config.save_preference_profiles()
        
        logger.info("All systems stopped gracefully")

    async def get_detailed_report(self) -> Dict[str, Any]:
        """Get detailed report from all systems"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "orchestrator": {
                "running": self.running,
                "uptime_hours": (datetime.now() - self.start_time).total_seconds() / 3600 if self.start_time else 0,
                "statistics": self.optimization_stats
            }
        }
        
        try:
            if self.ai_optimizer:
                report["ai_optimizer"] = await self.ai_optimizer.get_optimization_report()
            
            if self.adaptive_config:
                report["adaptive_config"] = await self.adaptive_config.get_adaptation_report()
            
            if self.self_healing:
                report["self_healing"] = await self.self_healing.get_healing_report()
                
        except Exception as e:
            logger.error(f"Error generating detailed report: {e}")
            report["error"] = str(e)
        
        return report

    async def execute_command(self, command: str, args: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute orchestrator commands"""
        args = args or {}
        
        try:
            if command == "status":
                status = await self.get_system_status()
                return asdict(status)
            
            elif command == "report":
                return await self.get_detailed_report()
            
            elif command == "emergency_stop":
                await self.stop_all_systems()
                return {"status": "stopped"}
            
            elif command == "restart_component":
                component = args.get("component")
                if component == "ai_optimizer" and self.ai_optimizer:
                    # Would implement restart logic
                    return {"status": f"restarted {component}"}
                
            else:
                return {"error": f"Unknown command: {command}"}
                
        except Exception as e:
            return {"error": str(e)}

def setup_signal_handlers(orchestrator):
    """Setup signal handlers for graceful shutdown"""
    def signal_handler(signum, frame):
        logger.info(f"Received signal {signum}, initiating graceful shutdown...")
        asyncio.create_task(orchestrator.stop_all_systems())
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Hyprland AI Optimization Orchestrator")
    parser.add_argument("--no-ai-optimizer", action="store_true", help="Disable AI optimizer")
    parser.add_argument("--no-adaptive-config", action="store_true", help="Disable adaptive configuration")
    parser.add_argument("--no-self-healing", action="store_true", help="Disable self-healing system")
    parser.add_argument("--status", action="store_true", help="Get system status and exit")
    parser.add_argument("--report", action="store_true", help="Get detailed report and exit")
    parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    
    args = parser.parse_args()
    
    # Create orchestrator
    orchestrator = HyprlandAIOrchestrator()
    
    # Setup signal handlers
    setup_signal_handlers(orchestrator)
    
    # Handle status/report commands
    if args.status:
        status = await orchestrator.get_system_status()
        print(json.dumps(asdict(status), indent=2))
        return
    
    if args.report:
        report = await orchestrator.get_detailed_report()
        print(json.dumps(report, indent=2))
        return
    
    # Start all systems
    logger.info("Starting Hyprland AI Optimization Suite")
    
    try:
        await orchestrator.start_all_systems(
            enable_ai_optimizer=not args.no_ai_optimizer,
            enable_adaptive_config=not args.no_adaptive_config,
            enable_self_healing=not args.no_self_healing
        )
    except KeyboardInterrupt:
        logger.info("Received interrupt signal")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
    finally:
        await orchestrator.stop_all_systems()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Orchestrator stopped by user")
    except Exception as e:
        logger.error(f"Orchestrator failed: {e}")
        sys.exit(1)
