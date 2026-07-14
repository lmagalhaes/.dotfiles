# Tmux Project Management System

Dynamic project session management for tmux with automatic menu generation.

## Quick Start

**Open the menu:**
- Press `Ctrl+b` then `Shift+D`
- Select a project from the menu
- The session will be created (first time) or switched to (if exists)

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
   - `PROJECT_CATEGORY` - Group label in menu (e.g., "Workyard", "Personal")
   - `PROJECT_ROOT` - Root directory path

4. **Make it executable:**
   ```bash
   chmod +x my-new-project.sh
   ```

5. **Done!** The project will automatically appear in the menu

## Project Configuration Example

```bash
#!/bin/bash
PROJECT_CATEGORY="Personal"
PROJECT_NAME="my-project"
PROJECT_KEY="m"
PROJECT_DESCRIPTION="My Project"
PROJECT_ROOT="$HOME/workspace/my-project"
```

## Session Structure

Each project session is a single window named `editor` with 2 horizontal panes.
On subsequent opens, the existing session is reactivated as-is.

## Manual Usage

Launch a project directly from the command line:
```bash
~/.dotfiles/tmux/project-launcher.sh <project-name>
```

List available projects:
```bash
~/.dotfiles/tmux/project-launcher.sh
```

## Files

- **project-launcher.sh** - Creates/switches to project sessions
- **project-fzf.sh** - fzf-based interactive picker (`Prefix D`)
- **project-menu.sh** - Native tmux grouped menu (`Prefix P`)
- **project-preview.sh** - fzf preview pane content
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
