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
sudo apt-get -y -qq install curl git jq pass unzip bzip2 tree make bsdmainutils time gettext-base wget

OSQ_VERSION=`curl -s https://api.github.com/repos/osquery/osquery/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
OSQ_APT_CACHE=/var/cache/apt/archives
OSQ_DEB_FILE=osquery_${OSQ_VERSION}-1.linux_amd64.deb
sudo curl -sL -o $OSQ_APT_CACHE/$OSQ_DEB_FILE https://pkg.osquery.io/deb/$OSQ_DEB_FILE
sudo dpkg -i $OSQ_APT_CACHE/$OSQ_DEB_FILE

curl -sSL https://git.io/git-extras-setup | sudo bash /dev/stdin

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $HOME/bin
ASDF_DIR=$HOME/.asdf
ASDF_VERSION=`curl -s https://api.github.com/repos/asdf-vm/asdf/tags | jq '.[0].name' -r` \
    bash -c 'git -c advice.detachedHead=false clone --quiet https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch ${ASDF_VERSION}'
. $ASDF_DIR/asdf.sh
for pkg in direnv deno; do asdf plugin-add $pkg; asdf install $pkg latest; asdf global $pkg latest; done

export CHEZMOI_CONF=~/.config/chezmoi/chezmoi.toml
mkdir -p `dirname $CHEZMOI_CONF`
curl https://raw.githubusercontent.com/netspective-studios/home-creators/main/dot_config/chezmoi/chezmoi.toml.example > $CHEZMOI_CONF
chmod 0600 $CHEZMOI_CONF

echo "******************************************************************"
echo "** Netspective Studios Home (NSH) admin boostrap complete.      **"
echo "** Installed:                                                   **"
echo "**   - curl, git, jq, pass, unzip, bzip2, tree, and make        **"
echo "**   - osquery (for endpoint observability)                     **"
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
