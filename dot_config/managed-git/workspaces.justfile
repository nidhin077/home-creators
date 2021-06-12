# Report configuration
inspect:
    #!/bin/bash
    set -euo pipefail
    tree -d -L 4 `pwd`

# Clone or pull gitURL from a managed git supplier's HTTP endpoint
repo-ensure gitURL context="interactive":
    #!/bin/bash
    set -euo pipefail
    workspaceHome={{gitURL}}
    if [ -d "$workspaceHome" ]; then
        echo "`basename $workspaceHome` found, pulling latest in `realpath --relative-to=. $workspaceHome`"
        git -C "$workspaceHome" pull --quiet 
    else
        mkdir -p `dirname "$workspaceHome"`
        curl -Lsfo /dev/null https://{{gitURL}} || (echo "https://{{gitURL}} is not a valid URL"; exit 1)
        git clone https://{{gitURL}} "$workspaceHome" --quiet
        if [ -f "$workspaceHome/.envrc" ]; then
            direnv allow "$workspaceHome"
        fi
        echo "`basename $workspaceHome` not found, cloned `realpath --relative-to=. \"$workspaceHome\"`"
    fi
    case "{{context}}" in
        interactive)
            echo "Ready: cd $workspaceHome"
            find "$workspaceHome" -type f -name "*.code-workspace" -printf "   or: just vscws-repos-ensure-ref `realpath --relative-to=. \"$workspaceHome\"`/%P\n"
            ;;

        batch) ;; # nothing special required
        *) echo -n "unknown context: {{context}}" ;;
    esac

# List all *.code-workspace files available
vscws-inspect in=".":
    #!/bin/bash
    set -euo pipefail
    find {{in}} -type f -name "*.code-workspace" -exec realpath --relative-to=. {} \;

# List all *.code-workspace files available and generate code to clone/pull content
vscws-inspect-ensure in=".":
    #!/bin/bash
    set -euo pipefail
    find {{in}} -type f -name "*.code-workspace" -printf "just vscws-repos-ensure-ref %P\n" 

# List all managed Git suppliers (e.g. github.com) referenced in all VS Code *.code-workspace files
vscws-inspect-git-managers in=".":
    #!/bin/bash
    set -euo pipefail
    find {{in}} -type f -name "*.code-workspace" -printf "cat %p | jq -r '.folders[] | .path | split(\"/\")[0]'\n" | sh | sort | uniq

# List all folders for which Git servers are referenced in a single VS Code *.code-workspace file
vscws-inspect-git-managers-single vscws:
    #!/bin/bash
    set -euo pipefail
    cat {{vscws}} | jq -r '.folders[] | .path | split("/")[0]' | sort | uniq

# List file counts for all folders in a VS Code *.code-workspace file
vscws-inspect-path-files-count vscws:
    #!/bin/bash
    set -euo pipefail
    cat {{vscws}} | jq -r '.folders[] | "FC=`find \(.path)/* -type f | wc -l`; echo \"$FC\t\(.path)\""' | sh

# List path sizes for all folders in a VS Code *.code-workspace file
vscws-inspect-path-size vscws:
    #!/bin/bash
    set -euo pipefail
    cat {{vscws}} | jq -r '.folders[] | "du -s \(.path)"' | sh

# Run 'just repo-ensure' on all folders in a VS Code *.code-workspace file
vscws-repos-ensure vscws:
    #!/bin/bash
    set -euo pipefail
    cat {{vscws}} | jq -r '.folders[] | "just repo-ensure \(.path) batch"' | sh
    
# Run 'just repo-ensure' on all folders in a VS Code *.code-workspace file and symlink the file for opening in VSC
vscws-repos-ensure-ref vscws:
    #!/bin/bash
    set -euo pipefail
    just vscws-repos-ensure {{vscws}}
    # create a symlink to the workspaces home which, when opened from VS Code
    # will be able properly access all repos properly
    vscwsRef=`basename {{vscws}}`    
    if [ -L $vscwsRef ]; then
        rm -f $vscwsRef
    fi
    ln -s {{vscws}} $vscwsRef
