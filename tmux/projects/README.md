# Tmux Project Management System

Dynamic project session management for tmux with automatic menu generation.

## Quick Start

**Open the menu:**
- Press `Ctrl+b` then `Shift+D`
- Select a project from the menu
- The session will be created (first time) or switched to (if exists)

## Project Structure

Each project has its own configuration file in this directory:

```
projects/
├── README.md              # This file
├── template.sh.example    # Template for new projects
├── crew-api.sh           # CrewAPI project config
├── core.sh               # Core project config
├── web-app.sh            # WebApp project config
└── web-app-v2.sh         # WebAppV2 project config
```

## Adding a New Project

1. **Copy the template:**
   ```bash
   cd ~/.dotfiles/tmux/projects
   cp template.sh.example my-new-project.sh
   ```

2. **Edit the configuration:**
   ```bash
   vim my-new-project.sh
   ```

3. **Set the variables:**
   - `PROJECT_NAME` - Identifier for session name (e.g., "my-project")
   - `PROJECT_KEY` - Single character hotkey (e.g., "m")
   - `PROJECT_DESCRIPTION` - Display name in menu (e.g., "My Project")
   - `PROJECT_ROOT` - Root directory path
   - `PROJECT_CMD` - Command to run in runtime window (optional)

4. **Make it executable:**
   ```bash
   chmod +x my-new-project.sh
   ```

5. **Done!** The project will automatically appear in the menu

## Project Configuration Example

```bash
#!/bin/bash
PROJECT_NAME="my-project"
PROJECT_KEY="m"
PROJECT_DESCRIPTION="My Project"
PROJECT_ROOT="$HOME/workspace/my-project"
PROJECT_CMD="npm run dev"
```

## Session Structure

Each project session includes:
- **editor** window (2 panes) - Your main workspace
- **runtime** window - Runs PROJECT_CMD
- **logs** window - Tails log files
- **shell** window - Additional terminal

## Optional Configuration

Disable specific windows by adding to your project file:

```bash
SKIP_RUNTIME=true   # No runtime window
SKIP_LOGS=true      # No logs window
SKIP_SHELL=true     # No shell window
```

## Manual Usage

Launch a project directly from command line:
```bash
~/.dotfiles/tmux/project-launcher.sh <project-name>
```

List available projects:
```bash
~/.dotfiles/tmux/project-launcher.sh
```

## Files

- **project-launcher.sh** - Creates/switches to project sessions
- **project-menu.sh** - Builds dynamic menu from projects directory
- **projects/*.sh** - Individual project configurations

## Troubleshooting

**Project doesn't appear in menu:**
- Ensure the file ends with `.sh`
- Ensure it's executable (`chmod +x`)
- Don't name it `template.sh*` (templates are excluded)
- Reload tmux config: `Ctrl+b` then `r`

**Session not created:**
- Check that PROJECT_ROOT directory exists
- Run manually to see errors: `~/.dotfiles/tmux/project-launcher.sh <project-name>`
