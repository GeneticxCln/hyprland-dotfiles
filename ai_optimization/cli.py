#!/usr/bin/env python3
"""
Command Line Interface for Hyprland AI Optimization System
Provides easy management and monitoring capabilities
"""

import asyncio
import json
import argparse
import sys
from pathlib import Path
import subprocess
import time
from datetime import datetime
from typing import Dict, Any, Optional
import logging

# Suppress logging for CLI
logging.getLogger().setLevel(logging.CRITICAL)

class HyprlandAICLI:
    """Command-line interface for the AI optimization system"""
    
    def __init__(self):
        self.base_path = Path("/home/sasha/hyprland-project/ai_optimization")
        self.python_path = self.base_path / "venv" / "bin" / "python"
        self.orchestrator_path = self.base_path / "main_orchestrator.py"
        
    def run_command(self, args):
        """Run CLI command based on arguments"""
        if args.command == "status":
            return self._show_status(args.detailed)
        elif args.command == "start":
            return self._start_system()
        elif args.command == "stop":
            return self._stop_system()
        elif args.command == "restart":
            return self._restart_system()
        elif args.command == "logs":
            return self._show_logs(args.follow, args.lines)
        elif args.command == "report":
            return self._generate_report(args.output)
        elif args.command == "config":
            return self._manage_config(args.config_action, args.key, args.value)
        elif args.command == "health":
            return self._health_check()
        elif args.command == "optimize":
            return self._force_optimization()
        elif args.command == "stats":
            return self._show_statistics()
        else:
            print(f"Unknown command: {args.command}")
            return False

    def _show_status(self, detailed: bool = False) -> bool:
        """Show system status"""
        try:
            # Check if orchestrator is running
            result = subprocess.run(
                ['pgrep', '-f', 'main_orchestrator.py'],
                capture_output=True, text=True
            )
            
            is_running = result.returncode == 0
            
            # Check systemd service status
            service_result = subprocess.run(
                ['systemctl', '--user', 'is-active', 'hyprland-ai-optimization'],
                capture_output=True, text=True
            )
            
            service_status = service_result.stdout.strip()
            
            print("🤖 Hyprland AI Optimization System Status")
            print("=" * 50)
            print(f"Process Running: {'✅ Yes' if is_running else '❌ No'}")
            print(f"Service Status: {service_status}")
            
            if is_running and detailed:
                # Get detailed status from orchestrator
                status_result = subprocess.run([
                    str(self.python_path), str(self.orchestrator_path), '--status'
                ], capture_output=True, text=True, cwd=self.base_path)
                
                if status_result.returncode == 0:
                    try:
                        status_data = json.loads(status_result.stdout)
                        self._print_detailed_status(status_data)
                    except json.JSONDecodeError:
                        print("Could not parse detailed status")
            
            return True
            
        except Exception as e:
            print(f"Error checking status: {e}")
            return False

    def _print_detailed_status(self, status: Dict[str, Any]):
        """Print detailed status information"""
        print("\n📊 Detailed Status:")
        print("-" * 30)
        print(f"AI Optimizer: {'🟢 Active' if status.get('ai_optimizer_active') else '🔴 Inactive'}")
        print(f"Adaptive Config: {'🟢 Active' if status.get('adaptive_config_active') else '🔴 Inactive'}")
        print(f"Self-Healing: {'🟢 Active' if status.get('self_healing_active') else '🔴 Inactive'}")
        print(f"Total Optimizations: {status.get('total_optimizations', 0)}")
        print(f"Active Issues: {status.get('active_issues', 0)}")
        print(f"System Health: {status.get('system_health_score', 0):.1f}%")
        print(f"Performance Score: {status.get('performance_score', 0):.1f}%")
        print(f"Stability Score: {status.get('stability_score', 0):.1f}%")
        print(f"Uptime: {status.get('uptime_hours', 0):.1f} hours")

    def _start_system(self) -> bool:
        """Start the AI optimization system"""
        try:
            print("🚀 Starting Hyprland AI Optimization System...")
            
            # Start via systemd if available
            result = subprocess.run([
                'systemctl', '--user', 'start', 'hyprland-ai-optimization'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ System started via systemd")
                time.sleep(2)  # Give it a moment to start
                
                # Verify it's running
                if self._is_system_running():
                    print("🎉 System is now running!")
                    return True
                else:
                    print("⚠️ System may have failed to start properly")
                    return False
            else:
                # Fallback to direct execution
                print("Systemd service not available, starting directly...")
                process = subprocess.Popen([
                    str(self.python_path), str(self.orchestrator_path)
                ], cwd=self.base_path)
                
                print("✅ System started in background")
                print(f"Process ID: {process.pid}")
                return True
                
        except Exception as e:
            print(f"❌ Failed to start system: {e}")
            return False

    def _stop_system(self) -> bool:
        """Stop the AI optimization system"""
        try:
            print("🛑 Stopping Hyprland AI Optimization System...")
            
            # Stop via systemd
            result = subprocess.run([
                'systemctl', '--user', 'stop', 'hyprland-ai-optimization'
            ], capture_output=True)
            
            # Also kill any running processes
            subprocess.run(['pkill', '-f', 'main_orchestrator.py'], capture_output=True)
            
            time.sleep(2)
            
            if not self._is_system_running():
                print("✅ System stopped successfully")
                return True
            else:
                print("⚠️ System may still be running")
                return False
                
        except Exception as e:
            print(f"❌ Failed to stop system: {e}")
            return False

    def _restart_system(self) -> bool:
        """Restart the AI optimization system"""
        print("🔄 Restarting Hyprland AI Optimization System...")
        
        if self._stop_system():
            time.sleep(3)
            return self._start_system()
        return False

    def _show_logs(self, follow: bool = False, lines: int = 50) -> bool:
        """Show system logs"""
        try:
            log_file = self.base_path / "logs" / "orchestrator.log"
            
            if not log_file.exists():
                print("No log file found")
                return False
            
            if follow:
                print(f"📜 Following logs from {log_file} (Ctrl+C to stop)")
                subprocess.run(['tail', '-f', str(log_file)])
            else:
                print(f"📜 Last {lines} lines from {log_file}")
                subprocess.run(['tail', '-n', str(lines), str(log_file)])
            
            return True
            
        except KeyboardInterrupt:
            print("\nLog following stopped")
            return True
        except Exception as e:
            print(f"Error showing logs: {e}")
            return False

    def _generate_report(self, output_file: Optional[str] = None) -> bool:
        """Generate detailed system report"""
        try:
            print("📋 Generating system report...")
            
            result = subprocess.run([
                str(self.python_path), str(self.orchestrator_path), '--report'
            ], capture_output=True, text=True, cwd=self.base_path)
            
            if result.returncode != 0:
                print("❌ Failed to generate report")
                return False
            
            try:
                report_data = json.loads(result.stdout)
                
                if output_file:
                    with open(output_file, 'w') as f:
                        json.dump(report_data, f, indent=2)
                    print(f"✅ Report saved to {output_file}")
                else:
                    self._print_report_summary(report_data)
                
                return True
                
            except json.JSONDecodeError:
                print("❌ Could not parse report data")
                return False
                
        except Exception as e:
            print(f"Error generating report: {e}")
            return False

    def _print_report_summary(self, report: Dict[str, Any]):
        """Print a summary of the report"""
        print("\n📊 System Report Summary")
        print("=" * 40)
        
        if 'orchestrator' in report:
            orch = report['orchestrator']
            print(f"Orchestrator Uptime: {orch.get('uptime_hours', 0):.1f} hours")
            stats = orch.get('statistics', {})
            print(f"Total Optimizations: {stats.get('total_optimizations', 0)}")
            print(f"Adaptive Changes: {stats.get('adaptive_changes', 0)}")
            print(f"Healing Actions: {stats.get('healing_actions', 0)}")
        
        if 'ai_optimizer' in report:
            ai = report['ai_optimizer']
            health = ai.get('system_health', {})
            print(f"\n🤖 AI Optimizer:")
            print(f"  CPU Usage: {health.get('avg_cpu', 0):.1f}%")
            print(f"  Memory Usage: {health.get('avg_memory', 0):.1f}%")
            print(f"  Training Samples: {ai.get('ai_model_status', {}).get('training_samples', 0)}")
        
        if 'self_healing' in report:
            healing = report['self_healing']
            print(f"\n🏥 Self-Healing System:")
            print(f"  Active Issues: {healing.get('system_status', {}).get('active_issues', 0)}")
            print(f"  Resolved Issues: {healing.get('system_status', {}).get('resolved_issues', 0)}")
            success_rate = healing.get('system_health', {}).get('auto_healing_success_rate', 0)
            print(f"  Success Rate: {success_rate:.1f}%")

    def _manage_config(self, action: str, key: str = None, value: str = None) -> bool:
        """Manage system configuration"""
        config_file = self.base_path / "config" / "settings.json"
        
        try:
            if action == "show":
                if config_file.exists():
                    with open(config_file) as f:
                        config = json.load(f)
                    print("⚙️ Current Configuration:")
                    print(json.dumps(config, indent=2))
                    return True
                else:
                    print("Configuration file not found")
                    return False
            
            elif action == "get" and key:
                if config_file.exists():
                    with open(config_file) as f:
                        config = json.load(f)
                    
                    # Navigate nested keys (e.g., "ai_optimizer.learning_rate")
                    current = config
                    for k in key.split('.'):
                        if k in current:
                            current = current[k]
                        else:
                            print(f"Key '{key}' not found")
                            return False
                    
                    print(f"{key} = {current}")
                    return True
                
            elif action == "set" and key and value:
                # Load existing config
                config = {}
                if config_file.exists():
                    with open(config_file) as f:
                        config = json.load(f)
                
                # Set the value
                keys = key.split('.')
                current = config
                for k in keys[:-1]:
                    if k not in current:
                        current[k] = {}
                    current = current[k]
                
                # Try to convert value to appropriate type
                try:
                    if value.lower() in ('true', 'false'):
                        current[keys[-1]] = value.lower() == 'true'
                    elif '.' in value:
                        current[keys[-1]] = float(value)
                    elif value.isdigit():
                        current[keys[-1]] = int(value)
                    else:
                        current[keys[-1]] = value
                except:
                    current[keys[-1]] = value
                
                # Save config
                with open(config_file, 'w') as f:
                    json.dump(config, f, indent=2)
                
                print(f"✅ Set {key} = {current[keys[-1]]}")
                print("ℹ️  Restart the system for changes to take effect")
                return True
            
            else:
                print("Invalid config action. Use: show, get <key>, set <key> <value>")
                return False
                
        except Exception as e:
            print(f"Error managing config: {e}")
            return False

    def _health_check(self) -> bool:
        """Perform system health check"""
        print("🏥 Performing Health Check...")
        print("=" * 30)
        
        checks_passed = 0
        total_checks = 0
        
        # Check if system is running
        total_checks += 1
        if self._is_system_running():
            print("✅ System Process: Running")
            checks_passed += 1
        else:
            print("❌ System Process: Not Running")
        
        # Check dependencies
        total_checks += 1
        if self.python_path.exists():
            print("✅ Python Environment: Available")
            checks_passed += 1
        else:
            print("❌ Python Environment: Missing")
        
        # Check configuration
        total_checks += 1
        config_file = self.base_path / "config" / "settings.json"
        if config_file.exists():
            print("✅ Configuration: Present")
            checks_passed += 1
        else:
            print("❌ Configuration: Missing")
        
        # Check log directory
        total_checks += 1
        log_dir = self.base_path / "logs"
        if log_dir.exists():
            print("✅ Log Directory: Available")
            checks_passed += 1
        else:
            print("❌ Log Directory: Missing")
        
        # Check Hyprland
        total_checks += 1
        if subprocess.run(['which', 'hyprctl'], capture_output=True).returncode == 0:
            print("✅ Hyprland: Available")
            checks_passed += 1
        else:
            print("❌ Hyprland: Not Found")
        
        print(f"\n📊 Health Score: {checks_passed}/{total_checks} ({(checks_passed/total_checks)*100:.0f}%)")
        
        if checks_passed == total_checks:
            print("🎉 System is healthy!")
        elif checks_passed >= total_checks * 0.8:
            print("⚠️ System has minor issues")
        else:
            print("❌ System has significant problems")
        
        return checks_passed >= total_checks * 0.8

    def _force_optimization(self) -> bool:
        """Force an immediate optimization cycle"""
        try:
            print("⚡ Triggering immediate optimization...")
            
            if not self._is_system_running():
                print("❌ System is not running")
                return False
            
            # This would require adding a trigger mechanism to the orchestrator
            # For now, just inform the user
            print("ℹ️  Manual optimization trigger not yet implemented")
            print("🔄 The system automatically optimizes based on conditions")
            
            return True
            
        except Exception as e:
            print(f"Error forcing optimization: {e}")
            return False

    def _show_statistics(self) -> bool:
        """Show system statistics"""
        try:
            print("📈 System Statistics")
            print("=" * 25)
            
            # Get runtime statistics
            log_file = self.base_path / "logs" / "orchestrator.log"
            if log_file.exists():
                # Simple log analysis
                with open(log_file) as f:
                    lines = f.readlines()
                
                optimization_count = len([l for l in lines if 'optimization' in l.lower()])
                error_count = len([l for l in lines if 'ERROR' in l])
                warning_count = len([l for l in lines if 'WARNING' in l])
                
                print(f"Log Entries: {len(lines)}")
                print(f"Optimization References: {optimization_count}")
                print(f"Errors: {error_count}")
                print(f"Warnings: {warning_count}")
            
            # Database statistics if available
            db_files = [
                self.base_path / "ai_optimization" / "models" / "optimization_history.json",
                self.base_path / "adaptive_data" / "adaptive_config.db",
                self.base_path / "healing_data" / "healing_system.db"
            ]
            
            for db_file in db_files:
                if db_file.exists():
                    size = db_file.stat().st_size / 1024  # KB
                    print(f"{db_file.name}: {size:.1f} KB")
            
            return True
            
        except Exception as e:
            print(f"Error showing statistics: {e}")
            return False

    def _is_system_running(self) -> bool:
        """Check if the system is running"""
        result = subprocess.run(
            ['pgrep', '-f', 'main_orchestrator.py'],
            capture_output=True
        )
        return result.returncode == 0

def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Hyprland AI Optimization System CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s status           # Show system status
  %(prog)s status --detailed # Show detailed status
  %(prog)s start            # Start the system
  %(prog)s stop             # Stop the system
  %(prog)s logs --follow    # Follow logs in real-time
  %(prog)s report --output report.json  # Save detailed report
  %(prog)s config show      # Show current configuration
  %(prog)s config set ai_optimizer.learning_rate 0.01  # Set config value
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Show system status')
    status_parser.add_argument('--detailed', '-d', action='store_true', 
                              help='Show detailed status information')
    
    # Start command
    subparsers.add_parser('start', help='Start the AI optimization system')
    
    # Stop command
    subparsers.add_parser('stop', help='Stop the AI optimization system')
    
    # Restart command
    subparsers.add_parser('restart', help='Restart the AI optimization system')
    
    # Logs command
    logs_parser = subparsers.add_parser('logs', help='Show system logs')
    logs_parser.add_argument('--follow', '-f', action='store_true', 
                            help='Follow logs in real-time')
    logs_parser.add_argument('--lines', '-n', type=int, default=50,
                            help='Number of lines to show (default: 50)')
    
    # Report command
    report_parser = subparsers.add_parser('report', help='Generate system report')
    report_parser.add_argument('--output', '-o', help='Output file for report')
    
    # Config command
    config_parser = subparsers.add_parser('config', help='Manage configuration')
    config_subparsers = config_parser.add_subparsers(dest='config_action')
    
    config_subparsers.add_parser('show', help='Show current configuration')
    
    get_parser = config_subparsers.add_parser('get', help='Get configuration value')
    get_parser.add_argument('key', help='Configuration key (e.g., ai_optimizer.learning_rate)')
    
    set_parser = config_subparsers.add_parser('set', help='Set configuration value')
    set_parser.add_argument('key', help='Configuration key')
    set_parser.add_argument('value', help='New value')
    
    # Health command
    subparsers.add_parser('health', help='Perform system health check')
    
    # Optimize command
    subparsers.add_parser('optimize', help='Force immediate optimization')
    
    # Stats command
    subparsers.add_parser('stats', help='Show system statistics')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    cli = HyprlandAICLI()
    
    try:
        success = cli.run_command(args)
        return 0 if success else 1
    except KeyboardInterrupt:
        print("\nOperation cancelled")
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
