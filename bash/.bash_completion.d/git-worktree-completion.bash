#!/usr/bin/env bash
# Bash completion for git worktree commands

_git_worktree_branches() {
    local branches=""

    # Get list of worktrees (exclude main repo path, get branch names)
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local repo_root=$(dirname "$(git rev-parse --git-common-dir 2>/dev/null)")
        local current_path=""
        local branch=""

        # Extract branch names from worktrees
        while IFS= read -r line; do
            if [[ $line == worktree\ * ]]; then
                current_path="${line#worktree }"
            elif [[ $line == branch\ * ]] && [[ "$current_path" != "$repo_root" ]]; then
                branch="${line#branch refs/heads/}"
                branches="$branches $branch"
            fi
        done < <(git worktree list --porcelain 2>/dev/null)
    fi

    echo "$branches"
}

_git_worktree_switch_docker() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Get worktree branches
    local branches=$(_git_worktree_branches)

    # Add special keywords
    local keywords="main status"

    # Generate completions
    COMPREPLY=($(compgen -W "$keywords $branches" -- "$cur"))
}

# For direct script invocation: git-worktree-switch-docker <TAB>
complete -F _git_worktree_switch_docker git-worktree-switch-docker

# For git alias: git wt-docker <TAB>
# Git completion expects function named _git_<alias> with underscores
_git_wt_docker() {
    # When called as git alias, COMP_WORDS is: [git, wt-docker, ...]
    # We want to complete the argument after wt-docker
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Get worktree branches
    local branches=$(_git_worktree_branches)

    # Add special keywords
    local keywords="main status"

    # Generate completions
    COMPREPLY=($(compgen -W "$keywords $branches" -- "$cur"))
}

# For direct script invocation: git-worktree-remove <TAB>
_git_worktree_remove() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Get worktree branch names (reuse helper function)
    local branches=$(_git_worktree_branches)

    # Generate completions
    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}

complete -F _git_worktree_remove git-worktree-remove

# For git alias: git wt-rm <TAB>
# Complete with branch names (wrapper script converts to paths)
_git_wt_rm() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Get worktree branch names (reuse helper function)
    local branches=$(_git_worktree_branches)

    # Generate completions
    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}

# For git alias: git wt-cleanup <TAB>
# Complete with options: --dry-run, --all
_git_wt_cleanup() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local options="--dry-run --all -h --help"

    COMPREPLY=($(compgen -W "$options" -- "$cur"))
}

# For git alias: git wt-create <TAB>
# Complete second argument with branch names (base branch)
_git_wt_create() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    # First argument: new branch name (no completion)
    # Second argument: base branch (complete with existing branches)
    if [ "$COMP_CWORD" -eq 2 ]; then
        # Complete with local branch names
        local branches=""
        if git rev-parse --git-dir &>/dev/null 2>&1; then
            branches=$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
        fi
        COMPREPLY=($(compgen -W "$branches" -- "$cur"))
    elif [ "$COMP_CWORD" -eq 1 ]; then
        # First arg - check for help flag
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
        fi
    fi
}

# Aliases for git wt-list and git wt-ls (no arguments needed, but support -h)
_git_wt_list() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
    fi
}

_git_wt_ls() {
    _git_wt_list
}
