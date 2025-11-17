# Contributing to SMI USB Display Ubuntu Installer

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## Code of Conduct

This project follows a simple code of conduct:
- Be respectful and considerate
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Found a bug? Help us fix it:

1. **Check existing issues** - Someone may have already reported it
2. **Create a new issue** with:
   - Clear, descriptive title
   - Step-by-step reproduction instructions
   - Expected vs actual behavior
   - System information:
     ```bash
     uname -r                    # Kernel version
     lsb_release -a              # Ubuntu version
     dkms status | grep evdi     # EVDI status
     ```
   - Relevant log outputs
   - Screenshots if applicable

### Suggesting Enhancements

Have an idea? We'd love to hear it:

1. **Check existing issues** - It might already be planned
2. **Create an enhancement issue** with:
   - Clear description of the feature
   - Use case / problem it solves
   - Proposed solution (if any)
   - Alternative solutions considered

### Improving Documentation

Documentation improvements are always welcome:
- Fix typos or unclear instructions
- Add missing information
- Improve examples
- Translate to other languages

### Testing

Help test on different configurations:
- Different Ubuntu versions
- Different kernel versions
- Different hardware
- Edge cases and unusual setups

## Getting Started

### Development Setup

1. **Fork the repository**

2. **Clone your fork:**
```bash
git clone https://github.com/YOUR_USERNAME/smi-usb-display-ubuntu.git
cd smi-usb-display-ubuntu
```

3. **Create a branch:**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### Testing Your Changes

Before submitting:

1. **Test the installation script:**
```bash
# In a VM or test system
sudo bash install_smi_fixed.sh
```

2. **Verify functionality:**
```bash
lsmod | grep evdi
systemctl status smiusbdisplay.service
# Connect USB display and test
```

3. **Test error conditions:**
- Missing dependencies
- Already installed scenarios
- Secure Boot enabled/disabled

4. **Review your changes:**
```bash
git diff
shellcheck install_smi_fixed.sh  # If you have shellcheck
```

## Development Process

### Branching Strategy

- `main` - Stable releases
- `develop` - Integration branch for next release
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH**
- Major: Breaking changes
- Minor: New features, backward compatible
- Patch: Bug fixes

## Reporting Bugs

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**System Information:**
- Ubuntu version: [e.g., 24.04]
- Kernel version: [e.g., 6.14.0-35]
- EVDI version: [e.g., 1.14.11]
- Secure Boot: [enabled/disabled]

**Logs:**
```
# Paste relevant logs here
sudo journalctl -u smiusbdisplay.service -n 50
```

**Additional context**
Any other relevant information.
```

## Suggesting Enhancements

### Enhancement Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem. Ex. I'm frustrated when [...]

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions or features you've considered.

**Additional context**
Any other context, screenshots, or examples.
```

## Pull Request Process

### Before Submitting

1. **Update documentation** if needed
2. **Test thoroughly** on your system
3. **Update CHANGELOG.md** with your changes
4. **Ensure no merge conflicts** with main branch

### PR Guidelines

1. **Title:** Clear, descriptive title
   - Good: "Fix EVDI module loading on kernel 6.15"
   - Bad: "Fix bug"

2. **Description:** Include:
   - What changes were made
   - Why they were made
   - How to test
   - Related issues (Fixes #123)

3. **Commits:**
   - Atomic commits (one logical change per commit)
   - Clear commit messages
   - Sign your commits if possible

4. **Review:**
   - Respond to feedback promptly
   - Make requested changes
   - Keep discussion professional

### PR Template

```markdown
## Description
Brief description of changes.

## Motivation and Context
Why is this change needed? What problem does it solve?

## How Has This Been Tested?
Describe your testing process.

## Types of Changes
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have tested my changes
- [ ] I have updated the documentation accordingly
- [ ] I have updated CHANGELOG.md
- [ ] My changes generate no new warnings
- [ ] I have added tests (if applicable)

## Related Issues
Fixes #(issue number)
```

## Style Guidelines

### Bash Script Style

1. **Use shellcheck:**
```bash
shellcheck install_smi_fixed.sh
```

2. **Error handling:**
```bash
set -e  # Exit on error
# OR handle errors explicitly
command || handle_error
```

3. **Functions:**
```bash
function_name() {
    local variable="value"
    # Function body
}
```

4. **Comments:**
```bash
# Explain WHY, not WHAT
# Good: "EVDI needs to be unloaded before patching"
# Bad:  "Unload EVDI"
```

5. **Variables:**
```bash
CONSTANT_VALUE="value"  # Constants in CAPS
local_variable="value"  # Local variables lowercase
```

### Documentation Style

1. **Markdown:**
   - Use headers hierarchically
   - Include code blocks with syntax highlighting
   - Add links where helpful
   - Use tables for structured data

2. **Code examples:**
   - Always show complete, working examples
   - Include expected output
   - Add comments to explain complex parts

3. **Writing:**
   - Clear, concise language
   - Active voice
   - Present tense
   - Second person for instructions

## Additional Resources

- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Markdown Guide](https://www.markdownguide.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

## Questions?

- Open a discussion on GitHub
- Check existing documentation
- Review closed issues for similar questions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
