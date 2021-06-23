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
    echo "multi-git-status `multi-git-status --version`"
    mlr --version
    echo "daff `daff version`"
    fsql --version
    simple-http-server --version
    gitql --version
    echo "asdf `asdf --version`"
    asdf current direnv | sed 's/^/  /'
    asdf current deno | sed 's/^/  /'
    asdf current zoxide | sed 's/^/  /'
    asdf current exa | sed 's/^/  /'
    asdf current broot | sed 's/^/  /'
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
    export UDD_VERSION=`curl -s https://api.github.com/repos/hayd/deno-udd/tags | jq '.[0].name' -r`
    deno install -A -f -n udd --quiet https://deno.land/x/udd@${UDD_VERSION}/main.ts

# Install the named plugin (or update it if it's already installed) and its latest stable version
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

# Install the named plugin, its latest stable release, and then set it as the global version
setup-asdf-plugin-global plugin src="": (setup-asdf-plugin plugin src)
    asdf global {{plugin}} latest

# Install common data engineering tools such Miller and daff from GitHub
setup-data-engr: 
    #!/bin/bash    
    set -euo pipefail
    just setup-github-binary-latest johnkerl/miller mlr.linux.x86_64 {{userBinariesHome}}/mlr
    just setup-github-binary-latest-pipe xo/usql 'usql-${ASSET_VERSION:1}-linux-amd64.tar.bz2' 'tar -xj -C {{userBinariesHome}} usql'
    curl -Ls "https://github.com/netspective-studios/redistributables/raw/master/linux/daff-1.3.46-haxe2cpp-amd64-debug" > {{userBinariesHome}}/daff
    chmod +x {{userBinariesHome}}/daff

# Install database admin tools for PostgreSQL
setup-db-admin-postgres: 
    just setup-github-binary-latest-pipe lesovsky/pgcenter 'pgcenter_${ASSET_VERSION:1}_linux_amd64.tar.gz' 'tar -xz -C {{userBinariesHome}} pgcenter'

# Install database admin tools for various engines just as PostgreSQL
setup-db-admin: setup-db-admin-postgres

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
    curl -Ls "https://raw.githubusercontent.com/fboender/multi-git-status/master/mgitstatus" > {{userBinariesHome}}/git-mgitstatus
    chmod +x {{userBinariesHome}}/git-mgitstatus
    curl -Ls "https://raw.githubusercontent.com/kamranahmedse/git-standup/master/git-standup" > {{userBinariesHome}}/git-standup
    chmod +x {{userBinariesHome}}/git-standup
    just setup-github-binary-latest-cmd filhodanuvem/gitql 'gitql-linux64.zip' 'unzip -o -d {{userBinariesHome}} -qq $ASSET_TMP'
    chmod +x {{userBinariesHome}}/gitql
    # allow use through 'git query' instead of just 'gitql':
    rm -f {{userBinariesHome}}/git-query
    ln -s {{userBinariesHome}}/gitql {{userBinariesHome}}/git-query

# Install default assets
setup: setup-jq setup-ipm setup-deno setup-data-engr
    #!/bin/bash
    set -euo pipefail
    just setup-github-binary-latest-pipe kashav/fsql 'fsql-${ASSET_VERSION:1}-linux-amd64.tar.gz' 'tar -xz -C {{userBinariesHome}} --strip-components=1 linux-amd64/fsql'
    just setup-github-binary-latest TheWaWaR/simple-http-server 'x86_64-unknown-linux-musl-simple-http-server' {{userBinariesHome}}/simple-http-server
    denoStdLibVersion=`curl -s https://api.github.com/repos/denoland/deno_std/releases | jq '.[0].name' -r`
    deno install --allow-net --allow-read --quiet --force --name file-server https://deno.land/std@${denoStdLibVersion}/http/file_server.ts

_execute-and-report cmd:
    #!/bin/bash
    # run command and redirect stdout to /dev/null, stderr to stdout
    result=`{{cmd}} 2>&1 1>/dev/null`
    if [ -z "$result" ]; then
        echo "[{{cmd}}] done"
    else
        echo "[{{cmd}}] $result"
    fi

# Perform routine maintenance
maintain:
    #!/bin/bash
    # run updates and redirect stdout to /dev/null, stderr to stdout
    just _execute-and-report 'chezmoi update'
    just _execute-and-report 'asdf update'
    just _execute-and-report 'asdf plugin update --all'
    just _execute-and-report 'just setup'
    just _execute-and-report 'just setup-asdf-plugins-typical'
    echo "Run 'z4h update' manually for now"

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

# Download github.com/{repo}/releases/download/LATEST/{archive} and run command with $ASSET_TMP then delete (useful for .zip files)
setup-github-binary-latest-cmd repo archive cmd:
    #!/bin/bash
    set -euo pipefail
    ASSET_VERSION=`curl -s https://api.github.com/repos/{{repo}}/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
    ASSET_TMP="/tmp/{{archive}}"
    curl -Ls https://github.com/{{repo}}/releases/download/${ASSET_VERSION}/{{archive}} -o $ASSET_TMP
    {{cmd}}
    rm -f $ASSET_TMP

# Install typical asdf plugins and their latest versions (direnv, deno, git-chglog)
setup-asdf-plugins-typical:
    #!/bin/bash
    set -euo pipefail
    just setup-asdf-plugin-global zoxide https://github.com/nyrst/asdf-zoxide.git
    just setup-asdf-plugin-global exa https://github.com/nyrst/asdf-exa.git
    just setup-asdf-plugin-global broot https://github.com/cmur2/asdf-broot.git
    just setup-asdf-plugin-global git-chglog https://github.com/GoodwayGroup/asdf-git-chglog.git
