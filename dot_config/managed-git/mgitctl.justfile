# Prepare the managed Git workspaces home directory by creating {{path}}
# and symlinking to {{mGitConfHome}}/workspaces.justfile. Also creates a 
# directory-specific direnv .envrc file with context information so that
# other scripts know that the {{path}} is a managed Git workspaces path.

# Init a new managed git workspaces home directory in {{path}}
workspaces-init path mGitConfHome="${MANAGED_GIT_CONF_HOME:-$HOME/.config/managed-git}":
    #!/bin/bash
    set -euo pipefail
    managedGitHome="{{path}}"
    mGitConfHome="{{mGitConfHome}}" # because it could have shell interpolation
    if [ -d "$managedGitHome" ]; then
        echo "`realpath --relative-to=$(pwd) \"$managedGitHome\"` found, not recreating $managedGitHome"
    else
        mkdir -p "$managedGitHome"
        echo "`realpath --relative-to=$(pwd) \"$managedGitHome\"` not found, created $managedGitHome"
    fi
    rm -f "$managedGitHome/Justfile"
    ln -s "`realpath --relative-to=\"$managedGitHome\" \"$mGitConfHome/workspaces.justfile\"`" "$managedGitHome/Justfile"
    echo "export MANAGED_GIT_WORKSPACES_HOME=$managedGitHome" > $managedGitHome/.envrc
    direnv allow $managedGitHome/.envrc
    echo "Ready: cd `realpath --relative-to=$(pwd) \"$managedGitHome\"`"
