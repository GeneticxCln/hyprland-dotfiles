#!/usr/bin/env python3
"""
Adaptive Configuration Manager for Hyprland
Uses machine learning to learn user preferences and automatically adjust configurations
"""

import asyncio
import json
import logging
import numpy as np
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Set
import time
from datetime import datetime, timedelta
import hashlib
import sqlite3
from collections import defaultdict, Counter
import subprocess
import re
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import cosine_similarity
import threading
import queue
import pickle

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class UserContext:
    """Current user context for preference learning"""
    timestamp: float
    hour_of_day: int
    day_of_week: int
    active_applications: List[str]
    workspace_layout: str
    window_count: int
    screen_brightness: float
    system_load: float
    battery_level: float
    is_gaming: bool
    is_coding: bool
    is_media_consumption: bool
    user_activity_pattern: str

@dataclass
class ConfigurationChange:
    """Represents a configuration change made by the user"""
    timestamp: float
    config_key: str
    old_value: Any
    new_value: Any
    context: UserContext
    change_source: str  # 'user', 'ai', 'adaptive'

@dataclass
class PreferenceProfile:
    """User preference profile for different contexts"""
    profile_id: str
    context_patterns: Dict[str, Any]
    preferred_configs: Dict[str, Any]
    usage_frequency: float
    last_used: float
    confidence_score: float

class AdaptiveConfigManager:
    """Manages adaptive configuration learning and application"""
    
    def __init__(self, config_path: str = "/home/sasha/.config/hypr"):
        self.config_path = Path(config_path)
        self.data_path = Path("/home/sasha/hyprland-project/ai_optimization/adaptive_data")
        self.data_path.mkdir(parents=True, exist_ok=True)
        
        # Database for storing learning data
        self.db_path = self.data_path / "adaptive_config.db"
        self._init_database()
        
        # Learning components
        self.context_clusterer = KMeans(n_clusters=5, random_state=42)
        self.scaler = StandardScaler()
        self.preference_profiles: Dict[str, PreferenceProfile] = {}
        
        # Configuration tracking
        self.config_history: List[ConfigurationChange] = []
        self.current_context: Optional[UserContext] = None
        self.active_profile: Optional[str] = None
        
        # Pattern recognition
        self.usage_patterns = defaultdict(list)
        self.config_effectiveness = defaultdict(float)
        
        # Learning parameters
        self.min_samples_for_learning = 10
        self.confidence_threshold = 0.7
        self.adaptation_sensitivity = 0.1
        
        # Load existing data
        self._load_preference_profiles()
        self._load_usage_patterns()
        
        logger.info("Adaptive Configuration Manager initialized")

    def _init_database(self):
        """Initialize SQLite database for storing learning data"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # User contexts table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_contexts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL,
                hour_of_day INTEGER,
                day_of_week INTEGER,
                active_applications TEXT,
                workspace_layout TEXT,
                window_count INTEGER,
                screen_brightness REAL,
                system_load REAL,
                battery_level REAL,
                is_gaming INTEGER,
                is_coding INTEGER,
                is_media_consumption INTEGER,
                activity_pattern TEXT
            )
        ''')
        
        # Configuration changes table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS config_changes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL,
                config_key TEXT,
                old_value TEXT,
                new_value TEXT,
                context_id INTEGER,
                change_source TEXT,
                FOREIGN KEY (context_id) REFERENCES user_contexts (id)
            )
        ''')
        
        # Preference profiles table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS preference_profiles (
                profile_id TEXT PRIMARY KEY,
                context_patterns TEXT,
                preferred_configs TEXT,
                usage_frequency REAL,
                last_used REAL,
                confidence_score REAL
            )
        ''')
        
        # Usage effectiveness table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS config_effectiveness (
                config_combo_hash TEXT PRIMARY KEY,
                effectiveness_score REAL,
                usage_count INTEGER,
                last_updated REAL
            )
        ''')
        
        conn.commit()
        conn.close()

    async def start_adaptive_learning(self):
        """Start the adaptive learning loop"""
        logger.info("Starting adaptive configuration learning")
        
        while True:
            try:
                # Update current context
                context = await self._capture_user_context()
                self.current_context = context
                
                # Check for configuration changes
                await self._detect_config_changes()
                
                # Learn from recent changes
                await self._update_learning_models()
                
                # Apply adaptive optimizations
                await self._apply_adaptive_optimizations()
                
                # Clean up old data
                await self._cleanup_old_data()
                
                # Sleep before next iteration
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                logger.error(f"Error in adaptive learning loop: {e}")
                await asyncio.sleep(60)

    async def _capture_user_context(self) -> UserContext:
        """Capture current user context for learning"""
        try:
            now = datetime.now()
            
            # Basic time context
            hour_of_day = now.hour
            day_of_week = now.weekday()
            
            # Active applications
            active_apps = await self._get_active_applications()
            
            # Workspace layout
            workspace_layout = await self._get_workspace_layout()
            
            # Window count
            window_count = await self._get_window_count()
            
            # Screen brightness (if available)
            screen_brightness = await self._get_screen_brightness()
            
            # System load
            with open('/proc/loadavg') as f:
                system_load = float(f.read().split()[0])
            
            # Battery level
            battery_level = await self._get_battery_level()
            
            # Activity detection
            is_gaming = await self._detect_gaming_activity(active_apps)
            is_coding = await self._detect_coding_activity(active_apps)
            is_media = await self._detect_media_activity(active_apps)
            
            # Activity pattern
            activity_pattern = await self._classify_activity_pattern(
                active_apps, window_count, hour_of_day
            )
            
            context = UserContext(
                timestamp=time.time(),
                hour_of_day=hour_of_day,
                day_of_week=day_of_week,
                active_applications=active_apps,
                workspace_layout=workspace_layout,
                window_count=window_count,
                screen_brightness=screen_brightness,
                system_load=system_load,
                battery_level=battery_level,
                is_gaming=is_gaming,
                is_coding=is_coding,
                is_media_consumption=is_media,
                user_activity_pattern=activity_pattern
            )
            
            # Store in database
            self._store_context(context)
            
            return context
            
        except Exception as e:
            logger.error(f"Error capturing user context: {e}")
            raise

    async def _get_active_applications(self) -> List[str]:
        """Get list of currently active applications"""
        try:
            result = subprocess.run(['hyprctl', 'clients'], capture_output=True, text=True)
            if result.returncode == 0:
                apps = []
                for line in result.stdout.split('\n'):
                    if 'class:' in line:
                        class_match = re.search(r'class: (\w+)', line)
                        if class_match:
                            apps.append(class_match.group(1))
                return list(set(apps))  # Remove duplicates
        except:
            pass
        return []

    async def _get_workspace_layout(self) -> str:
        """Get current workspace layout description"""
        try:
            result = subprocess.run(['hyprctl', 'workspaces'], capture_output=True, text=True)
            if result.returncode == 0:
                # Simplified layout description based on active workspaces
                workspace_count = result.stdout.count('workspace ID')
                return f"workspaces_{workspace_count}"
        except:
            pass
        return "default"

    async def _get_window_count(self) -> int:
        """Get current number of windows"""
        try:
            result = subprocess.run(['hyprctl', 'clients'], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.count('Window ')
        except:
            pass
        return 0

    async def _get_screen_brightness(self) -> float:
        """Get current screen brightness"""
        try:
            brightness_files = list(Path('/sys/class/backlight').glob('*/brightness'))
            if brightness_files:
                with open(brightness_files[0]) as f:
                    current = int(f.read().strip())
                max_file = brightness_files[0].parent / 'max_brightness'
                with open(max_file) as f:
                    max_bright = int(f.read().strip())
                return current / max_bright
        except:
            pass
        return 0.5

    async def _get_battery_level(self) -> float:
        """Get battery level"""
        try:
            with open('/sys/class/power_supply/BAT0/capacity') as f:
                return float(f.read().strip())
        except:
            pass
        return 100.0

    async def _detect_gaming_activity(self, active_apps: List[str]) -> bool:
        """Detect if user is currently gaming"""
        gaming_indicators = [
            'steam', 'lutris', 'wine', 'proton', 'gamemode',
            'minecraft', 'dota', 'csgo', 'valorant', 'league'
        ]
        return any(indicator.lower() in app.lower() for app in active_apps for indicator in gaming_indicators)

    async def _detect_coding_activity(self, active_apps: List[str]) -> bool:
        """Detect if user is currently coding"""
        coding_indicators = [
            'code', 'vim', 'neovim', 'emacs', 'intellij', 'pycharm',
            'vscode', 'atom', 'sublime', 'terminal', 'kitty', 'alacritty'
        ]
        return any(indicator.lower() in app.lower() for app in active_apps for indicator in coding_indicators)

    async def _detect_media_activity(self, active_apps: List[str]) -> bool:
        """Detect if user is consuming media"""
        media_indicators = [
            'firefox', 'chrome', 'mpv', 'vlc', 'spotify', 'discord',
            'youtube', 'netflix', 'plex', 'kodi'
        ]
        return any(indicator.lower() in app.lower() for app in active_apps for indicator in media_indicators)

    async def _classify_activity_pattern(self, active_apps: List[str], window_count: int, hour: int) -> str:
        """Classify the current activity pattern"""
        if await self._detect_gaming_activity(active_apps):
            return "gaming"
        elif await self._detect_coding_activity(active_apps):
            return "development"
        elif await self._detect_media_activity(active_apps):
            return "media"
        elif window_count > 5:
            return "multitasking"
        elif 9 <= hour <= 17:
            return "work"
        elif hour >= 22 or hour <= 6:
            return "night"
        else:
            return "general"

    def _store_context(self, context: UserContext):
        """Store user context in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO user_contexts (
                timestamp, hour_of_day, day_of_week, active_applications,
                workspace_layout, window_count, screen_brightness, system_load,
                battery_level, is_gaming, is_coding, is_media_consumption,
                activity_pattern
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            context.timestamp, context.hour_of_day, context.day_of_week,
            json.dumps(context.active_applications), context.workspace_layout,
            context.window_count, context.screen_brightness, context.system_load,
            context.battery_level, context.is_gaming, context.is_coding,
            context.is_media_consumption, context.user_activity_pattern
        ))
        
        conn.commit()
        conn.close()

    async def _detect_config_changes(self):
        """Detect configuration changes made by user"""
        try:
            current_config = await self._read_current_config()
            
            if hasattr(self, '_last_known_config'):
                for key, value in current_config.items():
                    if key in self._last_known_config:
                        old_value = self._last_known_config[key]
                        if old_value != value:
                            # Configuration changed
                            change = ConfigurationChange(
                                timestamp=time.time(),
                                config_key=key,
                                old_value=old_value,
                                new_value=value,
                                context=self.current_context,
                                change_source='user'
                            )
                            
                            self.config_history.append(change)
                            self._store_config_change(change)
                            
                            logger.info(f"Detected user config change: {key} {old_value} -> {value}")
            
            self._last_known_config = current_config
            
        except Exception as e:
            logger.error(f"Error detecting config changes: {e}")

    async def _read_current_config(self) -> Dict[str, Any]:
        """Read current Hyprland configuration"""
        config = {}
        try:
            # Read main config file
            config_file = self.config_path / "hyprland.conf"
            if config_file.exists():
                with open(config_file) as f:
                    content = f.read()
                
                # Parse configuration (simplified)
                for line in content.split('\n'):
                    line = line.strip()
                    if '=' in line and not line.startswith('#'):
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        
                        # Try to convert to appropriate type
                        if value.lower() in ('true', 'yes', '1'):
                            value = True
                        elif value.lower() in ('false', 'no', '0'):
                            value = False
                        else:
                            try:
                                value = float(value)
                                if value.is_integer():
                                    value = int(value)
                            except ValueError:
                                pass  # Keep as string
                        
                        config[key] = value
        except Exception as e:
            logger.error(f"Error reading config: {e}")
        
        return config

    def _store_config_change(self, change: ConfigurationChange):
        """Store configuration change in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # First, get the context ID
        cursor.execute(
            'SELECT id FROM user_contexts WHERE timestamp = ?',
            (change.context.timestamp,)
        )
        context_result = cursor.fetchone()
        context_id = context_result[0] if context_result else None
        
        cursor.execute('''
            INSERT INTO config_changes (
                timestamp, config_key, old_value, new_value, context_id, change_source
            ) VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            change.timestamp, change.config_key,
            json.dumps(change.old_value), json.dumps(change.new_value),
            context_id, change.change_source
        ))
        
        conn.commit()
        conn.close()

    async def _update_learning_models(self):
        """Update machine learning models with recent data"""
        if len(self.config_history) < self.min_samples_for_learning:
            return
        
        try:
            # Extract patterns from recent changes
            await self._extract_usage_patterns()
            
            # Update preference profiles
            await self._update_preference_profiles()
            
            # Train context clustering model
            await self._update_context_clustering()
            
            logger.info("Learning models updated successfully")
            
        except Exception as e:
            logger.error(f"Error updating learning models: {e}")

    async def _extract_usage_patterns(self):
        """Extract usage patterns from configuration history"""
        pattern_data = defaultdict(list)
        
        for change in self.config_history[-100:]:  # Last 100 changes
            context = change.context
            
            # Create pattern key
            pattern_key = f"{context.user_activity_pattern}_{context.hour_of_day // 4}"
            
            # Store config preference
            pattern_data[pattern_key].append({
                'config_key': change.config_key,
                'value': change.new_value,
                'timestamp': change.timestamp
            })
        
        self.usage_patterns.update(pattern_data)

    async def _update_preference_profiles(self):
        """Update user preference profiles based on learned patterns"""
        for pattern_key, changes in self.usage_patterns.items():
            if len(changes) < 3:  # Need minimum changes to create profile
                continue
            
            # Aggregate preferences
            config_preferences = defaultdict(list)
            for change in changes:
                config_preferences[change['config_key']].append(change['value'])
            
            # Calculate most common preferences
            preferred_configs = {}
            for config_key, values in config_preferences.items():
                if len(set(values)) == 1:  # All same value
                    preferred_configs[config_key] = values[0]
                else:
                    # Use most common value
                    counter = Counter(values)
                    preferred_configs[config_key] = counter.most_common(1)[0][0]
            
            # Create or update profile
            profile_id = hashlib.md5(pattern_key.encode()).hexdigest()[:8]
            
            if profile_id in self.preference_profiles:
                profile = self.preference_profiles[profile_id]
                profile.preferred_configs.update(preferred_configs)
                profile.usage_frequency += 1
                profile.last_used = time.time()
            else:
                profile = PreferenceProfile(
                    profile_id=profile_id,
                    context_patterns={'pattern_key': pattern_key},
                    preferred_configs=preferred_configs,
                    usage_frequency=len(changes),
                    last_used=time.time(),
                    confidence_score=min(len(changes) / 10, 1.0)
                )
                self.preference_profiles[profile_id] = profile

    async def _update_context_clustering(self):
        """Update context clustering model"""
        try:
            # Get recent contexts
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT hour_of_day, day_of_week, window_count, screen_brightness,
                       system_load, battery_level, is_gaming, is_coding, is_media_consumption
                FROM user_contexts
                ORDER BY timestamp DESC
                LIMIT 1000
            ''')
            
            contexts = cursor.fetchall()
            conn.close()
            
            if len(contexts) < 10:
                return
            
            # Prepare data for clustering
            X = np.array(contexts)
            X = self.scaler.fit_transform(X)
            
            # Update clustering model
            self.context_clusterer.fit(X)
            
        except Exception as e:
            logger.error(f"Error updating context clustering: {e}")

    async def _apply_adaptive_optimizations(self):
        """Apply adaptive optimizations based on current context"""
        if not self.current_context:
            return
        
        try:
            # Find matching preference profile
            best_profile = await self._find_best_profile(self.current_context)
            
            if best_profile and best_profile.confidence_score > self.confidence_threshold:
                # Apply profile configurations
                await self._apply_profile_config(best_profile)
                self.active_profile = best_profile.profile_id
                
                logger.info(f"Applied adaptive profile: {best_profile.profile_id}")
            
        except Exception as e:
            logger.error(f"Error applying adaptive optimizations: {e}")

    async def _find_best_profile(self, context: UserContext) -> Optional[PreferenceProfile]:
        """Find the best matching preference profile for current context"""
        if not self.preference_profiles:
            return None
        
        best_profile = None
        best_score = 0
        
        for profile in self.preference_profiles.values():
            # Calculate similarity score
            score = self._calculate_context_similarity(context, profile)
            
            if score > best_score:
                best_score = score
                best_profile = profile
        
        return best_profile if best_score > 0.5 else None

    def _calculate_context_similarity(self, context: UserContext, profile: PreferenceProfile) -> float:
        """Calculate similarity between current context and profile"""
        # Simple similarity calculation
        # In practice, you'd want more sophisticated similarity metrics
        
        pattern_key = profile.context_patterns.get('pattern_key', '')
        expected_pattern = f"{context.user_activity_pattern}_{context.hour_of_day // 4}"
        
        if pattern_key == expected_pattern:
            return profile.confidence_score * profile.usage_frequency / 10
        
        # Partial matches
        if context.user_activity_pattern in pattern_key:
            return profile.confidence_score * 0.7
        
        return 0.0

    async def _apply_profile_config(self, profile: PreferenceProfile):
        """Apply configuration from preference profile"""
        try:
            for config_key, value in profile.preferred_configs.items():
                await self._apply_single_config(config_key, value)
                
                # Record this as an adaptive change
                change = ConfigurationChange(
                    timestamp=time.time(),
                    config_key=config_key,
                    old_value=None,  # Would need to track current values
                    new_value=value,
                    context=self.current_context,
                    change_source='adaptive'
                )
                
                self.config_history.append(change)
                
        except Exception as e:
            logger.error(f"Error applying profile config: {e}")

    async def _apply_single_config(self, config_key: str, value: Any):
        """Apply a single configuration change"""
        try:
            # Convert value to string format for hyprctl
            if isinstance(value, bool):
                str_value = 'yes' if value else 'no'
            else:
                str_value = str(value)
            
            # Apply via hyprctl
            cmd = ['hyprctl', 'keyword', config_key, str_value]
            subprocess.run(cmd, check=True, capture_output=True)
            
        except subprocess.CalledProcessError as e:
            logger.warning(f"Failed to apply config {config_key}={value}: {e}")

    async def _cleanup_old_data(self):
        """Clean up old learning data to prevent database bloat"""
        try:
            cutoff_time = time.time() - (30 * 24 * 3600)  # 30 days ago
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Clean old contexts
            cursor.execute('DELETE FROM user_contexts WHERE timestamp < ?', (cutoff_time,))
            
            # Clean old config changes
            cursor.execute('DELETE FROM config_changes WHERE timestamp < ?', (cutoff_time,))
            
            conn.commit()
            conn.close()
            
            # Clean in-memory data
            self.config_history = [
                change for change in self.config_history
                if change.timestamp > cutoff_time
            ]
            
        except Exception as e:
            logger.error(f"Error cleaning up old data: {e}")

    def _load_preference_profiles(self):
        """Load existing preference profiles from database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM preference_profiles')
            rows = cursor.fetchall()
            
            for row in rows:
                profile_id, context_patterns, preferred_configs, usage_frequency, last_used, confidence_score = row
                
                profile = PreferenceProfile(
                    profile_id=profile_id,
                    context_patterns=json.loads(context_patterns),
                    preferred_configs=json.loads(preferred_configs),
                    usage_frequency=usage_frequency,
                    last_used=last_used,
                    confidence_score=confidence_score
                )
                
                self.preference_profiles[profile_id] = profile
            
            conn.close()
            logger.info(f"Loaded {len(self.preference_profiles)} preference profiles")
            
        except Exception as e:
            logger.error(f"Error loading preference profiles: {e}")

    def _load_usage_patterns(self):
        """Load usage patterns from database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Load recent config changes to rebuild patterns
            cursor.execute('''
                SELECT cc.config_key, cc.new_value, cc.timestamp, uc.activity_pattern, uc.hour_of_day
                FROM config_changes cc
                JOIN user_contexts uc ON cc.context_id = uc.id
                WHERE cc.timestamp > ?
                ORDER BY cc.timestamp DESC
                LIMIT 500
            ''', (time.time() - 7 * 24 * 3600,))  # Last 7 days
            
            rows = cursor.fetchall()
            
            for config_key, new_value, timestamp, activity_pattern, hour_of_day in rows:
                pattern_key = f"{activity_pattern}_{hour_of_day // 4}"
                self.usage_patterns[pattern_key].append({
                    'config_key': config_key,
                    'value': json.loads(new_value),
                    'timestamp': timestamp
                })
            
            conn.close()
            
        except Exception as e:
            logger.error(f"Error loading usage patterns: {e}")

    def save_preference_profiles(self):
        """Save current preference profiles to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Clear existing profiles
            cursor.execute('DELETE FROM preference_profiles')
            
            # Insert current profiles
            for profile in self.preference_profiles.values():
                cursor.execute('''
                    INSERT INTO preference_profiles 
                    (profile_id, context_patterns, preferred_configs, usage_frequency, last_used, confidence_score)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    profile.profile_id,
                    json.dumps(profile.context_patterns),
                    json.dumps(profile.preferred_configs),
                    profile.usage_frequency,
                    profile.last_used,
                    profile.confidence_score
                ))
            
            conn.commit()
            conn.close()
            
            logger.info("Preference profiles saved successfully")
            
        except Exception as e:
            logger.error(f"Error saving preference profiles: {e}")

    async def get_adaptation_report(self) -> Dict[str, Any]:
        """Generate adaptive configuration report"""
        report = {
            "timestamp": datetime.now().isoformat(),
            "active_profile": self.active_profile,
            "total_profiles": len(self.preference_profiles),
            "learning_data": {
                "config_changes": len(self.config_history),
                "usage_patterns": len(self.usage_patterns),
                "contexts_captured": await self._count_contexts()
            },
            "current_context": asdict(self.current_context) if self.current_context else None,
            "top_patterns": list(self.usage_patterns.keys())[:5],
            "adaptation_stats": {
                "adaptations_applied": len([c for c in self.config_history if c.change_source == 'adaptive']),
                "user_overrides": len([c for c in self.config_history if c.change_source == 'user']),
                "confidence_threshold": self.confidence_threshold
            }
        }
        
        return report

    async def _count_contexts(self) -> int:
        """Count total contexts captured"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM user_contexts')
            count = cursor.fetchone()[0]
            conn.close()
            return count
        except:
            return 0

async def main():
    """Main entry point for adaptive config manager"""
    manager = AdaptiveConfigManager()
    
    # Start adaptive learning
    await manager.start_adaptive_learning()

if __name__ == "__main__":
    asyncio.run(main())
