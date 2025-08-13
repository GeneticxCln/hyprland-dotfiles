#!/usr/bin/env python3
"""
Advanced AI System Learning Module
Collects behavioral data and provides intelligent recommendations
"""

import json
import time
import os
import subprocess
import psutil
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict

class AILearningSystem:
    def __init__(self):
        self.config_dir = Path.home() / ".config/hypr/ai-enhancements"
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.data_file = self.config_dir / "learning_data.json"
        self.recommendations_file = self.config_dir / "recommendations.json"
        self.load_data()
        
    def load_data(self):
        """Load existing learning data"""
        try:
            if self.data_file.exists():
                with open(self.data_file, 'r') as f:
                    self.data = json.load(f)
            else:
                self.data = {
                    'usage_patterns': {},
                    'app_usage': {},
                    'theme_preferences': {},
                    'performance_history': {},
                    'user_feedback': {},
                    'workload_patterns': {}
                }
        except Exception as e:
            print(f"Error loading data: {e}")
            self.data = {
                'usage_patterns': {},
                'app_usage': {},
                'theme_preferences': {},
                'performance_history': {},
                'user_feedback': {},
                'workload_patterns': {}
            }
    
    def save_data(self):
        """Save learning data to file"""
        try:
            with open(self.data_file, 'w') as f:
                json.dump(self.data, f, indent=2, default=str)
        except Exception as e:
            print(f"Error saving data: {e}")
    
    def collect_usage_data(self):
        """Collect current system usage data"""
        current_time = datetime.now()
        hour = current_time.hour
        day_of_week = current_time.strftime('%A')
        
        # System metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Running applications
        processes = []
        for proc in psutil.process_iter(['name', 'memory_percent', 'cpu_percent']):
            try:
                if proc.info['memory_percent'] > 1:  # Only significant processes
                    processes.append(proc.info['name'])
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Store usage pattern
        pattern_key = f"{day_of_week}_{hour}"
        if pattern_key not in self.data['usage_patterns']:
            self.data['usage_patterns'][pattern_key] = {
                'cpu_usage': [],
                'memory_usage': [],
                'active_apps': [],
                'count': 0
            }
        
        pattern = self.data['usage_patterns'][pattern_key]
        pattern['cpu_usage'].append(cpu_percent)
        pattern['memory_usage'].append(memory.percent)
        pattern['active_apps'].extend(processes)
        pattern['count'] += 1
        
        # Keep only recent data (last 50 entries per pattern)
        for key in ['cpu_usage', 'memory_usage']:
            if len(pattern[key]) > 50:
                pattern[key] = pattern[key][-50:]
        
        if len(pattern['active_apps']) > 200:
            pattern['active_apps'] = pattern['active_apps'][-200:]
        
        print(f"📊 Collected usage data for {pattern_key} (#{pattern['count']})")
        
        # Update app usage statistics
        for app in set(processes):
            if app not in self.data['app_usage']:
                self.data['app_usage'][app] = {
                    'total_time': 0,
                    'usage_times': [],
                    'contexts': []
                }
            
            self.data['app_usage'][app]['usage_times'].append(current_time.isoformat())
            self.data['app_usage'][app]['total_time'] += 1
            
            # Keep only recent usage times
            if len(self.data['app_usage'][app]['usage_times']) > 100:
                self.data['app_usage'][app]['usage_times'] = self.data['app_usage'][app]['usage_times'][-100:]
        
        self.save_data()
    
    def detect_workload_type(self) -> str:
        """Detect current workload type based on running applications"""
        processes = [proc.name() for proc in psutil.process_iter()]
        
        # Gaming workload
        gaming_apps = ['steam', 'lutris', 'heroic', 'wine', 'proton']
        if any(app in ' '.join(processes).lower() for app in gaming_apps):
            return 'gaming'
        
        # Development workload
        dev_apps = ['code', 'nvim', 'vim', 'jetbrains', 'cargo', 'make', 'gcc', 'python']
        if any(app in ' '.join(processes).lower() for app in dev_apps):
            return 'development'
        
        # Media workload
        media_apps = ['vlc', 'mpv', 'ffmpeg', 'obs', 'gimp', 'inkscape', 'blender']
        if any(app in ' '.join(processes).lower() for app in media_apps):
            return 'media'
        
        # Productivity workload
        productivity_apps = ['firefox', 'chrome', 'thunderbird', 'libreoffice', 'discord']
        if any(app in ' '.join(processes).lower() for app in productivity_apps):
            return 'productivity'
        
        return 'general'
    
    def generate_intelligent_recommendations(self) -> Dict[str, Any]:
        """Generate AI recommendations based on collected data"""
        current_hour = datetime.now().hour
        current_day = datetime.now().strftime('%A')
        workload_type = self.detect_workload_type()
        
        recommendations = {
            'theme_recommendation': self.recommend_theme(),
            'performance_recommendation': self.recommend_performance_settings(),
            'cleanup_recommendation': self.recommend_cleanup(),
            'break_recommendation': self.recommend_break(),
            'workload_optimization': self.recommend_workload_optimization(workload_type),
            'predicted_apps': self.predict_likely_apps(),
            'confidence_score': 0.0
        }
        
        # Calculate confidence based on available data
        pattern_key = f"{current_day}_{current_hour}"
        if pattern_key in self.data['usage_patterns']:
            data_points = self.data['usage_patterns'][pattern_key]['count']
            recommendations['confidence_score'] = min(data_points / 10.0, 1.0)
        
        return recommendations
    
    def recommend_theme(self) -> Dict[str, str]:
        """Recommend theme based on time, workload, and user preferences"""
        current_hour = datetime.now().hour
        workload = self.detect_workload_type()
        
        # Default time-based recommendations
        if current_hour < 6 or current_hour > 20:
            base_theme = "catppuccin-mocha"  # Dark for night
        elif current_hour < 12:
            base_theme = "catppuccin-latte"  # Light for morning
        else:
            base_theme = "catppuccin-macchiato"  # Balanced for day
        
        # Workload-specific overrides
        workload_themes = {
            'gaming': 'tokyonight-night',
            'development': 'monokai-pro',
            'media': 'dracula',
            'productivity': 'nord'
        }
        
        recommended_theme = workload_themes.get(workload, base_theme)
        
        return {
            'theme': recommended_theme,
            'reason': f"Optimized for {workload} workload at {current_hour}:00",
            'workload': workload
        }
    
    def recommend_performance_settings(self) -> Dict[str, Any]:
        """Recommend performance settings based on usage patterns"""
        workload = self.detect_workload_type()
        
        settings = {
            'gaming': {
                'cpu_governor': 'performance',
                'io_scheduler': 'mq-deadline',
                'swappiness': 10,
                'reason': 'Maximum performance for gaming'
            },
            'development': {
                'cpu_governor': 'ondemand',
                'io_scheduler': 'bfq',
                'swappiness': 60,
                'reason': 'Balanced performance for development'
            },
            'media': {
                'cpu_governor': 'performance',
                'io_scheduler': 'bfq',
                'swappiness': 30,
                'reason': 'Optimized for media processing'
            },
            'productivity': {
                'cpu_governor': 'powersave',
                'io_scheduler': 'bfq',
                'swappiness': 60,
                'reason': 'Power efficient for office work'
            }
        }
        
        return settings.get(workload, settings['productivity'])
    
    def recommend_cleanup(self) -> Dict[str, Any]:
        """Recommend cleanup actions based on system state"""
        try:
            disk_usage = psutil.disk_usage('/').percent
            memory_usage = psutil.virtual_memory().percent
            
            recommendations = []
            priority = 'low'
            
            if disk_usage > 85:
                recommendations.append("Disk cleanup - usage above 85%")
                priority = 'high'
            elif disk_usage > 75:
                recommendations.append("Consider disk cleanup - usage above 75%")
                priority = 'medium'
            
            if memory_usage > 80:
                recommendations.append("Memory optimization recommended")
                priority = 'high'
            
            # Check for old files
            home_size = sum(f.stat().st_size for f in Path.home().rglob('*') if f.is_file()) / (1024**3)
            if home_size > 50:  # 50GB
                recommendations.append("Large home directory detected")
            
            return {
                'actions': recommendations,
                'priority': priority,
                'disk_usage': disk_usage,
                'memory_usage': memory_usage
            }
            
        except Exception as e:
            return {
                'actions': ['Unable to analyze system state'],
                'priority': 'low',
                'error': str(e)
            }
    
    def recommend_break(self) -> Dict[str, Any]:
        """Recommend breaks based on usage patterns"""
        current_time = datetime.now()
        session_file = self.config_dir / "session_start"
        
        try:
            if session_file.exists():
                session_start = datetime.fromtimestamp(float(session_file.read_text().strip()))
                session_duration = (current_time - session_start).total_seconds() / 3600
                
                if session_duration > 2:
                    return {
                        'recommend_break': True,
                        'session_duration': round(session_duration, 1),
                        'break_type': 'long' if session_duration > 4 else 'short',
                        'message': f"You've been active for {session_duration:.1f} hours"
                    }
            
            return {'recommend_break': False}
            
        except Exception:
            return {'recommend_break': False, 'error': 'Unable to determine session duration'}
    
    def recommend_workload_optimization(self, workload: str) -> Dict[str, Any]:
        """Recommend optimizations specific to current workload"""
        optimizations = {
            'gaming': {
                'suggestions': [
                    'Enable game mode',
                    'Set CPU governor to performance',
                    'Close unnecessary background apps',
                    'Use dark theme to reduce eye strain'
                ],
                'priority': 'high'
            },
            'development': {
                'suggestions': [
                    'Enable development tools',
                    'Set up optimal editor settings',
                    'Use coding-friendly theme',
                    'Optimize terminal performance'
                ],
                'priority': 'medium'
            },
            'media': {
                'suggestions': [
                    'Allocate more RAM to media apps',
                    'Enable hardware acceleration',
                    'Optimize storage for large files',
                    'Use media-optimized theme'
                ],
                'priority': 'medium'
            },
            'productivity': {
                'suggestions': [
                    'Enable power saving mode',
                    'Optimize for battery life',
                    'Use comfortable theme for long sessions',
                    'Set up distraction-free environment'
                ],
                'priority': 'low'
            }
        }
        
        return optimizations.get(workload, {
            'suggestions': ['No specific optimizations available'],
            'priority': 'low'
        })
    
    def predict_likely_apps(self) -> List[str]:
        """Predict likely applications user might open based on patterns"""
        current_hour = datetime.now().hour
        current_day = datetime.now().strftime('%A')
        pattern_key = f"{current_day}_{current_hour}"
        
        if pattern_key in self.data['usage_patterns']:
            app_frequency = defaultdict(int)
            for app in self.data['usage_patterns'][pattern_key]['active_apps']:
                app_frequency[app] += 1
            
            # Return top 5 most frequent apps
            return sorted(app_frequency.keys(), key=lambda x: app_frequency[x], reverse=True)[:5]
        
        return []
    
    def learn_from_feedback(self, action: str, feedback: str):
        """Learn from user feedback on AI actions"""
        if action not in self.data['user_feedback']:
            self.data['user_feedback'][action] = []
        
        self.data['user_feedback'][action].append({
            'feedback': feedback,
            'timestamp': datetime.now().isoformat(),
            'context': self.detect_workload_type()
        })
        
        # Keep only recent feedback
        if len(self.data['user_feedback'][action]) > 20:
            self.data['user_feedback'][action] = self.data['user_feedback'][action][-20:]
        
        self.save_data()
        print(f"📝 Learned from feedback for {action}: {feedback}")

def main():
    """Main function for AI learning system"""
    import argparse
    parser = argparse.ArgumentParser(description='AI Learning System')
    parser.add_argument('action', choices=['collect', 'recommend', 'feedback'], 
                       help='Action to perform')
    parser.add_argument('--feedback-action', help='Action to provide feedback for')
    parser.add_argument('--feedback-value', help='Feedback value (positive/negative/neutral)')
    
    args = parser.parse_args()
    
    ai_system = AILearningSystem()
    
    if args.action == 'collect':
        print("🧠 AI Learning System - Collecting Usage Data")
        ai_system.collect_usage_data()
        
    elif args.action == 'recommend':
        print("🎯 AI Learning System - Generating Recommendations")
        recommendations = ai_system.generate_intelligent_recommendations()
        
        # Save recommendations
        with open(ai_system.recommendations_file, 'w') as f:
            json.dump(recommendations, f, indent=2, default=str)
        
        print(f"💡 Theme: {recommendations['theme_recommendation']['theme']}")
        print(f"🔧 Performance: {recommendations['performance_recommendation']['reason']}")
        print(f"🧹 Cleanup: {recommendations['cleanup_recommendation']['priority']} priority")
        print(f"⏰ Break: {recommendations['break_recommendation'].get('recommend_break', False)}")
        print(f"🎯 Workload: {recommendations['workload_optimization']['priority']} priority optimization")
        print(f"📊 Confidence: {recommendations['confidence_score']:.1%}")
        
    elif args.action == 'feedback':
        if args.feedback_action and args.feedback_value:
            ai_system.learn_from_feedback(args.feedback_action, args.feedback_value)
        else:
            print("Error: --feedback-action and --feedback-value required")

if __name__ == "__main__":
    main()
