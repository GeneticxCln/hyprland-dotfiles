# 🤝 Contributing to Next-Generation Hyprland Desktop

Thank you for your interest in contributing! This project aims to be the most advanced Hyprland setup available, and your contributions help make that vision a reality.

## 🌟 **Ways to Contribute**

### 🐛 **Bug Reports**
- Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml)
- Include system information, theme used, and steps to reproduce
- Check existing issues first to avoid duplicates

### 💡 **Feature Requests**  
- Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml)
- Explain the problem you're trying to solve
- Consider offering to help with implementation

### 🎨 **Theme Contributions**
- New themes should include: Hyprland, Waybar, Rofi, Kitty, and wallpaper configs
- Follow the existing theme structure in `configs/`
- Test with the theme-switcher before submitting

### 📚 **Documentation**
- Help improve installation guides, troubleshooting, or feature documentation
- Screenshots and videos are especially valuable
- Update the wiki with new discoveries

### 💻 **Code Contributions**
- Bug fixes, performance improvements, new features
- Follow the existing code style and structure
- Add comments for complex logic

## 🚀 **Getting Started**

### **Prerequisites**
- Arch Linux or Arch-based distribution
- Git and basic shell scripting knowledge
- Test environment (VM recommended for major changes)

### **Development Setup**
```bash
# Fork the repository on GitHub
git clone https://github.com/yourusername/hyprland-project.git
cd hyprland-project

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test thoroughly

# Commit your changes
git add .
git commit -m "feat: add your feature description"

# Push to your fork
git push origin feature/your-feature-name

# Create a Pull Request on GitHub
```

## 📋 **Contribution Guidelines**

### **Code Style**
- Use 4-space indentation for scripts
- Add comments for complex logic
- Use descriptive variable names
- Follow existing naming conventions

### **Script Structure**
```bash
#!/bin/bash
# Brief description of the script
# Version: X.X

set -e  # Exit on error

# Colors and logging functions (use existing ones)
source "$(dirname "$0")/scripts/utils/common.sh"

# Main functionality here
main() {
    log "Starting feature..."
    # Implementation
    success "Feature completed!"
}

# Error handling
trap 'error "Script failed at line $LINENO"' ERR

# Execute main function
main "$@"
```

### **Theme Development**
New themes must include:
- `hyprland.conf` - Window manager configuration
- `waybar/config.jsonc` - Status bar configuration  
- `waybar/style.css` - Status bar styling
- `rofi/theme.rasi` - Application launcher theme
- `kitty/theme.conf` - Terminal colors
- Coordinated wallpaper (1920x1080 minimum)

### **Testing Requirements**
- Test on fresh Arch Linux installation
- Verify theme switching works correctly
- Test both NVIDIA and AMD systems if possible
- Document any new dependencies

## 🎯 **Priority Areas**

We especially welcome contributions in these areas:

### **🔥 High Priority**
- **AI Features Implementation** - Smart optimization, predictive maintenance
- **Mobile Integration** - Cross-platform sync, notifications
- **Gaming Optimizations** - Performance profiles, game-specific configs
- **Security Enhancements** - Privacy tools, secure defaults

### **🎨 Medium Priority**  
- **New Themes** - More theme families (Dracula variants, custom themes)
- **Wallpaper Collections** - High-quality theme-matching wallpapers
- **Installation Improvements** - Better error handling, recovery options
- **Documentation** - Video tutorials, troubleshooting guides

### **🔧 Lower Priority**
- **Code Refactoring** - Improve existing script structure
- **Performance** - Faster installation, resource optimization  
- **Accessibility** - Better color contrast, larger fonts options
- **Internationalization** - Multiple language support

## 📝 **Commit Message Format**

Use conventional commits:
```
type(scope): description

feat(themes): add dracula pro theme variant
fix(install): resolve NVIDIA driver installation issue  
docs(readme): update installation instructions
style(waybar): improve theme consistency
refactor(scripts): reorganize utility functions
test(themes): add automated theme validation
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style/formatting (no logic changes)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Build process, dependencies, etc.

## 🔍 **Review Process**

### **Pull Request Requirements**
- [ ] Clear description of changes made
- [ ] Reference related issues (if applicable)
- [ ] Testing completed on target systems
- [ ] Documentation updated (if needed)
- [ ] No conflicts with main branch

### **Review Criteria**
- **Functionality**: Does it work as intended?
- **Compatibility**: Works on supported distributions?
- **Code Quality**: Readable, maintainable code?
- **Documentation**: Changes are documented?
- **Testing**: Adequate testing performed?

## 🏷️ **Labels and Organization**

### **Issue Labels**
- `bug` - Something isn't working
- `enhancement` - New feature request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `question` - Further information requested
- `wontfix` - This will not be worked on

### **Pull Request Labels**
- `WIP` - Work in progress
- `ready for review` - Ready for maintainer review
- `needs changes` - Changes requested
- `approved` - Ready to merge

## 🎖️ **Recognition**

Contributors will be:
- Added to the README contributors section
- Mentioned in release notes
- Given credit in documentation they help create
- Invited to join the development team (for significant contributions)

## 🆘 **Getting Help**

- **Discord**: Join our community server (link coming soon)
- **GitHub Discussions**: Ask questions and share ideas
- **Issues**: Use the question template for specific problems
- **Email**: Direct contact for sensitive issues

## 📜 **Code of Conduct**

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/) Code of Conduct. By participating, you agree to uphold this code.

### **Summary**
- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment
- Report inappropriate behavior

---

## 🎉 **Thank You!**

Every contribution, no matter how small, helps make this the best Hyprland setup available. Whether you're fixing a typo, adding a theme, or implementing a major feature - your work matters!

**Let's build the future of Linux desktops together!** 🚀
