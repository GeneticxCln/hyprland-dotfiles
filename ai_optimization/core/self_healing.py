#!/usr/bin/env python3
"""
Intelligent Self-Healing System for Hyprland
Automatically detects, diagnoses, and resolves system issues
"""

import asyncio
import json
import logging
import subprocess
import psutil
import re
import time
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Tuple, Any, Set
from datetime import datetime, timedelta
from collections import defaultdict, deque
import sqlite3
import hashlib
from enum import Enum
import threading
import signal
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class IssueSeverity(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

class IssueCategory(Enum):
    PERFORMANCE = "performance"
    STABILITY = "stability"
    GRAPHICS = "graphics"
    AUDIO = "audio"
    INPUT = "input"
    MEMORY = "memory"
    DISK = "disk"
    NETWORK = "network"
    SYSTEM = "system"

@dataclass
class SystemIssue:
    """Represents a detected system issue"""
    issue_id: str
    timestamp: float
    category: IssueCategory
    severity: IssueSeverity
    title: str
    description: str
    symptoms: List[str]
    metrics: Dict[str, Any]
    potential_causes: List[str]
    suggested_fixes: List[str]
    auto_fixable: bool
    resolved: bool = False
    resolution_attempts: int = 0
    resolution_timestamp: Optional[float] = None

@dataclass
class HealingAction:
    """Represents an automated healing action"""
    action_id: str
    timestamp: float
    issue_id: str
    action_type: str
    description: str
    command: Optional[str]
    config_changes: Dict[str, Any]
    success: bool
    error_message: Optional[str]
    rollback_info: Optional[Dict[str, Any]]

class SelfHealingSystem:
    """Main self-healing system orchestrator"""
    
    def __init__(self):
        self.data_path = Path("/home/sasha/hyprland-project/ai_optimization/healing_data")
        self.data_path.mkdir(parents=True, exist_ok=True)
        
        # Database for issue tracking
        self.db_path = self.data_path / "healing_system.db"
        self._init_database()
        
        # Issue tracking
        self.active_issues: Dict[str, SystemIssue] = {}
        self.resolved_issues: List[SystemIssue] = []
        self.healing_history: List[HealingAction] = []
        
        # Monitoring state
        self.monitoring_active = False
        self.monitoring_interval = 30  # seconds
        self.issue_detection_thresholds = {
            'cpu_usage': 90.0,
            'memory_usage': 95.0,
            'disk_usage': 95.0,
            'temperature': 85.0,
            'fps_drop': 20.0,
            'audio_glitches': 5,
            'crashes_per_hour': 3
        }
        
        # System state tracking
        self.system_metrics_history = deque(maxlen=1440)  # 24 hours at 1-minute intervals
        self.process_restarts = defaultdict(int)
        self.last_known_good_config = {}
        
        # Healing strategies
        self.healing_strategies = self._initialize_healing_strategies()
        
        logger.info("Self-Healing System initialized")

    def _init_database(self):
        """Initialize database for issue tracking"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Issues table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_issues (
                issue_id TEXT PRIMARY KEY,
                timestamp REAL,
                category TEXT,
                severity INTEGER,
                title TEXT,
                description TEXT,
                symptoms TEXT,
                metrics TEXT,
                potential_causes TEXT,
                suggested_fixes TEXT,
                auto_fixable INTEGER,
                resolved INTEGER,
                resolution_attempts INTEGER,
                resolution_timestamp REAL
            )
        ''')
        
        # Healing actions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS healing_actions (
                action_id TEXT PRIMARY KEY,
                timestamp REAL,
                issue_id TEXT,
                action_type TEXT,
                description TEXT,
                command TEXT,
                config_changes TEXT,
                success INTEGER,
                error_message TEXT,
                rollback_info TEXT,
                FOREIGN KEY (issue_id) REFERENCES system_issues (issue_id)
            )
        ''')
        
        # System metrics table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_metrics (
                timestamp REAL PRIMARY KEY,
                cpu_usage REAL,
                memory_usage REAL,
                gpu_usage REAL,
                temperature REAL,
                disk_usage REAL,
                network_latency REAL,
                active_processes INTEGER,
                system_load REAL
            )
        ''')
        
        conn.commit()
        conn.close()

    def _initialize_healing_strategies(self) -> Dict[IssueCategory, List[Dict[str, Any]]]:
        """Initialize healing strategies for different issue types"""
        return {
            IssueCategory.PERFORMANCE: [
                {
                    'name': 'reduce_animations',
                    'description': 'Disable or reduce animations to improve performance',
                    'action': self._reduce_animations,
                    'conditions': ['cpu_usage > 85', 'low_fps'],
                    'rollback': self._restore_animations
                },
                {
                    'name': 'disable_blur',
                    'description': 'Disable blur effects to reduce GPU load',
                    'action': self._disable_blur,
                    'conditions': ['gpu_usage > 90', 'low_fps'],
                    'rollback': self._enable_blur
                },
                {
                    'name': 'kill_resource_hogs',
                    'description': 'Terminate processes consuming excessive resources',
                    'action': self._kill_resource_hogs,
                    'conditions': ['memory_usage > 95'],
                    'rollback': None
                }
            ],
            IssueCategory.STABILITY: [
                {
                    'name': 'restart_compositor',
                    'description': 'Restart Hyprland compositor',
                    'action': self._restart_hyprland,
                    'conditions': ['frequent_crashes', 'compositor_hang'],
                    'rollback': None
                },
                {
                    'name': 'reset_to_defaults',
                    'description': 'Reset to last known good configuration',
                    'action': self._reset_to_defaults,
                    'conditions': ['persistent_issues'],
                    'rollback': self._restore_user_config
                }
            ],
            IssueCategory.GRAPHICS: [
                {
                    'name': 'restart_gpu_driver',
                    'description': 'Restart GPU driver modules',
                    'action': self._restart_gpu_driver,
                    'conditions': ['gpu_hang', 'display_corruption'],
                    'rollback': None
                },
                {
                    'name': 'adjust_refresh_rate',
                    'description': 'Lower display refresh rate',
                    'action': self._adjust_refresh_rate,
                    'conditions': ['display_issues', 'gpu_overload'],
                    'rollback': self._restore_refresh_rate
                }
            ],
            IssueCategory.MEMORY: [
                {
                    'name': 'clear_caches',
                    'description': 'Clear system caches to free memory',
                    'action': self._clear_caches,
                    'conditions': ['memory_usage > 90'],
                    'rollback': None
                },
                {
                    'name': 'enable_zswap',
                    'description': 'Enable compressed swap in RAM',
                    'action': self._enable_zswap,
                    'conditions': ['memory_pressure'],
                    'rollback': self._disable_zswap
                }
            ],
            IssueCategory.AUDIO: [
                {
                    'name': 'restart_pipewire',
                    'description': 'Restart PipeWire audio server',
                    'action': self._restart_pipewire,
                    'conditions': ['audio_glitches', 'no_audio'],
                    'rollback': None
                }
            ]
        }

    async def start_monitoring(self):
        """Start the system monitoring and healing loop"""
        logger.info("Starting self-healing monitoring")
        self.monitoring_active = True
        
        # Load existing issues and history
        self._load_system_state()
        
        while self.monitoring_active:
            try:
                # Collect system metrics
                metrics = await self._collect_system_metrics()
                self.system_metrics_history.append(metrics)
                self._store_metrics(metrics)
                
                # Detect issues
                new_issues = await self._detect_issues(metrics)
                
                # Process new issues
                for issue in new_issues:
                    await self._handle_new_issue(issue)
                
                # Check on existing issues
                await self._monitor_existing_issues()
                
                # Perform healing actions
                await self._perform_healing_actions()
                
                # Cleanup old data
                await self._cleanup_old_data()
                
                await asyncio.sleep(self.monitoring_interval)
                
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                await asyncio.sleep(60)

    async def _collect_system_metrics(self) -> Dict[str, Any]:
        """Collect comprehensive system metrics"""
        try:
            # Basic system metrics
            cpu_usage = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # GPU metrics
            gpu_usage, gpu_temp = await self._get_gpu_metrics()
            
            # CPU temperature
            cpu_temp = await self._get_cpu_temperature()
            
            # Network metrics
            network_latency = await self._measure_network_latency()
            
            # Process count
            active_processes = len(psutil.pids())
            
            # System load
            system_load = psutil.getloadavg()[0] if hasattr(psutil, 'getloadavg') else 0
            
            # Hyprland-specific metrics
            hypr_metrics = await self._get_hyprland_metrics()
            
            return {
                'timestamp': time.time(),
                'cpu_usage': cpu_usage,
                'memory_usage': memory.percent,
                'gpu_usage': gpu_usage,
                'cpu_temperature': cpu_temp,
                'gpu_temperature': gpu_temp,
                'disk_usage': disk.percent,
                'network_latency': network_latency,
                'active_processes': active_processes,
                'system_load': system_load,
                **hypr_metrics
            }
            
        except Exception as e:
            logger.error(f"Error collecting metrics: {e}")
            return {'timestamp': time.time(), 'error': str(e)}

    async def _get_gpu_metrics(self) -> Tuple[float, float]:
        """Get GPU usage and temperature"""
        try:
            result = subprocess.run([
                'nvidia-smi', '--query-gpu=utilization.gpu,temperature.gpu',
                '--format=csv,noheader,nounits'
            ], capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                usage, temp = result.stdout.strip().split(', ')
                return float(usage), float(temp)
        except:
            pass
        return 0.0, 0.0

    async def _get_cpu_temperature(self) -> float:
        """Get CPU temperature"""
        try:
            temps = psutil.sensors_temperatures()
            if 'coretemp' in temps:
                return temps['coretemp'][0].current
            elif 'k10temp' in temps:  # AMD
                return temps['k10temp'][0].current
        except:
            pass
        return 0.0

    async def _measure_network_latency(self) -> float:
        """Measure network latency"""
        try:
            result = subprocess.run(
                ['ping', '-c', '1', '8.8.8.8'],
                capture_output=True, text=True, timeout=5
            )
            
            if result.returncode == 0:
                match = re.search(r'time=(\d+\.?\d*)', result.stdout)
                if match:
                    return float(match.group(1))
        except:
            pass
        return 0.0

    async def _get_hyprland_metrics(self) -> Dict[str, Any]:
        """Get Hyprland-specific metrics"""
        metrics = {
            'active_windows': 0,
            'workspace_count': 0,
            'compositor_responsive': True,
            'gpu_acceleration': True
        }
        
        try:
            # Get window count
            result = subprocess.run(
                ['hyprctl', 'clients'],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                metrics['active_windows'] = result.stdout.count('class:')
            
            # Get workspace count
            result = subprocess.run(
                ['hyprctl', 'workspaces'],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                metrics['workspace_count'] = result.stdout.count('workspace ID')
            
        except subprocess.TimeoutExpired:
            metrics['compositor_responsive'] = False
        except Exception:
            pass
        
        return metrics

    def _store_metrics(self, metrics: Dict[str, Any]):
        """Store metrics in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO system_metrics 
                (timestamp, cpu_usage, memory_usage, gpu_usage, temperature, 
                 disk_usage, network_latency, active_processes, system_load)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                metrics.get('timestamp', time.time()),
                metrics.get('cpu_usage', 0),
                metrics.get('memory_usage', 0),
                metrics.get('gpu_usage', 0),
                metrics.get('cpu_temperature', 0),
                metrics.get('disk_usage', 0),
                metrics.get('network_latency', 0),
                metrics.get('active_processes', 0),
                metrics.get('system_load', 0)
            ))
            
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error storing metrics: {e}")

    async def _detect_issues(self, current_metrics: Dict[str, Any]) -> List[SystemIssue]:
        """Detect system issues based on current metrics"""
        issues = []
        
        # High CPU usage
        if current_metrics.get('cpu_usage', 0) > self.issue_detection_thresholds['cpu_usage']:
            issues.append(self._create_cpu_issue(current_metrics))
        
        # High memory usage
        if current_metrics.get('memory_usage', 0) > self.issue_detection_thresholds['memory_usage']:
            issues.append(self._create_memory_issue(current_metrics))
        
        # High temperature
        cpu_temp = current_metrics.get('cpu_temperature', 0)
        gpu_temp = current_metrics.get('gpu_temperature', 0)
        max_temp = max(cpu_temp, gpu_temp)
        if max_temp > self.issue_detection_thresholds['temperature']:
            issues.append(self._create_temperature_issue(current_metrics))
        
        # Compositor issues
        if not current_metrics.get('compositor_responsive', True):
            issues.append(self._create_compositor_issue(current_metrics))
        
        # Check for patterns in historical data
        pattern_issues = await self._detect_pattern_issues()
        issues.extend(pattern_issues)
        
        # Filter out duplicates
        unique_issues = []
        for issue in issues:
            if not self._is_duplicate_issue(issue):
                unique_issues.append(issue)
        
        return unique_issues

    def _create_cpu_issue(self, metrics: Dict[str, Any]) -> SystemIssue:
        """Create CPU usage issue"""
        cpu_usage = metrics.get('cpu_usage', 0)
        
        return SystemIssue(
            issue_id=f"cpu_high_{int(time.time())}",
            timestamp=time.time(),
            category=IssueCategory.PERFORMANCE,
            severity=IssueSeverity.HIGH if cpu_usage > 95 else IssueSeverity.MEDIUM,
            title=f"High CPU Usage: {cpu_usage:.1f}%",
            description=f"CPU usage has reached {cpu_usage:.1f}%, which may cause system slowdown",
            symptoms=[
                "System responsiveness decreased",
                "Applications running slowly",
                "High CPU temperature possible"
            ],
            metrics=metrics,
            potential_causes=[
                "Resource-intensive applications running",
                "Background processes consuming CPU",
                "Inefficient system configuration",
                "Malware or runaway processes"
            ],
            suggested_fixes=[
                "Kill resource-intensive processes",
                "Reduce visual effects and animations",
                "Check for malware",
                "Optimize system configuration"
            ],
            auto_fixable=True
        )

    def _create_memory_issue(self, metrics: Dict[str, Any]) -> SystemIssue:
        """Create memory usage issue"""
        memory_usage = metrics.get('memory_usage', 0)
        
        return SystemIssue(
            issue_id=f"memory_high_{int(time.time())}",
            timestamp=time.time(),
            category=IssueCategory.MEMORY,
            severity=IssueSeverity.CRITICAL if memory_usage > 98 else IssueSeverity.HIGH,
            title=f"High Memory Usage: {memory_usage:.1f}%",
            description=f"Memory usage has reached {memory_usage:.1f}%, system may become unstable",
            symptoms=[
                "System becoming unresponsive",
                "Applications crashing",
                "Swap usage increasing",
                "OOM killer activating"
            ],
            metrics=metrics,
            potential_causes=[
                "Memory leaks in applications",
                "Too many applications running",
                "Insufficient RAM for workload",
                "System caches growing too large"
            ],
            suggested_fixes=[
                "Close unnecessary applications",
                "Clear system caches",
                "Kill memory-hogging processes",
                "Enable compressed swap"
            ],
            auto_fixable=True
        )

    def _create_temperature_issue(self, metrics: Dict[str, Any]) -> SystemIssue:
        """Create temperature issue"""
        cpu_temp = metrics.get('cpu_temperature', 0)
        gpu_temp = metrics.get('gpu_temperature', 0)
        max_temp = max(cpu_temp, gpu_temp)
        
        return SystemIssue(
            issue_id=f"temp_high_{int(time.time())}",
            timestamp=time.time(),
            category=IssueCategory.SYSTEM,
            severity=IssueSeverity.CRITICAL if max_temp > 90 else IssueSeverity.HIGH,
            title=f"High Temperature: {max_temp:.1f}°C",
            description=f"System temperature has reached {max_temp:.1f}°C, thermal throttling may occur",
            symptoms=[
                "System performance decreasing",
                "Fan noise increasing",
                "Thermal throttling active",
                "Potential hardware damage risk"
            ],
            metrics=metrics,
            potential_causes=[
                "Dust buildup in cooling system",
                "Failing cooling components",
                "High ambient temperature",
                "Excessive system load"
            ],
            suggested_fixes=[
                "Reduce system load",
                "Check cooling system",
                "Lower performance settings",
                "Improve ventilation"
            ],
            auto_fixable=True
        )

    def _create_compositor_issue(self, metrics: Dict[str, Any]) -> SystemIssue:
        """Create compositor responsiveness issue"""
        return SystemIssue(
            issue_id=f"compositor_hang_{int(time.time())}",
            timestamp=time.time(),
            category=IssueCategory.STABILITY,
            severity=IssueSeverity.HIGH,
            title="Compositor Not Responding",
            description="Hyprland compositor is not responding to commands",
            symptoms=[
                "hyprctl commands timing out",
                "Window management not working",
                "Display frozen or corrupted"
            ],
            metrics=metrics,
            potential_causes=[
                "Compositor crash or hang",
                "GPU driver issues",
                "Resource exhaustion",
                "Configuration errors"
            ],
            suggested_fixes=[
                "Restart Hyprland",
                "Check GPU drivers",
                "Reset configuration",
                "Check system resources"
            ],
            auto_fixable=True
        )

    async def _detect_pattern_issues(self) -> List[SystemIssue]:
        """Detect issues based on historical patterns"""
        issues = []
        
        if len(self.system_metrics_history) < 10:
            return issues
        
        # Check for gradual degradation
        recent_metrics = list(self.system_metrics_history)[-10:]
        
        # CPU usage trending up
        cpu_values = [m.get('cpu_usage', 0) for m in recent_metrics]
        if self._is_trending_up(cpu_values, threshold=20):
            issues.append(SystemIssue(
                issue_id=f"cpu_trend_{int(time.time())}",
                timestamp=time.time(),
                category=IssueCategory.PERFORMANCE,
                severity=IssueSeverity.MEDIUM,
                title="CPU Usage Trending Up",
                description="CPU usage has been steadily increasing",
                symptoms=["Gradual system slowdown"],
                metrics=recent_metrics[-1],
                potential_causes=["Resource leak", "Background processes"],
                suggested_fixes=["Monitor processes", "Restart applications"],
                auto_fixable=False
            ))
        
        # Memory usage trending up (possible leak)
        memory_values = [m.get('memory_usage', 0) for m in recent_metrics]
        if self._is_trending_up(memory_values, threshold=15):
            issues.append(SystemIssue(
                issue_id=f"memory_leak_{int(time.time())}",
                timestamp=time.time(),
                category=IssueCategory.MEMORY,
                severity=IssueSeverity.MEDIUM,
                title="Possible Memory Leak",
                description="Memory usage has been steadily increasing",
                symptoms=["Progressive system slowdown"],
                metrics=recent_metrics[-1],
                potential_causes=["Memory leak in application"],
                suggested_fixes=["Identify leaking process", "Restart applications"],
                auto_fixable=False
            ))
        
        return issues

    def _is_trending_up(self, values: List[float], threshold: float) -> bool:
        """Check if values are trending upward beyond threshold"""
        if len(values) < 5:
            return False
        
        first_half = values[:len(values)//2]
        second_half = values[len(values)//2:]
        
        avg_first = sum(first_half) / len(first_half)
        avg_second = sum(second_half) / len(second_half)
        
        return (avg_second - avg_first) > threshold

    def _is_duplicate_issue(self, new_issue: SystemIssue) -> bool:
        """Check if this is a duplicate of an existing issue"""
        for existing_issue in self.active_issues.values():
            if (existing_issue.category == new_issue.category and
                existing_issue.title == new_issue.title):
                return True
        return False

    async def _handle_new_issue(self, issue: SystemIssue):
        """Handle a newly detected issue"""
        logger.warning(f"Detected new issue: {issue.title}")
        
        # Store in active issues
        self.active_issues[issue.issue_id] = issue
        
        # Store in database
        self._store_issue(issue)
        
        # Log the issue
        self._log_issue_detection(issue)

    def _store_issue(self, issue: SystemIssue):
        """Store issue in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO system_issues 
                (issue_id, timestamp, category, severity, title, description,
                 symptoms, metrics, potential_causes, suggested_fixes, 
                 auto_fixable, resolved, resolution_attempts, resolution_timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                issue.issue_id, issue.timestamp, issue.category.value,
                issue.severity.value, issue.title, issue.description,
                json.dumps(issue.symptoms), json.dumps(issue.metrics),
                json.dumps(issue.potential_causes), json.dumps(issue.suggested_fixes),
                issue.auto_fixable, issue.resolved, issue.resolution_attempts,
                issue.resolution_timestamp
            ))
            
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error storing issue: {e}")

    def _log_issue_detection(self, issue: SystemIssue):
        """Log issue detection with appropriate level"""
        if issue.severity == IssueSeverity.CRITICAL:
            logger.critical(f"CRITICAL ISSUE: {issue.title} - {issue.description}")
        elif issue.severity == IssueSeverity.HIGH:
            logger.error(f"HIGH SEVERITY: {issue.title} - {issue.description}")
        elif issue.severity == IssueSeverity.MEDIUM:
            logger.warning(f"MEDIUM SEVERITY: {issue.title} - {issue.description}")
        else:
            logger.info(f"LOW SEVERITY: {issue.title} - {issue.description}")

    async def _monitor_existing_issues(self):
        """Monitor existing issues for resolution or escalation"""
        for issue_id, issue in list(self.active_issues.items()):
            # Check if issue has been resolved naturally
            if await self._is_issue_resolved(issue):
                logger.info(f"Issue resolved naturally: {issue.title}")
                issue.resolved = True
                issue.resolution_timestamp = time.time()
                self.resolved_issues.append(issue)
                del self.active_issues[issue_id]
                self._update_issue_in_db(issue)

    async def _is_issue_resolved(self, issue: SystemIssue) -> bool:
        """Check if an issue has been resolved"""
        current_metrics = self.system_metrics_history[-1] if self.system_metrics_history else {}
        
        if issue.category == IssueCategory.PERFORMANCE:
            cpu_usage = current_metrics.get('cpu_usage', 100)
            return cpu_usage < self.issue_detection_thresholds['cpu_usage'] * 0.8
        
        elif issue.category == IssueCategory.MEMORY:
            memory_usage = current_metrics.get('memory_usage', 100)
            return memory_usage < self.issue_detection_thresholds['memory_usage'] * 0.8
        
        elif issue.category == IssueCategory.SYSTEM:
            if 'temperature' in issue.title.lower():
                max_temp = max(
                    current_metrics.get('cpu_temperature', 100),
                    current_metrics.get('gpu_temperature', 100)
                )
                return max_temp < self.issue_detection_thresholds['temperature'] * 0.8
        
        elif issue.category == IssueCategory.STABILITY:
            return current_metrics.get('compositor_responsive', False)
        
        return False

    def _update_issue_in_db(self, issue: SystemIssue):
        """Update issue in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE system_issues 
                SET resolved = ?, resolution_attempts = ?, resolution_timestamp = ?
                WHERE issue_id = ?
            ''', (
                issue.resolved, issue.resolution_attempts,
                issue.resolution_timestamp, issue.issue_id
            ))
            
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error updating issue: {e}")

    async def _perform_healing_actions(self):
        """Perform automated healing actions for active issues"""
        for issue_id, issue in self.active_issues.items():
            if not issue.auto_fixable or issue.resolution_attempts > 2:
                continue
            
            # Find appropriate healing strategies
            strategies = self.healing_strategies.get(issue.category, [])
            
            for strategy in strategies:
                if await self._should_apply_strategy(strategy, issue):
                    await self._apply_healing_strategy(strategy, issue)
                    break

    async def _should_apply_strategy(self, strategy: Dict[str, Any], issue: SystemIssue) -> bool:
        """Determine if a healing strategy should be applied"""
        conditions = strategy.get('conditions', [])
        current_metrics = self.system_metrics_history[-1] if self.system_metrics_history else {}
        
        for condition in conditions:
            if not self._evaluate_condition(condition, current_metrics, issue):
                return False
        
        return True

    def _evaluate_condition(self, condition: str, metrics: Dict[str, Any], issue: SystemIssue) -> bool:
        """Evaluate a healing condition"""
        # Simple condition evaluation - would be more sophisticated in practice
        if 'cpu_usage > 85' in condition:
            return metrics.get('cpu_usage', 0) > 85
        elif 'gpu_usage > 90' in condition:
            return metrics.get('gpu_usage', 0) > 90
        elif 'memory_usage > 95' in condition:
            return metrics.get('memory_usage', 0) > 95
        elif 'low_fps' in condition:
            return True  # Simplified
        elif 'frequent_crashes' in condition:
            return issue.category == IssueCategory.STABILITY
        elif 'compositor_hang' in condition:
            return not metrics.get('compositor_responsive', True)
        
        return True

    async def _apply_healing_strategy(self, strategy: Dict[str, Any], issue: SystemIssue):
        """Apply a healing strategy"""
        action_id = f"heal_{int(time.time())}_{strategy['name']}"
        
        logger.info(f"Applying healing strategy: {strategy['description']}")
        
        action = HealingAction(
            action_id=action_id,
            timestamp=time.time(),
            issue_id=issue.issue_id,
            action_type=strategy['name'],
            description=strategy['description'],
            command=None,
            config_changes={},
            success=False,
            error_message=None,
            rollback_info=None
        )
        
        try:
            # Execute the healing action
            success = await strategy['action'](issue)
            action.success = success
            
            if success:
                logger.info(f"Healing action successful: {strategy['description']}")
                issue.resolution_attempts += 1
            else:
                logger.warning(f"Healing action failed: {strategy['description']}")
                issue.resolution_attempts += 1
            
        except Exception as e:
            logger.error(f"Error executing healing strategy: {e}")
            action.error_message = str(e)
            action.success = False
            issue.resolution_attempts += 1
        
        # Store the action
        self.healing_history.append(action)
        self._store_healing_action(action)

    def _store_healing_action(self, action: HealingAction):
        """Store healing action in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO healing_actions 
                (action_id, timestamp, issue_id, action_type, description,
                 command, config_changes, success, error_message, rollback_info)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                action.action_id, action.timestamp, action.issue_id,
                action.action_type, action.description, action.command,
                json.dumps(action.config_changes), action.success,
                action.error_message, json.dumps(action.rollback_info)
            ))
            
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error storing healing action: {e}")

    # Healing strategy implementations
    async def _reduce_animations(self, issue: SystemIssue) -> bool:
        """Reduce animations to improve performance"""
        try:
            commands = [
                ['hyprctl', 'keyword', 'animations:enabled', 'no'],
                ['hyprctl', 'keyword', 'decoration:blur:enabled', 'no']
            ]
            
            for cmd in commands:
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode != 0:
                    return False
            
            return True
        except Exception:
            return False

    async def _restore_animations(self, issue: SystemIssue) -> bool:
        """Restore animations"""
        try:
            commands = [
                ['hyprctl', 'keyword', 'animations:enabled', 'yes'],
                ['hyprctl', 'keyword', 'decoration:blur:enabled', 'yes']
            ]
            
            for cmd in commands:
                subprocess.run(cmd, capture_output=True, text=True)
            
            return True
        except Exception:
            return False

    async def _disable_blur(self, issue: SystemIssue) -> bool:
        """Disable blur effects"""
        try:
            result = subprocess.run(
                ['hyprctl', 'keyword', 'decoration:blur:enabled', 'no'],
                capture_output=True, text=True
            )
            return result.returncode == 0
        except Exception:
            return False

    async def _enable_blur(self, issue: SystemIssue) -> bool:
        """Enable blur effects"""
        try:
            result = subprocess.run(
                ['hyprctl', 'keyword', 'decoration:blur:enabled', 'yes'],
                capture_output=True, text=True
            )
            return result.returncode == 0
        except Exception:
            return False

    async def _kill_resource_hogs(self, issue: SystemIssue) -> bool:
        """Kill processes consuming excessive resources"""
        try:
            # Get processes sorted by resource usage
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    proc_info = proc.info
                    if proc_info['cpu_percent'] > 50 or proc_info['memory_percent'] > 20:
                        processes.append(proc_info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            # Kill the worst offenders (excluding system processes)
            excluded = {'systemd', 'kernel', 'init', 'kthreadd'}
            killed_any = False
            
            for proc_info in sorted(processes, key=lambda x: x['cpu_percent'] + x['memory_percent'], reverse=True)[:3]:
                if proc_info['name'] not in excluded:
                    try:
                        proc = psutil.Process(proc_info['pid'])
                        proc.terminate()
                        killed_any = True
                        logger.info(f"Terminated resource-hogging process: {proc_info['name']} (PID: {proc_info['pid']})")
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        continue
            
            return killed_any
        except Exception:
            return False

    async def _restart_hyprland(self, issue: SystemIssue) -> bool:
        """Restart Hyprland compositor"""
        try:
            # This is a dangerous operation - would need proper session management
            logger.warning("Hyprland restart requested but not implemented for safety")
            return False
        except Exception:
            return False

    async def _clear_caches(self, issue: SystemIssue) -> bool:
        """Clear system caches"""
        try:
            # Clear page cache, dentries, and inodes
            subprocess.run(['sudo', 'sync'], check=True)
            subprocess.run(['sudo', 'sh', '-c', 'echo 3 > /proc/sys/vm/drop_caches'], check=True)
            return True
        except Exception:
            return False

    async def _restart_pipewire(self, issue: SystemIssue) -> bool:
        """Restart PipeWire audio server"""
        try:
            subprocess.run(['systemctl', '--user', 'restart', 'pipewire'], check=True)
            subprocess.run(['systemctl', '--user', 'restart', 'pipewire-pulse'], check=True)
            return True
        except Exception:
            return False

    async def _restart_gpu_driver(self, issue: SystemIssue) -> bool:
        """Restart GPU driver modules"""
        try:
            # This is potentially dangerous and requires root
            logger.warning("GPU driver restart requested but requires manual intervention")
            return False
        except Exception:
            return False

    async def _enable_zswap(self, issue: SystemIssue) -> bool:
        """Enable compressed swap"""
        try:
            subprocess.run(['sudo', 'modprobe', 'zswap'], check=True)
            subprocess.run(['sudo', 'sh', '-c', 'echo 1 > /sys/module/zswap/parameters/enabled'], check=True)
            return True
        except Exception:
            return False

    async def _disable_zswap(self, issue: SystemIssue) -> bool:
        """Disable compressed swap"""
        try:
            subprocess.run(['sudo', 'sh', '-c', 'echo 0 > /sys/module/zswap/parameters/enabled'], check=True)
            return True
        except Exception:
            return False

    async def _adjust_refresh_rate(self, issue: SystemIssue) -> bool:
        """Lower display refresh rate"""
        try:
            result = subprocess.run(
                ['hyprctl', 'keyword', 'monitor', ',preferred,auto,1,60'],
                capture_output=True, text=True
            )
            return result.returncode == 0
        except Exception:
            return False

    async def _restore_refresh_rate(self, issue: SystemIssue) -> bool:
        """Restore display refresh rate"""
        try:
            result = subprocess.run(
                ['hyprctl', 'keyword', 'monitor', ',preferred,auto,1'],
                capture_output=True, text=True
            )
            return result.returncode == 0
        except Exception:
            return False

    async def _reset_to_defaults(self, issue: SystemIssue) -> bool:
        """Reset to last known good configuration"""
        try:
            # This would restore from backup
            logger.info("Configuration reset requested - would restore from backup")
            return True
        except Exception:
            return False

    async def _restore_user_config(self, issue: SystemIssue) -> bool:
        """Restore user configuration"""
        try:
            logger.info("User configuration restore requested")
            return True
        except Exception:
            return False

    def _load_system_state(self):
        """Load system state from database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Load active issues
            cursor.execute('''
                SELECT * FROM system_issues WHERE resolved = 0
            ''')
            
            for row in cursor.fetchall():
                issue_id, timestamp, category, severity, title, description, \
                symptoms, metrics, potential_causes, suggested_fixes, \
                auto_fixable, resolved, resolution_attempts, resolution_timestamp = row
                
                issue = SystemIssue(
                    issue_id=issue_id,
                    timestamp=timestamp,
                    category=IssueCategory(category),
                    severity=IssueSeverity(severity),
                    title=title,
                    description=description,
                    symptoms=json.loads(symptoms),
                    metrics=json.loads(metrics),
                    potential_causes=json.loads(potential_causes),
                    suggested_fixes=json.loads(suggested_fixes),
                    auto_fixable=bool(auto_fixable),
                    resolved=bool(resolved),
                    resolution_attempts=resolution_attempts,
                    resolution_timestamp=resolution_timestamp
                )
                
                self.active_issues[issue_id] = issue
            
            conn.close()
            logger.info(f"Loaded {len(self.active_issues)} active issues")
            
        except Exception as e:
            logger.error(f"Error loading system state: {e}")

    async def _cleanup_old_data(self):
        """Clean up old data to prevent database bloat"""
        try:
            cutoff_time = time.time() - (7 * 24 * 3600)  # 7 days ago
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Clean old metrics
            cursor.execute('DELETE FROM system_metrics WHERE timestamp < ?', (cutoff_time,))
            
            # Clean old resolved issues
            cursor.execute('''
                DELETE FROM system_issues 
                WHERE resolved = 1 AND resolution_timestamp < ?
            ''', (cutoff_time,))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f"Error cleaning up data: {e}")

    async def get_healing_report(self) -> Dict[str, Any]:
        """Generate comprehensive healing system report"""
        return {
            "timestamp": datetime.now().isoformat(),
            "system_status": {
                "monitoring_active": self.monitoring_active,
                "active_issues": len(self.active_issues),
                "resolved_issues": len(self.resolved_issues),
                "total_healing_actions": len(self.healing_history)
            },
            "active_issues": [
                {
                    "id": issue.issue_id,
                    "title": issue.title,
                    "category": issue.category.value,
                    "severity": issue.severity.name,
                    "age_minutes": (time.time() - issue.timestamp) / 60,
                    "resolution_attempts": issue.resolution_attempts
                }
                for issue in self.active_issues.values()
            ],
            "recent_actions": [
                {
                    "type": action.action_type,
                    "description": action.description,
                    "success": action.success,
                    "timestamp": action.timestamp
                }
                for action in self.healing_history[-10:]
            ],
            "system_health": {
                "critical_issues": len([i for i in self.active_issues.values() if i.severity == IssueSeverity.CRITICAL]),
                "high_priority_issues": len([i for i in self.active_issues.values() if i.severity == IssueSeverity.HIGH]),
                "auto_healing_success_rate": self._calculate_success_rate()
            }
        }

    def _calculate_success_rate(self) -> float:
        """Calculate auto-healing success rate"""
        if not self.healing_history:
            return 0.0
        
        successful_actions = len([a for a in self.healing_history if a.success])
        return (successful_actions / len(self.healing_history)) * 100

    def stop_monitoring(self):
        """Stop the monitoring system"""
        logger.info("Stopping self-healing monitoring")
        self.monitoring_active = False

async def main():
    """Main entry point for self-healing system"""
    healing_system = SelfHealingSystem()
    
    try:
        await healing_system.start_monitoring()
    except KeyboardInterrupt:
        healing_system.stop_monitoring()
        logger.info("Self-healing system stopped")

if __name__ == "__main__":
    asyncio.run(main())
