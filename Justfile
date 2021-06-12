userBinariesHome := "$HOME/bin"

# Report configuration
inspect:
    #!/bin/bash
    set -euo pipefail
    echo "userBinariesHome: {{userBinariesHome}}"

# Diagnose whether all dependencies are available
doctor:
    #!/bin/bash    
    set -euo pipefail
    echo "curl `curl --version | head -n 1 | awk '{ print $2 }'`"
    wget --version | head -n 1
    git --version
    just --version
    chezmoi --version
    echo "pass `pass version | grep -oh 'v[0-9]*\.[0-9]*\.[0-9]*'`"
    jq --version
    git-semtag --version
    mlr --version
    echo "daff `daff version`"
    fsql --version
    echo "asdf `asdf --version`"
    asdf current direnv | sed 's/^/  /'
    asdf current deno | sed 's/^/  /'
    asdf current git-chglog | sed 's/^/  /'

# Install latest version of jq JSON processor from GitHub
setup-jq: 
    #!/bin/bash    
    set -euo pipefail
    curl -s -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o {{userBinariesHome}}/jq && \
        chmod +x {{userBinariesHome}}/jq

# Install Deno dependencies such as udd
setup-deno:
    #!/bin/bash
    set -euo pipefail
    export UDD_VERSION=`curl -s https://api.github.com/repos/hayd/deno-udd/tags  | jq '.[0].name' -r`
    deno install -A -f -n udd https://deno.land/x/udd@${UDD_VERSION}/main.ts

# Install the named plugin and its latest stable version
setup-asdf-plugin plugin src="":
    #!/bin/bash
    set -euo pipefail
    if asdf plugin list | grep -q {{plugin}}; then
        echo "{{plugin}} plugin already installed"
        asdf plugin update {{plugin}}
    else
        asdf plugin add {{plugin}} {{src}}
    fi
    asdf install {{plugin}} latest

# Install common data engineering tools such Miller and daff from GitHub
setup-data-engr: 
    #!/bin/bash    
    set -euo pipefail
    just setup-github-binary-latest johnkerl/miller mlr.linux.x86_64 {{userBinariesHome}}/mlr
    just setup-github-binary-latest-pipe xo/usql 'usql-${ASSET_VERSION:1}-linux-amd64.tar.bz2' 'tar -xj -C {{userBinariesHome}} usql'
    curl -Ls "https://github.com/netspective-studios/redistributables/raw/master/linux/daff-1.3.46-haxe2cpp-amd64-debug" > {{userBinariesHome}}/daff
    chmod +x {{userBinariesHome}}/daff

# Install additional data engineering tools from GitHub
setup-data-engr-enhanced: setup-data-engr
    #!/bin/bash    
    set -euo pipefail
    just setup-github-binary-latest-pipe shenwei356/csvtk 'csvtk_linux_amd64.tar.gz' 'tar -xz -C {{userBinariesHome}} csvtk'
    just setup-github-binary-latest-pipe BurntSushi/xsv 'xsv-${ASSET_VERSION}-x86_64-unknown-linux-musl.tar.gz' 'tar -xz -C {{userBinariesHome}} xsv'
    just setup-github-binary-latest cube2222/octosql octosql-linux {{userBinariesHome}}/octosql
    just setup-github-binary-latest harelba/q q-x86_64-Linux {{userBinariesHome}}/q
    just setup-github-binary-latest TomWright/dasel dasel_linux_amd64 {{userBinariesHome}}/dasel

# Install intellectual property management (IPM, mostly Git-related) tools
setup-ipm:
    #!/bin/bash    
    set -euo pipefail
    curl -Ls "https://raw.githubusercontent.com/pnikosis/semtag/master/semtag" > {{userBinariesHome}}/git-semtag
    chmod +x {{userBinariesHome}}/git-semtag

# Install default assets
setup: setup-jq setup-ipm setup-deno setup-data-engr
    #!/bin/bash
    set -euo pipefail
    just setup-github-binary-latest-pipe kashav/fsql 'fsql-${ASSET_VERSION:1}-linux-amd64.tar.gz' 'tar -xz -C {{userBinariesHome}} --strip-components=1 linux-amd64/fsql'

# Perform routine maintenance
maintain: 
    #!/bin/bash
    chezmoi update
    z4h update
    asdf update
    asdf plugin update --all
    just setup
    just setup-asdf-plugins-typical

# Show the latest release version of the given repo
inspect-github-repo-latest-version repo:
    #!/bin/bash
    set -euo pipefail
    echo `curl -s https://api.github.com/repos/{{repo}}/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`    

# Download github.com/{repo}/releases/download/LATEST/{asset} as {dest}
setup-github-binary-latest repo asset dest:
    #!/bin/bash
    set -euo pipefail
    ASSET_VERSION=`curl -s https://api.github.com/repos/{{repo}}/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
    curl -s -L https://github.com/{{repo}}/releases/download/${ASSET_VERSION}/{{asset}} -o {{dest}} && chmod +x {{dest}}

# Download github.com/{repo}/releases/download/LATEST/{archive} and pipe to {{pipeCmd}}
setup-github-binary-latest-pipe repo archive pipeCmd:
    #!/bin/bash
    set -euo pipefail
    ASSET_VERSION=`curl -s https://api.github.com/repos/{{repo}}/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
    curl -Ls https://github.com/{{repo}}/releases/download/${ASSET_VERSION}/{{archive}} | {{pipeCmd}}

# Install typical asdf plugins and their latest versions (direnv, deno, git-chglog)
@setup-asdf-plugins-typical:
    #!/bin/bash
    set -euo pipefail
    just setup-asdf-plugin git-chglog https://github.com/GoodwayGroup/asdf-git-chglog.git
    asdf global git-chglog latest
