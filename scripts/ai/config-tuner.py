#!/usr/bin/env python3
"""
AI-Enhanced Hyprland - Intelligent Configuration Tuner
Advanced AI-driven system for learning user preferences and optimizing configurations
Version: 2.0
"""

import os
import sys
import json
import time
import sqlite3
import subprocess
import threading
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Tuple, Any
import argparse
import logging

# Try to import advanced AI libraries
try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

try:
    from sklearn.cluster import KMeans
    from sklearn.preprocessing import StandardScaler
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False

@dataclass
class UserPattern:
    """Data class for user behavior patterns"""
    timestamp: float
    active_windows: List[str]
    workspace: int
    cpu_usage: float
    memory_usage: float
    gpu_usage: float
    time_of_day: int  # 0-23
    day_of_week: int  # 0-6
    session_duration: float
    interaction_frequency: float
    window_switches: int
    application_launches: List[str]

@dataclass
class ConfigOptimization:
    """Configuration optimization recommendation"""
    config_path: str
    parameter: str
    current_value: Any
    recommended_value: Any
    confidence: float
    reason: str
    performance_impact: str

class AIConfigTuner:
    """AI-powered configuration tuning system"""
    
    def __init__(self, config_dir: str = None):
        self.config_dir = Path(config_dir or f"{os.path.expanduser('~')}/.config/hypr")
        self.data_dir = self.config_dir / "ai-tuner"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Database for storing patterns
        self.db_path = self.data_dir / "user_patterns.db"
        self.log_file = self.data_dir / "tuner.log"
        
        # Configuration files to monitor and tune
        self.config_files = {
            "hyprland": self.config_dir / "hyprland.conf",
            "waybar": self.config_dir.parent / "waybar" / "config.jsonc",
            "dunst": self.config_dir.parent / "dunst" / "dunstrc",
            "kitty": self.config_dir.parent / "kitty" / "kitty.conf"
        }
        
        # Learning parameters
        self.learning_enabled = True
        self.min_patterns_for_optimization = 50
        self.confidence_threshold = 0.7
        self.optimization_cooldown = timedelta(hours=6)
        
        # Performance tracking
        self.performance_baseline = {}
        self.optimization_history = []
        
        # Setup logging
        self.setup_logging()
        
        # Initialize database
        self.init_database()
        
        self.logger.info("AI Configuration Tuner initialized")

    def setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('AIConfigTuner')

    def init_database(self):
        """Initialize SQLite database for pattern storage"""
        self.conn = sqlite3.connect(self.db_path)
        self.cursor = self.conn.cursor()
        
        # Create tables
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL,
                active_windows TEXT,
                workspace INTEGER,
                cpu_usage REAL,
                memory_usage REAL,
                gpu_usage REAL,
                time_of_day INTEGER,
                day_of_week INTEGER,
                session_duration REAL,
                interaction_frequency REAL,
                window_switches INTEGER,
                application_launches TEXT
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS config_optimizations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL,
                config_path TEXT,
                parameter TEXT,
                old_value TEXT,
                new_value TEXT,
                confidence REAL,
                reason TEXT,
                performance_impact TEXT,
                user_accepted BOOLEAN
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS performance_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL,
                config_hash TEXT,
                avg_response_time REAL,
                frame_rate REAL,
                memory_efficiency REAL,
                cpu_efficiency REAL,
                user_satisfaction REAL
            )
        ''')
        
        self.conn.commit()
        self.logger.info("Database initialized")

    def collect_user_pattern(self) -> Optional[UserPattern]:
        """Collect current user behavior pattern"""
        try:
            # Get active windows
            active_windows = self._get_active_windows()
            
            # Get current workspace
            workspace = self._get_current_workspace()
            
            # Get system metrics
            cpu_usage = self._get_cpu_usage()
            memory_usage = self._get_memory_usage()
            gpu_usage = self._get_gpu_usage()
            
            # Get temporal information
            now = datetime.now()
            time_of_day = now.hour
            day_of_week = now.weekday()
            
            # Get interaction metrics
            interaction_freq = self._calculate_interaction_frequency()
            window_switches = self._count_window_switches()
            app_launches = self._get_recent_app_launches()
            
            pattern = UserPattern(
                timestamp=time.time(),
                active_windows=active_windows,
                workspace=workspace,
                cpu_usage=cpu_usage,
                memory_usage=memory_usage,
                gpu_usage=gpu_usage,
                time_of_day=time_of_day,
                day_of_week=day_of_week,
                session_duration=self._get_session_duration(),
                interaction_frequency=interaction_freq,
                window_switches=window_switches,
                application_launches=app_launches
            )
            
            return pattern
            
        except Exception as e:
            self.logger.error(f"Error collecting user pattern: {e}")
            return None

    def store_pattern(self, pattern: UserPattern):
        """Store user pattern in database"""
        try:
            self.cursor.execute('''
                INSERT INTO user_patterns 
                (timestamp, active_windows, workspace, cpu_usage, memory_usage, 
                 gpu_usage, time_of_day, day_of_week, session_duration, 
                 interaction_frequency, window_switches, application_launches)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                pattern.timestamp,
                json.dumps(pattern.active_windows),
                pattern.workspace,
                pattern.cpu_usage,
                pattern.memory_usage,
                pattern.gpu_usage,
                pattern.time_of_day,
                pattern.day_of_week,
                pattern.session_duration,
                pattern.interaction_frequency,
                pattern.window_switches,
                json.dumps(pattern.application_launches)
            ))
            self.conn.commit()
            
        except Exception as e:
            self.logger.error(f"Error storing pattern: {e}")

    def analyze_patterns(self) -> List[Dict]:
        """Analyze stored patterns to identify optimization opportunities"""
        try:
            # Get all patterns
            self.cursor.execute('SELECT * FROM user_patterns ORDER BY timestamp DESC LIMIT 1000')
            rows = self.cursor.fetchall()
            
            if len(rows) < self.min_patterns_for_optimization:
                self.logger.info(f"Not enough patterns for analysis: {len(rows)}/{self.min_patterns_for_optimization}")
                return []
            
            patterns = []
            for row in rows:
                patterns.append({
                    'timestamp': row[1],
                    'active_windows': json.loads(row[2]),
                    'workspace': row[3],
                    'cpu_usage': row[4],
                    'memory_usage': row[5],
                    'gpu_usage': row[6],
                    'time_of_day': row[7],
                    'day_of_week': row[8],
                    'session_duration': row[9],
                    'interaction_frequency': row[10],
                    'window_switches': row[11],
                    'application_launches': json.loads(row[12])
                })
            
            # Analyze patterns
            insights = []
            
            # Time-based patterns
            insights.extend(self._analyze_temporal_patterns(patterns))
            
            # Workspace usage patterns
            insights.extend(self._analyze_workspace_patterns(patterns))
            
            # Performance patterns
            insights.extend(self._analyze_performance_patterns(patterns))
            
            # Application usage patterns
            insights.extend(self._analyze_application_patterns(patterns))
            
            return insights
            
        except Exception as e:
            self.logger.error(f"Error analyzing patterns: {e}")
            return []

    def _analyze_temporal_patterns(self, patterns: List[Dict]) -> List[Dict]:
        """Analyze time-based usage patterns"""
        insights = []
        
        # Group by time of day
        time_usage = {}
        for pattern in patterns:
            hour = pattern['time_of_day']
            if hour not in time_usage:
                time_usage[hour] = {
                    'count': 0,
                    'avg_cpu': 0,
                    'avg_memory': 0,
                    'avg_interaction': 0
                }
            
            time_usage[hour]['count'] += 1
            time_usage[hour]['avg_cpu'] += pattern['cpu_usage']
            time_usage[hour]['avg_memory'] += pattern['memory_usage']
            time_usage[hour]['avg_interaction'] += pattern['interaction_frequency']
        
        # Calculate averages
        for hour in time_usage:
            count = time_usage[hour]['count']
            time_usage[hour]['avg_cpu'] /= count
            time_usage[hour]['avg_memory'] /= count
            time_usage[hour]['avg_interaction'] /= count
        
        # Identify peak usage hours
        peak_hours = sorted(time_usage.keys(), key=lambda h: time_usage[h]['avg_interaction'], reverse=True)[:3]
        
        if peak_hours:
            insights.append({
                'type': 'temporal_peak',
                'data': {
                    'peak_hours': peak_hours,
                    'usage_data': time_usage
                },
                'confidence': 0.8,
                'description': f"Peak usage hours identified: {peak_hours}"
            })
        
        return insights

    def _analyze_workspace_patterns(self, patterns: List[Dict]) -> List[Dict]:
        """Analyze workspace usage patterns"""
        insights = []
        
        workspace_usage = {}
        for pattern in patterns:
            ws = pattern['workspace']
            if ws not in workspace_usage:
                workspace_usage[ws] = {
                    'count': 0,
                    'apps': {},
                    'avg_switches': 0
                }
            
            workspace_usage[ws]['count'] += 1
            workspace_usage[ws]['avg_switches'] += pattern['window_switches']
            
            for app in pattern['active_windows']:
                if app not in workspace_usage[ws]['apps']:
                    workspace_usage[ws]['apps'][app] = 0
                workspace_usage[ws]['apps'][app] += 1
        
        # Calculate averages and identify patterns
        for ws in workspace_usage:
            workspace_usage[ws]['avg_switches'] /= workspace_usage[ws]['count']
        
        # Find most used workspaces
        most_used = sorted(workspace_usage.keys(), key=lambda w: workspace_usage[w]['count'], reverse=True)
        
        if most_used:
            insights.append({
                'type': 'workspace_usage',
                'data': {
                    'most_used_workspaces': most_used[:5],
                    'usage_data': workspace_usage
                },
                'confidence': 0.75,
                'description': f"Primary workspaces: {most_used[:3]}"
            })
        
        return insights

    def _analyze_performance_patterns(self, patterns: List[Dict]) -> List[Dict]:
        """Analyze system performance patterns"""
        insights = []
        
        # High resource usage patterns
        high_cpu_patterns = [p for p in patterns if p['cpu_usage'] > 70]
        high_memory_patterns = [p for p in patterns if p['memory_usage'] > 80]
        
        if high_cpu_patterns:
            common_apps = self._find_common_apps(high_cpu_patterns)
            insights.append({
                'type': 'high_cpu_pattern',
                'data': {
                    'frequency': len(high_cpu_patterns),
                    'common_apps': common_apps,
                    'avg_cpu': sum(p['cpu_usage'] for p in high_cpu_patterns) / len(high_cpu_patterns)
                },
                'confidence': 0.7,
                'description': f"High CPU usage patterns detected with apps: {common_apps[:3]}"
            })
        
        if high_memory_patterns:
            common_apps = self._find_common_apps(high_memory_patterns)
            insights.append({
                'type': 'high_memory_pattern',
                'data': {
                    'frequency': len(high_memory_patterns),
                    'common_apps': common_apps,
                    'avg_memory': sum(p['memory_usage'] for p in high_memory_patterns) / len(high_memory_patterns)
                },
                'confidence': 0.7,
                'description': f"High memory usage patterns detected with apps: {common_apps[:3]}"
            })
        
        return insights

    def _analyze_application_patterns(self, patterns: List[Dict]) -> List[Dict]:
        """Analyze application usage patterns"""
        insights = []
        
        app_usage = {}
        for pattern in patterns:
            for app in pattern['active_windows']:
                if app not in app_usage:
                    app_usage[app] = {
                        'count': 0,
                        'workspaces': set(),
                        'times': []
                    }
                app_usage[app]['count'] += 1
                app_usage[app]['workspaces'].add(pattern['workspace'])
                app_usage[app]['times'].append(pattern['time_of_day'])
        
        # Find most used applications
        most_used_apps = sorted(app_usage.keys(), key=lambda a: app_usage[a]['count'], reverse=True)[:10]
        
        if most_used_apps:
            insights.append({
                'type': 'application_usage',
                'data': {
                    'most_used_apps': most_used_apps,
                    'app_data': {app: {
                        'count': app_usage[app]['count'],
                        'workspaces': list(app_usage[app]['workspaces']),
                        'avg_hour': sum(app_usage[app]['times']) / len(app_usage[app]['times'])
                    } for app in most_used_apps}
                },
                'confidence': 0.8,
                'description': f"Primary applications: {most_used_apps[:5]}"
            })
        
        return insights

    def generate_optimizations(self, insights: List[Dict]) -> List[ConfigOptimization]:
        """Generate configuration optimizations based on insights"""
        optimizations = []
        
        for insight in insights:
            if insight['confidence'] < self.confidence_threshold:
                continue
            
            if insight['type'] == 'temporal_peak':
                optimizations.extend(self._generate_temporal_optimizations(insight))
            elif insight['type'] == 'workspace_usage':
                optimizations.extend(self._generate_workspace_optimizations(insight))
            elif insight['type'] == 'high_cpu_pattern':
                optimizations.extend(self._generate_performance_optimizations(insight))
            elif insight['type'] == 'application_usage':
                optimizations.extend(self._generate_app_optimizations(insight))
        
        return optimizations

    def _generate_temporal_optimizations(self, insight: Dict) -> List[ConfigOptimization]:
        """Generate time-based optimizations"""
        optimizations = []
        
        peak_hours = insight['data']['peak_hours']
        
        # Suggest different animation speeds for different times
        if len(peak_hours) > 0:
            optimizations.append(ConfigOptimization(
                config_path="hyprland.conf",
                parameter="animations:speed",
                current_value="1.0",
                recommended_value="0.8" if any(h < 9 or h > 17 for h in peak_hours) else "1.2",
                confidence=insight['confidence'],
                reason=f"Optimized for peak usage hours: {peak_hours}",
                performance_impact="low"
            ))
        
        return optimizations

    def _generate_workspace_optimizations(self, insight: Dict) -> List[ConfigOptimization]:
        """Generate workspace-based optimizations"""
        optimizations = []
        
        most_used = insight['data']['most_used_workspaces']
        
        # Suggest workspace-specific optimizations
        if len(most_used) >= 2:
            optimizations.append(ConfigOptimization(
                config_path="hyprland.conf",
                parameter="workspace",
                current_value="default",
                recommended_value=f"auto_back_and_forth=true",
                confidence=insight['confidence'],
                reason=f"Optimize for {len(most_used)} active workspaces",
                performance_impact="low"
            ))
        
        return optimizations

    def _generate_performance_optimizations(self, insight: Dict) -> List[ConfigOptimization]:
        """Generate performance-based optimizations"""
        optimizations = []
        
        if insight['type'] == 'high_cpu_pattern':
            common_apps = insight['data']['common_apps']
            
            # Suggest reduced animations for high CPU scenarios
            optimizations.append(ConfigOptimization(
                config_path="hyprland.conf",
                parameter="animations:enabled",
                current_value="true",
                recommended_value="conditional",
                confidence=insight['confidence'],
                reason=f"High CPU usage detected with: {', '.join(common_apps[:3])}",
                performance_impact="medium"
            ))
        
        return optimizations

    def _generate_app_optimizations(self, insight: Dict) -> List[ConfigOptimization]:
        """Generate application-specific optimizations"""
        optimizations = []
        
        most_used = insight['data']['most_used_apps']
        app_data = insight['data']['app_data']
        
        # Generate window rules for frequently used apps
        for app in most_used[:3]:
            if app_data[app]['count'] > 20:  # Frequently used threshold
                preferred_ws = app_data[app]['workspaces'][0] if app_data[app]['workspaces'] else 1
                
                optimizations.append(ConfigOptimization(
                    config_path="hyprland.conf",
                    parameter="windowrule",
                    current_value="default",
                    recommended_value=f"workspace {preferred_ws}, ^({app})$",
                    confidence=insight['confidence'] * 0.8,
                    reason=f"Auto-assign {app} to workspace {preferred_ws} (used {app_data[app]['count']} times)",
                    performance_impact="low"
                ))
        
        return optimizations

    def apply_optimization(self, optimization: ConfigOptimization, auto_apply: bool = False) -> bool:
        """Apply a configuration optimization"""
        try:
            if not auto_apply:
                # Ask user for confirmation
                response = input(f"\nApply optimization to {optimization.parameter}?\n"
                               f"Current: {optimization.current_value}\n"
                               f"Recommended: {optimization.recommended_value}\n"
                               f"Reason: {optimization.reason}\n"
                               f"Confidence: {optimization.confidence:.2f}\n"
                               f"Apply? (y/n): ")
                
                if response.lower() != 'y':
                    self.logger.info("Optimization declined by user")
                    return False
            
            # Backup current configuration
            config_path = self.config_dir / optimization.config_path
            backup_path = config_path.with_suffix(f".bak.{int(time.time())}")
            
            if config_path.exists():
                subprocess.run(['cp', str(config_path), str(backup_path)], check=True)
                self.logger.info(f"Created backup: {backup_path}")
            
            # Apply the optimization
            success = self._modify_config_file(optimization)
            
            if success:
                # Store optimization in database
                self.cursor.execute('''
                    INSERT INTO config_optimizations 
                    (timestamp, config_path, parameter, old_value, new_value, 
                     confidence, reason, performance_impact, user_accepted)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    time.time(),
                    optimization.config_path,
                    optimization.parameter,
                    str(optimization.current_value),
                    str(optimization.recommended_value),
                    optimization.confidence,
                    optimization.reason,
                    optimization.performance_impact,
                    True
                ))
                self.conn.commit()
                
                self.logger.info(f"Applied optimization: {optimization.parameter}")
                return True
            else:
                self.logger.error("Failed to apply optimization")
                return False
                
        except Exception as e:
            self.logger.error(f"Error applying optimization: {e}")
            return False

    def _modify_config_file(self, optimization: ConfigOptimization) -> bool:
        """Modify configuration file with the optimization"""
        config_path = self.config_dir / optimization.config_path
        
        if not config_path.exists():
            self.logger.warning(f"Config file not found: {config_path}")
            return False
        
        try:
            with open(config_path, 'r') as f:
                content = f.read()
            
            # Simple parameter replacement (could be enhanced for more complex configs)
            if optimization.parameter in content:
                # Replace existing parameter
                import re
                pattern = rf'^{optimization.parameter}\s*=.*$'
                replacement = f'{optimization.parameter} = {optimization.recommended_value}'
                content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
            else:
                # Add new parameter
                content += f'\n{optimization.parameter} = {optimization.recommended_value}\n'
            
            with open(config_path, 'w') as f:
                f.write(content)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error modifying config file: {e}")
            return False

    def _get_active_windows(self) -> List[str]:
        """Get list of currently active windows"""
        try:
            result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
            if result.returncode == 0:
                clients = json.loads(result.stdout)
                return [client.get('class', 'unknown') for client in clients if client.get('mapped', False)]
            return []
        except:
            return []

    def _get_current_workspace(self) -> int:
        """Get current workspace number"""
        try:
            result = subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True)
            if result.returncode == 0:
                workspace = json.loads(result.stdout)
                return workspace.get('id', 1)
            return 1
        except:
            return 1

    def _get_cpu_usage(self) -> float:
        """Get current CPU usage percentage"""
        try:
            result = subprocess.run(['top', '-bn1'], capture_output=True, text=True)
            for line in result.stdout.split('\n'):
                if 'Cpu(s):' in line:
                    # Extract CPU usage percentage
                    import re
                    match = re.search(r'(\d+\.?\d*)%us', line)
                    if match:
                        return float(match.group(1))
            return 0.0
        except:
            return 0.0

    def _get_memory_usage(self) -> float:
        """Get current memory usage percentage"""
        try:
            result = subprocess.run(['free'], capture_output=True, text=True)
            lines = result.stdout.split('\n')
            mem_line = lines[1]  # Second line contains memory info
            parts = mem_line.split()
            total = int(parts[1])
            used = int(parts[2])
            return (used / total) * 100
        except:
            return 0.0

    def _get_gpu_usage(self) -> float:
        """Get current GPU usage percentage"""
        try:
            result = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu', '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return float(result.stdout.strip())
            return 0.0
        except:
            return 0.0

    def _get_session_duration(self) -> float:
        """Get current session duration in minutes"""
        try:
            result = subprocess.run(['uptime', '-s'], capture_output=True, text=True)
            if result.returncode == 0:
                start_time = datetime.strptime(result.stdout.strip(), '%Y-%m-%d %H:%M:%S')
                duration = datetime.now() - start_time
                return duration.total_seconds() / 60
            return 0.0
        except:
            return 0.0

    def _calculate_interaction_frequency(self) -> float:
        """Calculate user interaction frequency (simplified)"""
        # This is a simplified implementation
        # In practice, you'd monitor keyboard/mouse events
        return 1.0  # Placeholder

    def _count_window_switches(self) -> int:
        """Count window switches in recent period (simplified)"""
        # This would require more sophisticated monitoring
        return 0  # Placeholder

    def _get_recent_app_launches(self) -> List[str]:
        """Get recently launched applications (simplified)"""
        # This would require monitoring process creation
        return []  # Placeholder

    def _find_common_apps(self, patterns: List[Dict]) -> List[str]:
        """Find common applications in a set of patterns"""
        app_counts = {}
        for pattern in patterns:
            for app in pattern['active_windows']:
                app_counts[app] = app_counts.get(app, 0) + 1
        
        return sorted(app_counts.keys(), key=lambda a: app_counts[a], reverse=True)

    def start_monitoring(self, interval: int = 60):
        """Start continuous monitoring and learning"""
        self.logger.info(f"Starting continuous monitoring with {interval}s interval")
        
        def monitor_loop():
            while self.learning_enabled:
                try:
                    pattern = self.collect_user_pattern()
                    if pattern:
                        self.store_pattern(pattern)
                        
                        # Periodically analyze and optimize
                        if int(time.time()) % (interval * 10) == 0:  # Every 10 minutes
                            self.run_optimization_cycle()
                    
                    time.sleep(interval)
                    
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    self.logger.error(f"Error in monitoring loop: {e}")
                    time.sleep(interval)
        
        # Start monitoring in background thread
        monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
        monitor_thread.start()
        
        return monitor_thread

    def run_optimization_cycle(self):
        """Run a complete optimization cycle"""
        self.logger.info("Running optimization cycle...")
        
        # Analyze patterns
        insights = self.analyze_patterns()
        self.logger.info(f"Generated {len(insights)} insights")
        
        # Generate optimizations
        optimizations = self.generate_optimizations(insights)
        self.logger.info(f"Generated {len(optimizations)} optimization recommendations")
        
        # Apply high-confidence optimizations automatically
        auto_applied = 0
        for opt in optimizations:
            if opt.confidence > 0.9 and opt.performance_impact == "low":
                if self.apply_optimization(opt, auto_apply=True):
                    auto_applied += 1
        
        if auto_applied > 0:
            self.logger.info(f"Auto-applied {auto_applied} high-confidence optimizations")
        
        # Present other optimizations to user
        manual_opts = [opt for opt in optimizations if opt.confidence <= 0.9 or opt.performance_impact != "low"]
        if manual_opts:
            self.logger.info(f"{len(manual_opts)} optimizations require manual review")
            self.present_optimizations(manual_opts)

    def present_optimizations(self, optimizations: List[ConfigOptimization]):
        """Present optimization recommendations to user"""
        print("\n" + "="*80)
        print("🤖 AI Configuration Tuner - Optimization Recommendations")
        print("="*80)
        
        for i, opt in enumerate(optimizations, 1):
            print(f"\n{i}. {opt.parameter} ({opt.config_path})")
            print(f"   Current: {opt.current_value}")
            print(f"   Recommended: {opt.recommended_value}")
            print(f"   Confidence: {opt.confidence:.2f}")
            print(f"   Impact: {opt.performance_impact}")
            print(f"   Reason: {opt.reason}")
        
        print(f"\nTo apply optimizations, use: python3 {__file__} apply")

    def generate_report(self) -> Dict:
        """Generate comprehensive analysis report"""
        # Get recent patterns
        self.cursor.execute('SELECT COUNT(*) FROM user_patterns')
        total_patterns = self.cursor.fetchone()[0]
        
        # Get optimization history
        self.cursor.execute('SELECT COUNT(*) FROM config_optimizations WHERE user_accepted = 1')
        applied_optimizations = self.cursor.fetchone()[0]
        
        # Analyze current patterns
        insights = self.analyze_patterns()
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'learning_status': {
                'patterns_collected': total_patterns,
                'optimizations_applied': applied_optimizations,
                'learning_enabled': self.learning_enabled
            },
            'current_insights': insights,
            'recommendations': len(self.generate_optimizations(insights)),
            'config_files_monitored': list(self.config_files.keys()),
            'system_info': {
                'config_dir': str(self.config_dir),
                'has_numpy': HAS_NUMPY,
                'has_sklearn': HAS_SKLEARN
            }
        }
        
        return report

def main():
    parser = argparse.ArgumentParser(description='AI-Enhanced Hyprland Configuration Tuner')
    parser.add_argument('action', nargs='?', default='status', 
                       choices=['status', 'start', 'stop', 'analyze', 'report', 'apply', 'collect'],
                       help='Action to perform')
    parser.add_argument('--config-dir', help='Configuration directory path')
    parser.add_argument('--interval', type=int, default=60, help='Monitoring interval in seconds')
    parser.add_argument('--auto-apply', action='store_true', help='Automatically apply high-confidence optimizations')
    
    args = parser.parse_args()
    
    tuner = AIConfigTuner(args.config_dir)
    
    if args.action == 'start':
        print("🤖 Starting AI Configuration Tuner...")
        print(f"Monitoring interval: {args.interval}s")
        print("Press Ctrl+C to stop")
        
        monitor_thread = tuner.start_monitoring(args.interval)
        
        try:
            monitor_thread.join()
        except KeyboardInterrupt:
            tuner.learning_enabled = False
            print("\n🛑 Monitoring stopped")
    
    elif args.action == 'collect':
        print("📊 Collecting current user pattern...")
        pattern = tuner.collect_user_pattern()
        if pattern:
            tuner.store_pattern(pattern)
            print("✅ Pattern collected and stored")
        else:
            print("❌ Failed to collect pattern")
    
    elif args.action == 'analyze':
        print("🔍 Analyzing user patterns...")
        insights = tuner.analyze_patterns()
        
        if insights:
            print(f"\n📈 Generated {len(insights)} insights:")
            for insight in insights:
                print(f"  • {insight['description']} (confidence: {insight['confidence']:.2f})")
            
            optimizations = tuner.generate_optimizations(insights)
            if optimizations:
                print(f"\n💡 Generated {len(optimizations)} optimization recommendations")
                tuner.present_optimizations(optimizations)
        else:
            print("ℹ️  No patterns available for analysis")
    
    elif args.action == 'apply':
        print("🔧 Applying optimizations...")
        insights = tuner.analyze_patterns()
        optimizations = tuner.generate_optimizations(insights)
        
        applied = 0
        for opt in optimizations:
            if tuner.apply_optimization(opt, args.auto_apply):
                applied += 1
        
        print(f"✅ Applied {applied}/{len(optimizations)} optimizations")
    
    elif args.action == 'report':
        print("📋 Generating comprehensive report...")
        report = tuner.generate_report()
        
        report_file = tuner.data_dir / f"report_{int(time.time())}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"📄 Report saved to: {report_file}")
        print(json.dumps(report, indent=2))
    
    elif args.action == 'status':
        print("📊 AI Configuration Tuner Status")
        print("=" * 40)
        
        # Check if monitoring is active
        tuner.cursor.execute('SELECT COUNT(*) FROM user_patterns')
        pattern_count = tuner.cursor.fetchone()[0]
        
        tuner.cursor.execute('SELECT COUNT(*) FROM config_optimizations')
        opt_count = tuner.cursor.fetchone()[0]
        
        print(f"Patterns collected: {pattern_count}")
        print(f"Optimizations applied: {opt_count}")
        print(f"Learning enabled: {tuner.learning_enabled}")
        print(f"Configuration directory: {tuner.config_dir}")
        
        if pattern_count >= tuner.min_patterns_for_optimization:
            print("✅ Ready for optimization")
        else:
            needed = tuner.min_patterns_for_optimization - pattern_count
            print(f"ℹ️  Need {needed} more patterns for optimization")

if __name__ == '__main__':
    main()
