#!/bin/bash
# Project: Workyard Infra
#
# To create a new project:
# 1. Copy this file to a new name: cp template.sh.example my-project.sh
# 2. Fill in the variables below
# 3. The project will automatically appear in the menu (Ctrl+b D)

# Category for menu grouping (e.g., "Workyard", "Personal", "Client Work")
PROJECT_CATEGORY="Workyard"

# Project identifier (used for session name)
PROJECT_NAME="infra"

# Single character hotkey for the menu (must be unique)
PROJECT_KEY="i"

# Display name in the menu
PROJECT_DESCRIPTION="Workyard Infra"

# Root directory for the project
PROJECT_ROOT="$HOME/workspace/workyard/infra"

# Command to run in the runtime window (optional, leave empty if not needed)
PROJECT_CMD="pwd"

# Optional: Uncomment to disable specific windows
# SKIP_RUNTIME=true
