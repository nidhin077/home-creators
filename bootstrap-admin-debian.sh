#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# NSH_ prefix should used for all Netspective Studios Home (NSH) packages

export NSH_IS_WSL=0
if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
    if [[ "$(< /proc/version)" == *@(WSL2)* ]]; then
        export NSH_IS_WSL=2
    else
        export NSH_IS_WSL=1
    fi
fi

# TODO: check if non-Debian (e.g. non-Ubuntu) based OS and stop; later we'll add ability for non-Debian distros

sudo apt-get -qq update
sudo apt-get -y -qq install curl git jq pass unzip bzip2 tree make bsdmainutils time
curl -sSL https://git.io/git-extras-setup | sudo bash /dev/stdin

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $HOME/bin
ASDF_VERSION=`curl -s https://api.github.com/repos/asdf-vm/asdf/tags | jq '.[0].name' -r` \
    bash -c 'git -c advice.detachedHead=false clone --quiet https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION}'
. $HOME/.asdf/asdf.sh
for pkg in direnv deno; do asdf plugin-add $pkg; asdf install $pkg latest; asdf global $pkg latest; done

export CHEZMOI_CONF=~/.config/chezmoi/chezmoi.toml
mkdir -p `dirname $CHEZMOI_CONF`
cat << EOF > $CHEZMOI_CONF
[data]
    [data.git.user]
        name = "Shahid N. Shah"
        email = "user@email.com"
    [data.git.credential.helper.cache]
        timeout = 2592000 # 30 days

    # add [data.github.user.prime] if you want the following in .gitconfig:
    # [url "https://gitHubUserHandle:PERSONAL_ACCESS_TOKEN_VALUE@github.com"]
    #    insteadOf = https://github.com    
    # [data.github.user.prime]
    #    id = 'gitHubUserHandle'
    #    pat = 'PERSONAL_ACCESS_TOKEN_VALUE'
    #    insteadof_in_gitconfig = "yes"        
EOF
chmod 0600 $CHEZMOI_CONF

echo "******************************************************************"
echo "** Netspective Studios Home (NSH) admin boostrap complete.      **"
echo "** Installed:                                                   **"
echo "**   - curl, git, jq, pass, unzip, bzip2, tree, and make        **"
echo "**   - asdf (version manager for languages, runtimes, etc.)     **"
echo "**   - just (command runner)                                    **"
echo "**   - deno (V8 runtime for JavaScript and TypeScript)          **"
echo "**   - direnv (per-directory environment variables loader)      **"
echo "** ------------------------------------------------------------ **"
echo "** NSH_IS_WSL: $NSH_IS_WSL                                                **"
echo "** ------------------------------------------------------------ **"
echo "** Continue installation by editing chezmoi config:             **"
echo '**   vi ~/.config/chezmoi/chezmoi.toml                          **'
echo "******************************************************************"
