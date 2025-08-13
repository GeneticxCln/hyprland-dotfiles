"""
Hyprland AI Optimization System - Core Module
"""

__version__ = "1.0.0"
__author__ = "AI-Driven Hyprland Optimizer"
__description__ = "Intelligent self-healing and adaptive optimization for Hyprland"

from .ai_optimizer import AIOptimizer
from .adaptive_config import AdaptiveConfigManager
from .self_healing import SelfHealingSystem

__all__ = [
    'AIOptimizer',
    'AdaptiveConfigManager', 
    'SelfHealingSystem'
]
