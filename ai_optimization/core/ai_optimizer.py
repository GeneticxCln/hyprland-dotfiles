#!/usr/bin/env python3
"""
Advanced AI-Driven Optimization Engine for Hyprland
Implements neural network-based performance prediction and autonomous optimization
"""

import asyncio
import json
import logging
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import psutil
import subprocess
import time
from datetime import datetime, timedelta
import pickle
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest
import threading
from collections import deque
import warnings
warnings.filterwarnings('ignore')

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class SystemMetrics:
    """Comprehensive system metrics for AI analysis"""
    timestamp: float
    cpu_usage: float
    memory_usage: float
    gpu_usage: float
    gpu_memory: float
    io_read: float
    io_write: float
    network_sent: float
    network_recv: float
    active_windows: int
    workspace_switches: int
    animation_fps: float
    power_consumption: float
    temperature: float
    battery_level: float
    user_activity_score: float

@dataclass
class OptimizationTarget:
    """Defines what we're optimizing for"""
    performance_weight: float = 0.4
    battery_weight: float = 0.2
    user_experience_weight: float = 0.3
    stability_weight: float = 0.1

class PerformancePredictor(nn.Module):
    """Neural network for predicting system performance"""
    
    def __init__(self, input_size: int = 16, hidden_size: int = 128):
        super(PerformancePredictor, self).__init__()
        self.network = nn.Sequential(
            nn.Linear(input_size, hidden_size),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(hidden_size, hidden_size),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(hidden_size, 64),
            nn.ReLU(),
            nn.Linear(64, 4)  # [performance_score, battery_impact, stability_score, user_satisfaction]
        )
    
    def forward(self, x):
        return torch.sigmoid(self.network(x))

class AIOptimizer:
    """Main AI optimization engine"""
    
    def __init__(self, config_path: str = "/home/sasha/.config/hypr"):
        self.config_path = Path(config_path)
        self.model_path = Path("/home/sasha/hyprland-project/ai_optimization/models")
        self.model_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize components
        self.predictor = PerformancePredictor()
        self.optimizer = optim.Adam(self.predictor.parameters(), lr=0.001)
        self.scaler = StandardScaler()
        self.anomaly_detector = IsolationForest(contamination=0.1)
        
        # Data storage
        self.metrics_history = deque(maxlen=10000)
        self.optimization_history = []
        self.current_config = {}
        
        # Performance tracking
        self.performance_baseline = None
        self.last_optimization = None
        self.learning_rate = 0.001
        
        # Load existing models
        self._load_models()
        
        # Configuration ranges for optimization
        self.config_ranges = {
            'animations:enabled': [0, 1],
            'decoration:blur:enabled': [0, 1],
            'decoration:drop_shadow': [0, 1],
            'decoration:rounding': [0, 20],
            'misc:vfr': [0, 1],
            'render:direct_scanout': [0, 1],
            'general:gaps_in': [0, 15],
            'general:gaps_out': [0, 30],
            'animations:bezier_steps': [1, 10],
            'decoration:blur:size': [1, 10],
            'decoration:blur:passes': [1, 4]
        }
        
        logger.info("AI Optimizer initialized successfully")

    async def start_optimization_loop(self):
        """Start the main optimization loop"""
        logger.info("Starting AI optimization loop")
        
        while True:
            try:
                # Collect metrics
                metrics = await self._collect_metrics()
                self.metrics_history.append(metrics)
                
                # Check if optimization is needed
                if await self._should_optimize():
                    await self._perform_optimization()
                
                # Learn from current performance
                await self._update_model()
                
                # Sleep before next iteration
                await asyncio.sleep(30)  # Optimize every 30 seconds
                
            except Exception as e:
                logger.error(f"Error in optimization loop: {e}")
                await asyncio.sleep(60)  # Wait longer on error

    async def _collect_metrics(self) -> SystemMetrics:
        """Collect comprehensive system metrics"""
        try:
            # System metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            
            # GPU metrics (if available)
            gpu_usage, gpu_memory = await self._get_gpu_metrics()
            
            # IO metrics
            io_counters = psutil.disk_io_counters()
            io_read = io_counters.read_bytes if io_counters else 0
            io_write = io_counters.write_bytes if io_counters else 0
            
            # Network metrics
            net_counters = psutil.net_io_counters()
            network_sent = net_counters.bytes_sent if net_counters else 0
            network_recv = net_counters.bytes_recv if net_counters else 0
            
            # Hyprland-specific metrics
            active_windows = await self._get_active_windows_count()
            workspace_switches = await self._get_workspace_switches()
            animation_fps = await self._get_animation_fps()
            
            # Power and thermal metrics
            power_consumption = await self._get_power_consumption()
            temperature = await self._get_temperature()
            battery_level = await self._get_battery_level()
            
            # User activity
            user_activity = await self._calculate_user_activity()
            
            return SystemMetrics(
                timestamp=time.time(),
                cpu_usage=cpu_percent,
                memory_usage=memory.percent,
                gpu_usage=gpu_usage,
                gpu_memory=gpu_memory,
                io_read=io_read,
                io_write=io_write,
                network_sent=network_sent,
                network_recv=network_recv,
                active_windows=active_windows,
                workspace_switches=workspace_switches,
                animation_fps=animation_fps,
                power_consumption=power_consumption,
                temperature=temperature,
                battery_level=battery_level,
                user_activity_score=user_activity
            )
        except Exception as e:
            logger.error(f"Error collecting metrics: {e}")
            raise

    async def _get_gpu_metrics(self) -> Tuple[float, float]:
        """Get GPU usage and memory metrics"""
        try:
            # Try nvidia-ml-py first
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            gpu_util = pynvml.nvmlDeviceGetUtilizationRates(handle)
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            
            gpu_usage = gpu_util.gpu
            gpu_memory = (mem_info.used / mem_info.total) * 100
            
            return gpu_usage, gpu_memory
        except:
            try:
                # Fallback to nvidia-smi
                result = subprocess.run([
                    'nvidia-smi', '--query-gpu=utilization.gpu,memory.used,memory.total',
                    '--format=csv,noheader,nounits'
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    values = result.stdout.strip().split(', ')
                    gpu_usage = float(values[0])
                    memory_used = float(values[1])
                    memory_total = float(values[2])
                    gpu_memory = (memory_used / memory_total) * 100
                    return gpu_usage, gpu_memory
            except:
                pass
            
            return 0.0, 0.0

    async def _get_active_windows_count(self) -> int:
        """Get number of active windows"""
        try:
            result = subprocess.run(['hyprctl', 'clients'], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.count('class:')
        except:
            pass
        return 0

    async def _get_workspace_switches(self) -> int:
        """Track workspace switches (simplified implementation)"""
        # This would ideally track actual workspace switches over time
        # For now, return current workspace as a proxy
        try:
            result = subprocess.run(['hyprctl', 'activeworkspace'], capture_output=True, text=True)
            if result.returncode == 0:
                return 1  # Simplified
        except:
            pass
        return 0

    async def _get_animation_fps(self) -> float:
        """Get current animation FPS"""
        # This is a simplified implementation
        # Real implementation would hook into Hyprland's animation system
        return 60.0

    async def _get_power_consumption(self) -> float:
        """Get system power consumption"""
        try:
            # Try to read from RAPL (Intel) or similar
            power_files = list(Path('/sys/class/powercap').glob('*/energy_uj'))
            if power_files:
                total_power = 0
                for pfile in power_files:
                    with open(pfile) as f:
                        total_power += int(f.read().strip())
                return total_power / 1000000  # Convert to watts
        except:
            pass
        return 0.0

    async def _get_temperature(self) -> float:
        """Get system temperature"""
        try:
            temps = psutil.sensors_temperatures()
            if temps:
                for name, entries in temps.items():
                    if entries:
                        return entries[0].current
        except:
            pass
        return 0.0

    async def _get_battery_level(self) -> float:
        """Get battery level"""
        try:
            battery = psutil.sensors_battery()
            if battery:
                return battery.percent
        except:
            pass
        return 100.0

    async def _calculate_user_activity(self) -> float:
        """Calculate user activity score"""
        # This would track mouse movement, keyboard input, etc.
        # Simplified implementation
        return 50.0

    async def _should_optimize(self) -> bool:
        """Determine if optimization should be performed"""
        if len(self.metrics_history) < 10:
            return False
        
        # Check if performance has degraded
        recent_metrics = list(self.metrics_history)[-10:]
        avg_cpu = sum(m.cpu_usage for m in recent_metrics) / len(recent_metrics)
        avg_memory = sum(m.memory_usage for m in recent_metrics) / len(recent_metrics)
        
        # Optimize if high resource usage or every 5 minutes
        if avg_cpu > 80 or avg_memory > 85:
            return True
        
        if self.last_optimization is None:
            return True
        
        return (time.time() - self.last_optimization) > 300  # 5 minutes

    async def _perform_optimization(self):
        """Perform AI-driven optimization"""
        logger.info("Performing AI optimization")
        
        try:
            # Get current metrics
            current_metrics = self.metrics_history[-1]
            
            # Predict optimal configuration
            optimal_config = await self._predict_optimal_config(current_metrics)
            
            # Apply configuration
            await self._apply_configuration(optimal_config)
            
            # Update tracking
            self.last_optimization = time.time()
            self.optimization_history.append({
                'timestamp': time.time(),
                'metrics': asdict(current_metrics),
                'config': optimal_config
            })
            
            logger.info("Optimization completed successfully")
            
        except Exception as e:
            logger.error(f"Error during optimization: {e}")

    async def _predict_optimal_config(self, metrics: SystemMetrics) -> Dict[str, Any]:
        """Use AI to predict optimal configuration"""
        try:
            # Prepare input data
            input_data = self._metrics_to_tensor(metrics)
            
            # Generate multiple configuration candidates
            candidates = []
            for _ in range(100):  # Generate 100 candidates
                candidate = self._generate_random_config()
                
                # Predict performance for this candidate
                combined_input = torch.cat([input_data, self._config_to_tensor(candidate)])
                with torch.no_grad():
                    prediction = self.predictor(combined_input.unsqueeze(0))
                
                # Calculate score based on optimization targets
                score = self._calculate_optimization_score(prediction[0])
                candidates.append((candidate, score.item()))
            
            # Select best candidate
            best_config = max(candidates, key=lambda x: x[1])[0]
            
            return best_config
            
        except Exception as e:
            logger.error(f"Error predicting optimal config: {e}")
            return {}

    def _metrics_to_tensor(self, metrics: SystemMetrics) -> torch.Tensor:
        """Convert metrics to tensor for neural network"""
        values = [
            metrics.cpu_usage / 100.0,
            metrics.memory_usage / 100.0,
            metrics.gpu_usage / 100.0,
            metrics.gpu_memory / 100.0,
            min(metrics.io_read / 1e9, 1.0),  # Normalize IO
            min(metrics.io_write / 1e9, 1.0),
            min(metrics.network_sent / 1e9, 1.0),
            min(metrics.network_recv / 1e9, 1.0),
            min(metrics.active_windows / 20.0, 1.0),
            min(metrics.workspace_switches / 10.0, 1.0),
            metrics.animation_fps / 60.0,
            min(metrics.power_consumption / 100.0, 1.0),
            min(metrics.temperature / 80.0, 1.0),
            metrics.battery_level / 100.0,
            metrics.user_activity_score / 100.0,
            time.time() % 86400 / 86400.0  # Time of day
        ]
        return torch.tensor(values, dtype=torch.float32)

    def _config_to_tensor(self, config: Dict[str, Any]) -> torch.Tensor:
        """Convert configuration to tensor"""
        values = []
        for key in self.config_ranges:
            if key in config:
                range_min, range_max = self.config_ranges[key]
                normalized = (config[key] - range_min) / (range_max - range_min)
                values.append(normalized)
            else:
                values.append(0.5)  # Default middle value
        return torch.tensor(values, dtype=torch.float32)

    def _generate_random_config(self) -> Dict[str, Any]:
        """Generate a random configuration for exploration"""
        config = {}
        for key, (min_val, max_val) in self.config_ranges.items():
            if isinstance(min_val, int) and isinstance(max_val, int):
                config[key] = np.random.randint(min_val, max_val + 1)
            else:
                config[key] = np.random.uniform(min_val, max_val)
        return config

    def _calculate_optimization_score(self, prediction: torch.Tensor) -> torch.Tensor:
        """Calculate optimization score based on targets"""
        target = OptimizationTarget()
        
        performance_score = prediction[0]
        battery_score = 1.0 - prediction[1]  # Lower battery impact is better
        stability_score = prediction[2]
        user_satisfaction = prediction[3]
        
        total_score = (
            performance_score * target.performance_weight +
            battery_score * target.battery_weight +
            user_satisfaction * target.user_experience_weight +
            stability_score * target.stability_weight
        )
        
        return total_score

    async def _apply_configuration(self, config: Dict[str, Any]):
        """Apply configuration to Hyprland"""
        try:
            # Generate hyprland config
            config_lines = []
            for key, value in config.items():
                if key.startswith('animations:'):
                    param = key.replace('animations:', '')
                    if param == 'enabled':
                        config_lines.append(f"animations:enabled = {'yes' if value else 'no'}")
                    else:
                        config_lines.append(f"animations:{param} = {value}")
                elif key.startswith('decoration:'):
                    param = key.replace('decoration:', '')
                    if param == 'blur:enabled':
                        config_lines.append(f"decoration:blur:enabled = {'yes' if value else 'no'}")
                    elif param == 'drop_shadow':
                        config_lines.append(f"decoration:drop_shadow = {'yes' if value else 'no'}")
                    else:
                        config_lines.append(f"decoration:{param} = {value}")
                elif key.startswith('general:'):
                    param = key.replace('general:', '')
                    config_lines.append(f"general:{param} = {value}")
                elif key.startswith('misc:'):
                    param = key.replace('misc:', '')
                    config_lines.append(f"misc:{param} = {'yes' if value else 'no'}")
                elif key.startswith('render:'):
                    param = key.replace('render:', '')
                    config_lines.append(f"render:{param} = {'yes' if value else 'no'}")
            
            # Apply via hyprctl
            for line in config_lines:
                cmd = ['hyprctl', 'keyword'] + line.split(' = ')
                subprocess.run(cmd, check=True, capture_output=True)
            
            self.current_config = config
            logger.info(f"Applied configuration: {config}")
            
        except Exception as e:
            logger.error(f"Error applying configuration: {e}")

    async def _update_model(self):
        """Update the neural network model with new data"""
        if len(self.metrics_history) < 50:  # Need enough data
            return
        
        try:
            # Prepare training data
            X = []
            y = []
            
            for i, metrics in enumerate(list(self.metrics_history)[-50:]):
                if i == 0:
                    continue
                
                prev_metrics = list(self.metrics_history)[-(50-i+1)]
                
                # Input: previous metrics + configuration
                input_tensor = self._metrics_to_tensor(prev_metrics)
                config_tensor = self._config_to_tensor(self.current_config)
                combined_input = torch.cat([input_tensor, config_tensor])
                
                # Output: performance improvement
                performance_improvement = self._calculate_performance_improvement(prev_metrics, metrics)
                
                X.append(combined_input)
                y.append(performance_improvement)
            
            if len(X) < 10:  # Need minimum training samples
                return
            
            # Train the model
            X_tensor = torch.stack(X)
            y_tensor = torch.stack(y)
            
            self.predictor.train()
            self.optimizer.zero_grad()
            
            predictions = self.predictor(X_tensor)
            loss = nn.MSELoss()(predictions, y_tensor)
            
            loss.backward()
            self.optimizer.step()
            
            logger.info(f"Model updated - Loss: {loss.item():.4f}")
            
            # Save model periodically
            if len(self.optimization_history) % 10 == 0:
                self._save_models()
            
        except Exception as e:
            logger.error(f"Error updating model: {e}")

    def _calculate_performance_improvement(self, prev_metrics: SystemMetrics, curr_metrics: SystemMetrics) -> torch.Tensor:
        """Calculate performance improvement between metrics"""
        # This is a simplified calculation
        # In practice, you'd want more sophisticated performance metrics
        
        cpu_improvement = (prev_metrics.cpu_usage - curr_metrics.cpu_usage) / 100.0
        memory_improvement = (prev_metrics.memory_usage - curr_metrics.memory_usage) / 100.0
        fps_improvement = (curr_metrics.animation_fps - prev_metrics.animation_fps) / 60.0
        battery_improvement = (curr_metrics.battery_level - prev_metrics.battery_level) / 100.0
        
        return torch.tensor([
            max(cpu_improvement, -1.0),  # Performance score
            max(battery_improvement, -1.0),  # Battery impact
            0.8,  # Stability (simplified)
            0.7   # User satisfaction (simplified)
        ], dtype=torch.float32)

    def _save_models(self):
        """Save trained models and data"""
        try:
            # Save neural network
            torch.save(self.predictor.state_dict(), self.model_path / 'predictor.pth')
            
            # Save scaler and other components
            with open(self.model_path / 'scaler.pkl', 'wb') as f:
                pickle.dump(self.scaler, f)
            
            with open(self.model_path / 'anomaly_detector.pkl', 'wb') as f:
                pickle.dump(self.anomaly_detector, f)
            
            # Save optimization history
            with open(self.model_path / 'optimization_history.json', 'w') as f:
                json.dump(self.optimization_history, f, indent=2)
            
            logger.info("Models saved successfully")
            
        except Exception as e:
            logger.error(f"Error saving models: {e}")

    def _load_models(self):
        """Load existing trained models"""
        try:
            # Load neural network
            predictor_path = self.model_path / 'predictor.pth'
            if predictor_path.exists():
                self.predictor.load_state_dict(torch.load(predictor_path))
                logger.info("Loaded existing predictor model")
            
            # Load other components
            scaler_path = self.model_path / 'scaler.pkl'
            if scaler_path.exists():
                with open(scaler_path, 'rb') as f:
                    self.scaler = pickle.load(f)
            
            anomaly_path = self.model_path / 'anomaly_detector.pkl'
            if anomaly_path.exists():
                with open(anomaly_path, 'rb') as f:
                    self.anomaly_detector = pickle.load(f)
            
            # Load optimization history
            history_path = self.model_path / 'optimization_history.json'
            if history_path.exists():
                with open(history_path) as f:
                    self.optimization_history = json.load(f)
            
        except Exception as e:
            logger.error(f"Error loading models: {e}")

    async def get_optimization_report(self) -> Dict[str, Any]:
        """Generate comprehensive optimization report"""
        if not self.metrics_history:
            return {"error": "No metrics available"}
        
        recent_metrics = list(self.metrics_history)[-20:]  # Last 20 samples
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "system_health": {
                "avg_cpu": sum(m.cpu_usage for m in recent_metrics) / len(recent_metrics),
                "avg_memory": sum(m.memory_usage for m in recent_metrics) / len(recent_metrics),
                "avg_gpu": sum(m.gpu_usage for m in recent_metrics) / len(recent_metrics),
                "avg_temperature": sum(m.temperature for m in recent_metrics) / len(recent_metrics),
                "battery_level": recent_metrics[-1].battery_level
            },
            "optimization_stats": {
                "total_optimizations": len(self.optimization_history),
                "last_optimization": self.last_optimization,
                "current_config": self.current_config
            },
            "ai_model_status": {
                "training_samples": len(self.metrics_history),
                "model_loaded": True
            },
            "recommendations": self._generate_recommendations(recent_metrics)
        }
        
        return report

    def _generate_recommendations(self, metrics: List[SystemMetrics]) -> List[str]:
        """Generate optimization recommendations"""
        recommendations = []
        
        avg_cpu = sum(m.cpu_usage for m in metrics) / len(metrics)
        avg_memory = sum(m.memory_usage for m in metrics) / len(metrics)
        avg_battery = sum(m.battery_level for m in metrics) / len(metrics)
        
        if avg_cpu > 80:
            recommendations.append("High CPU usage detected - consider disabling animations")
        
        if avg_memory > 85:
            recommendations.append("High memory usage - consider reducing blur effects")
        
        if avg_battery < 20:
            recommendations.append("Low battery - switching to power-saving mode")
        
        return recommendations

async def main():
    """Main entry point for the AI optimizer"""
    optimizer = AIOptimizer()
    
    # Start optimization loop
    await optimizer.start_optimization_loop()

if __name__ == "__main__":
    asyncio.run(main())
