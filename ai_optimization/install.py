#!/usr/bin/env python3
"""
Installation and Setup Script for Hyprland AI Optimization System
Handles dependencies, configuration, and system integration
"""

import subprocess
import sys
import os
import shutil
from pathlib import Path
import json
import logging
from typing import List, Dict, Any
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class HyprlandAIInstaller:
    """Installer for the Hyprland AI Optimization System"""
    
    def __init__(self):
        self.base_path = Path("/home/sasha/hyprland-project/ai_optimization")
        self.config_path = Path("/home/sasha/.config/hypr")
        self.service_path = Path("/home/sasha/.config/systemd/user")
        
        self.required_python_packages = [
            "asyncio", "numpy", "torch", "scikit-learn", "psutil",
            "sqlite3", "aiofiles", "pynvml"
        ]
        
        self.required_system_packages = [
            "python3-pip", "python3-venv", "nvidia-ml-py3", 
            "lm-sensors", "htop", "iotop"
        ]

    def run_installation(self, 
                         skip_deps: bool = False,
                         create_service: bool = True,
                         setup_autostart: bool = True,
                         verbose: bool = False):
        """Run complete installation process"""
        
        if verbose:
            logging.getLogger().setLevel(logging.DEBUG)
        
        logger.info("🚀 Starting Hyprland AI Optimization System Installation")
        
        try:
            # Check prerequisites
            self._check_prerequisites()
            
            # Install dependencies
            if not skip_deps:
                self._install_dependencies()
            
            # Setup directories
            self._setup_directories()
            
            # Create configuration files
            self._create_configurations()
            
            # Create systemd service
            if create_service:
                self._create_systemd_service()
            
            # Setup autostart
            if setup_autostart:
                self._setup_autostart()
            
            # Create management scripts
            self._create_management_scripts()
            
            # Final setup
            self._finalize_installation()
            
            logger.info("✅ Installation completed successfully!")
            self._print_next_steps()
            
        except Exception as e:
            logger.error(f"❌ Installation failed: {e}")
            raise

    def _check_prerequisites(self):
        """Check system prerequisites"""
        logger.info("🔍 Checking prerequisites...")
        
        # Check if running on Linux
        if sys.platform != 'linux':
            raise RuntimeError("This system is designed for Linux only")
        
        # Check if Hyprland is installed
        if not shutil.which('hyprctl'):
            raise RuntimeError("Hyprland is not installed or not in PATH")
        
        # Check Python version
        if sys.version_info < (3, 8):
            raise RuntimeError("Python 3.8+ is required")
        
        # Check if pip is available
        if not shutil.which('pip') and not shutil.which('pip3'):
            raise RuntimeError("pip is not installed")
        
        # Check disk space (need at least 500MB)
        statvfs = os.statvfs(self.base_path.parent)
        free_space = statvfs.f_frsize * statvfs.f_bavail
        if free_space < 500 * 1024 * 1024:  # 500MB
            logger.warning("Low disk space detected, installation may fail")
        
        logger.info("✅ Prerequisites check passed")

    def _install_dependencies(self):
        """Install required dependencies"""
        logger.info("📦 Installing dependencies...")
        
        # Update package lists
        logger.info("Updating package lists...")
        try:
            subprocess.run(['sudo', 'pacman', '-Sy'], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            logger.warning("Could not update package lists, continuing anyway...")
        
        # Install system packages
        logger.info("Installing system packages...")
        for package in self.required_system_packages:
            try:
                result = subprocess.run(
                    ['pacman', '-Q', package], 
                    capture_output=True, 
                    text=True
                )
                if result.returncode == 0:
                    logger.debug(f"Package {package} already installed")
                    continue
                    
            except subprocess.CalledProcessError:
                pass
            
            logger.info(f"Installing {package}...")
            try:
                subprocess.run(['sudo', 'pacman', '-S', '--noconfirm', package], check=True)
            except subprocess.CalledProcessError as e:
                logger.warning(f"Could not install {package}: {e}")
        
        # Create virtual environment
        venv_path = self.base_path / "venv"
        if not venv_path.exists():
            logger.info("Creating Python virtual environment...")
            subprocess.run([sys.executable, '-m', 'venv', str(venv_path)], check=True)
        
        # Install Python packages
        pip_path = venv_path / "bin" / "pip"
        logger.info("Installing Python packages...")
        
        # Upgrade pip first
        subprocess.run([str(pip_path), 'install', '--upgrade', 'pip'], check=True)
        
        # Install packages
        packages_to_install = [
            'torch', 'numpy', 'scikit-learn', 'psutil', 
            'aiofiles', 'asyncio', 'sqlite3'
        ]
        
        try:
            # Try to install nvidia-ml-py3 (may fail if no NVIDIA GPU)
            subprocess.run([str(pip_path), 'install', 'nvidia-ml-py3'], 
                         check=True, capture_output=True)
            packages_to_install.append('nvidia-ml-py3')
        except subprocess.CalledProcessError:
            logger.warning("Could not install nvidia-ml-py3, GPU monitoring may be limited")
        
        for package in packages_to_install:
            logger.info(f"Installing Python package: {package}")
            try:
                subprocess.run([str(pip_path), 'install', package], check=True)
            except subprocess.CalledProcessError as e:
                logger.error(f"Failed to install {package}: {e}")
                raise
        
        logger.info("✅ Dependencies installed")

    def _setup_directories(self):
        """Setup required directories"""
        logger.info("📁 Setting up directories...")
        
        directories = [
            self.base_path / "logs",
            self.base_path / "models", 
            self.base_path / "adaptive_data",
            self.base_path / "healing_data",
            self.base_path / "config",
            self.service_path
        ]
        
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
            logger.debug(f"Created directory: {directory}")
        
        logger.info("✅ Directories setup complete")

    def _create_configurations(self):
        """Create configuration files"""
        logger.info("⚙️ Creating configuration files...")
        
        # Main configuration
        config = {
            "ai_optimizer": {
                "enabled": True,
                "optimization_interval": 30,
                "learning_rate": 0.001,
                "conservative_mode": False
            },
            "adaptive_config": {
                "enabled": True,
                "learning_interval": 60,
                "confidence_threshold": 0.7,
                "min_samples": 10
            },
            "self_healing": {
                "enabled": True,
                "monitoring_interval": 30,
                "auto_fix_enabled": True,
                "max_fix_attempts": 3
            },
            "system": {
                "log_level": "INFO",
                "max_log_size": "100MB",
                "data_retention_days": 30
            }
        }
        
        config_file = self.base_path / "config" / "settings.json"
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        logger.info(f"✅ Configuration created: {config_file}")

    def _create_systemd_service(self):
        """Create systemd user service"""
        logger.info("🔧 Creating systemd service...")
        
        service_content = f"""[Unit]
Description=Hyprland AI Optimization System
After=graphical-session.target

[Service]
Type=exec
ExecStart={self.base_path}/venv/bin/python {self.base_path}/main_orchestrator.py --daemon
Restart=always
RestartSec=10
Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0

[Install]
WantedBy=default.target
"""
        
        service_file = self.service_path / "hyprland-ai-optimization.service"
        with open(service_file, 'w') as f:
            f.write(service_content)
        
        # Reload systemd and enable service
        try:
            subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
            subprocess.run(['systemctl', '--user', 'enable', 'hyprland-ai-optimization'], check=True)
            logger.info("✅ Systemd service created and enabled")
        except subprocess.CalledProcessError as e:
            logger.warning(f"Could not enable systemd service: {e}")

    def _setup_autostart(self):
        """Setup autostart integration"""
        logger.info("🔄 Setting up autostart...")
        
        # Create desktop entry for autostart
        autostart_dir = Path.home() / ".config" / "autostart"
        autostart_dir.mkdir(exist_ok=True)
        
        desktop_entry = f"""[Desktop Entry]
Type=Application
Name=Hyprland AI Optimization
Comment=AI-driven optimization for Hyprland
Exec={self.base_path}/venv/bin/python {self.base_path}/main_orchestrator.py
Icon=preferences-system
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
"""
        
        desktop_file = autostart_dir / "hyprland-ai-optimization.desktop"
        with open(desktop_file, 'w') as f:
            f.write(desktop_entry)
        
        logger.info("✅ Autostart configured")

    def _create_management_scripts(self):
        """Create management scripts"""
        logger.info("📜 Creating management scripts...")
        
        # Create start script
        start_script = f"""#!/bin/bash
# Start Hyprland AI Optimization System
cd {self.base_path}
source venv/bin/activate
python main_orchestrator.py "$@"
"""
        
        start_file = self.base_path / "start.sh"
        with open(start_file, 'w') as f:
            f.write(start_script)
        start_file.chmod(0o755)
        
        # Create status script
        status_script = f"""#!/bin/bash
# Get Hyprland AI Optimization System status
cd {self.base_path}
source venv/bin/activate
python main_orchestrator.py --status
"""
        
        status_file = self.base_path / "status.sh"
        with open(status_file, 'w') as f:
            f.write(status_script)
        status_file.chmod(0o755)
        
        # Create stop script
        stop_script = f"""#!/bin/bash
# Stop Hyprland AI Optimization System
systemctl --user stop hyprland-ai-optimization
pkill -f "main_orchestrator.py"
"""
        
        stop_file = self.base_path / "stop.sh"
        with open(stop_file, 'w') as f:
            f.write(stop_script)
        stop_file.chmod(0o755)
        
        logger.info("✅ Management scripts created")

    def _finalize_installation(self):
        """Finalize installation"""
        logger.info("🎯 Finalizing installation...")
        
        # Create __init__.py files
        init_files = [
            self.base_path / "core" / "__init__.py",
            self.base_path / "__init__.py"
        ]
        
        for init_file in init_files:
            init_file.touch()
        
        # Set permissions
        for script in ["start.sh", "status.sh", "stop.sh"]:
            script_path = self.base_path / script
            if script_path.exists():
                script_path.chmod(0o755)
        
        # Create symlinks in user bin if it exists
        user_bin = Path.home() / ".local" / "bin"
        if user_bin.exists():
            symlinks = [
                ("hypr-ai-start", "start.sh"),
                ("hypr-ai-status", "status.sh"), 
                ("hypr-ai-stop", "stop.sh")
            ]
            
            for link_name, target in symlinks:
                link_path = user_bin / link_name
                target_path = self.base_path / target
                
                if link_path.exists():
                    link_path.unlink()
                
                try:
                    link_path.symlink_to(target_path)
                    logger.debug(f"Created symlink: {link_name}")
                except OSError:
                    logger.warning(f"Could not create symlink: {link_name}")
        
        logger.info("✅ Installation finalized")

    def _print_next_steps(self):
        """Print next steps for user"""
        print("\n" + "="*60)
        print("🎉 INSTALLATION COMPLETE!")
        print("="*60)
        print("\n📋 Next Steps:")
        print(f"   1. Start the system: cd {self.base_path} && ./start.sh")
        print(f"   2. Check status: ./status.sh")
        print(f"   3. View logs: tail -f logs/orchestrator.log")
        print("\n🔧 Management Commands:")
        if (Path.home() / ".local" / "bin").exists():
            print("   • hypr-ai-start  - Start the system")
            print("   • hypr-ai-status - Check status")
            print("   • hypr-ai-stop   - Stop the system")
        else:
            print(f"   • {self.base_path}/start.sh  - Start the system")
            print(f"   • {self.base_path}/status.sh - Check status") 
            print(f"   • {self.base_path}/stop.sh   - Stop the system")
        
        print("\n📊 Monitoring:")
        print(f"   • systemctl --user status hyprland-ai-optimization")
        print(f"   • journalctl --user -fu hyprland-ai-optimization")
        
        print("\n⚙️ Configuration:")
        print(f"   • Edit: {self.base_path}/config/settings.json")
        
        print("\n🤖 The AI system will:")
        print("   • Learn your usage patterns automatically")
        print("   • Optimize performance based on workload")
        print("   • Self-heal system issues")
        print("   • Adapt to your preferences over time")
        
        print("\n⚠️  Note: The system needs to run for a few hours to build")
        print("   its learning models and start providing optimizations.")
        print("\n" + "="*60)

    def uninstall(self):
        """Uninstall the AI optimization system"""
        logger.info("🗑️ Uninstalling Hyprland AI Optimization System...")
        
        try:
            # Stop and disable service
            subprocess.run(['systemctl', '--user', 'stop', 'hyprland-ai-optimization'], 
                         capture_output=True)
            subprocess.run(['systemctl', '--user', 'disable', 'hyprland-ai-optimization'], 
                         capture_output=True)
            
            # Remove service file
            service_file = self.service_path / "hyprland-ai-optimization.service"
            if service_file.exists():
                service_file.unlink()
            
            # Remove autostart entry
            autostart_file = Path.home() / ".config" / "autostart" / "hyprland-ai-optimization.desktop"
            if autostart_file.exists():
                autostart_file.unlink()
            
            # Remove symlinks
            user_bin = Path.home() / ".local" / "bin"
            if user_bin.exists():
                for link_name in ["hypr-ai-start", "hypr-ai-status", "hypr-ai-stop"]:
                    link_path = user_bin / link_name
                    if link_path.exists():
                        link_path.unlink()
            
            # Remove installation directory (ask user first)
            if self.base_path.exists():
                response = input(f"Remove all data in {self.base_path}? [y/N]: ")
                if response.lower() in ['y', 'yes']:
                    shutil.rmtree(self.base_path)
                    logger.info("✅ Installation directory removed")
                else:
                    logger.info("💾 Data preserved")
            
            logger.info("✅ Uninstallation complete")
            
        except Exception as e:
            logger.error(f"Error during uninstallation: {e}")
            raise

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Hyprland AI Optimization System Installer")
    parser.add_argument("--skip-deps", action="store_true", help="Skip dependency installation")
    parser.add_argument("--no-service", action="store_true", help="Don't create systemd service")
    parser.add_argument("--no-autostart", action="store_true", help="Don't setup autostart")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--uninstall", action="store_true", help="Uninstall the system")
    
    args = parser.parse_args()
    
    installer = HyprlandAIInstaller()
    
    try:
        if args.uninstall:
            installer.uninstall()
        else:
            installer.run_installation(
                skip_deps=args.skip_deps,
                create_service=not args.no_service,
                setup_autostart=not args.no_autostart,
                verbose=args.verbose
            )
    except KeyboardInterrupt:
        logger.info("Installation cancelled by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Installation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
