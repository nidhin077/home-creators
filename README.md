# Netspective Studios Typical Polyglot Creator's Home Setup

This is our opinionated [chezmoi](https://www.chezmoi.io/)- and [asdf](https://asdf-vm.com/)-based "engineering sandbox home" setup for polyglot software development or any other "creator tasks" that are performed on Linux-like operating systems.

If you're using Windows 10 with WSL2, create a "disposable" Debian WSL2 instance using Windows Store. This project treats the WSL2 instance as "disposable" meaning it's for development only and can easily be destroyed and recreated whenever necessary. The cost for creation and destruction for a Engineering Sandbox should be so low that it should be treated almost as a container rather than a VM.

If you're using a Debian-based distro you should be able to run this repo in any Debian user account. It will probably work with any Linux-like OS but has only been tested on Debian-based distros (e.g. Debian and Ubuntu).

## One-time setup

Bootstrap a Debian environment with required utilities:

```bash
sudo apt-get -qq update && sudo apt-get install curl -y -qq && \
    curl -sSL https://raw.githubusercontent.com/netspective-studios/home-creators/master/bootstrap-admin-debian.sh | bash
```

We use [chezmoi](https://www.chezmoi.io/) with templates to manage our dotfiles across multiple diverse machines, securely. The `bootstrap-*` script has already created the `chezmoi` config file which you should personalize _before installing_ `chezmoi`. See [chezmoi.toml Example](dot_config/chezmoi/chezmoi.toml.example) to help understand the variables that can be set and used across chezmoi templates.

```bash
# Personalize your chezmoi config
vi ~/.config/chezmoi/chezmoi.toml
sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply netspective-studios/home-creators
```

We prefer ZSH as the default shell. Run [ZSH for Humans](https://github.com/romkatv/zsh4humans#installation) (`z4h`) installer:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
```

Finalize `.zshrc` setup and then exit your shell:

```bash
cat << 'EOF' >> ~/.zshrc
z4h source ~/.asdf/asdf.sh
z4h source -- ~/.config/z4h-zshrc/*.auto.zshrc
eval "$(asdf exec direnv hook zsh)"
direnv() { asdf exec direnv "$@"; }
EOF
exit
```

Open a new terminal then complete the initial setup using `homectl`:

```zsh
homectl setup setup-asdf-plugins-typical setup-data-engr-enhanced
```

After initial setup `cd ~ && just (cmd)` will be equivalent to `homectl (cmd)`. `homectl` is one of many aliases defined by the auto-imported [~/.config/z4h-zshrc/aliases.auto.zshrc](dot_config/z4h-zshrc/aliases.auto.zshrc.tmpl) file. Personalize `z4h` with your own preferences. Learn how to use `z4h` to [keep it up to date](https://github.com/romkatv/zsh4humans#updating) and understand the recommended [customization approach](https://github.com/romkatv/zsh4humans#customization).

Customize your aliases and functions in `~/.config/z4h-zshrc/*.auto.zshrc` -- basically, any file in your `~/.config/z4h-zshrc` directory that has the `*.auto.zshrc` extension will be automatically sourced by `z4h` into each shell.

## One-time Install of Optional Packages

```bash
# if you're doing PostgreSQL database development and need psql command
# $HOME/.pgpass and $HOME/.psqlrc are part of chezmoi dotfiles
sudo apt-get install postgresql-client -y -qq

# if you're doing your own software builds (instead of using binaries)
sudo apt-get -y -qq install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libxml2-dev xz-utils tk-dev libxmlsec1-dev libreadline-dev libffi-dev libbz2-dev liblzma-dev llvm
```

## Routine Maintenance

On a daily, weekly, or monthly basis run:

```bash
homectl maintain
```

# What's Installed

* We use `$HOME/bin` for binaries whenever possible instead globally installing them using `sudo`.
* We use `git` and `git-extras` because we're a GitOps shop.
* We use [asdf](https://asdf-vm.com/) as our package manager to install all languages and utilities possible so that they can be easily installed and, more importantly, support multiple versions simultaneously.
* We use [just](https://github.com/casey/just) command runner to execute tasks (available in `$HOME/bin`). We favor `just` over `make` for new packages but `make` is still a great tool for legacy requirements.
* We use [pass](https://www.passwordstore.org/) the standard unix password manager for managing secrets that should not be in plaintext.

## Secrets Management

* `$HOME/.pgpass` should follow [PostgreSQL .pgpass](https://tableplus.com/blog/2019/09/how-to-use-pgpass-in-postgresql.html) rules for password management.

## Managed Git Repos (GitHub, GitLab, etc.) Tools

Please review the bundled [Managed Git](dot_config/managed-git/README.md) and opinionated set of instructions and tools for managing code workspaces that depend on multiple repositories.

We use [Semantic Versioning](https://semver.org/) so be sure to learn and regularly use the [semtag](https://github.com/nico2sh/semtag) bash script that is installed as `git-semtag` in `$HOME/bin` by `homectl setup` task. 

For example:

```bash
git commit -am "git commit message"
git-semtag final -v v0.5.0
# or 'git-semtag final' without version to auto-compute semver based on heuristics
git push
```

## Polyglot Languages Installation and Version Management

Netspective Studios projects assume that [asdf](https://asdf-vm.com/) is being used for version management of programming languages (Java, Go, etc.) and runtime environments (Deno, NodeJS, Python, etc.) and `direnv` is being used for project-specific environments. 

You can install languages and other packages like this:

```bash
asdf plugin add golang
asdf plugin add nodejs

asdf install golang latest
asdf install nodejs latest

asdf global golang latest
asdf global nodejs latest
...

asdf current
```

Or, use the convenience tasks in `homectl`:

```bash
homectl setup-asdf-plugin java          # Install the plugin and its latest stable version but don't set the version
homectl setup-asdf-plugin julia
...
homectl setup-asdf-plugin-global hugo   # Install the named plugin, its latest stable release, and then set it as the global version
homectl setup-asdf-plugin-global python
homectl setup-asdf-plugin-global haxe
homectl setup-asdf-plugin-global neko
...
asdf current
```

## Important per-project and per-directory configuration management tools

We use `asdf` to manage almost all languages and utilities so that they can be easily installed and, more importantly, support multiple versions simultaneously. For example, we heavily use `Deno` for multiple projects but each project might require a different version. `asdf` supports global, per session, and per project (directory) [version configuration strategy](https://asdf-vm.com/#/core-configuration?id=tool-versions).

`asdf` has [centrally managed plugins](https://asdf-vm.com/#/plugins-all) for many languages and runtimes and there are even more [contributed plugins](https://github.com/search?q=asdf) for additional languages and runtimes. 

There are good [asdf videos](https://www.youtube.com/watch?v=r6qLQgq2vGk) worth watching.

In addition to `asdf` which supports a flexible [version configuration strategy](https://asdf-vm.com/#/core-configuration?id=tool-versions) for languages and runtimes, we use [direnv](https://asdf-vm.com/) to encourage usage of environment variables with per-directory flexibility. Per their documentation:

> direnv is an extension for your shell. It augments existing shells with a new feature that can load and unload environment variables depending on the current directory.

We use `direnv` and `.envrc` files to manage environments on a [per-directory](https://www.tecmint.com/direnv-manage-environment-variables-in-linux/) (per-project and descendant directories) basis. `direnv` can be used to [manage secrets](https://www.youtube.com/watch?v=x3p-28PajJY) as well as non-secret configurations. Many other [development automation techniques](http://www.futurile.net/2016/02/03/automating-environment-setup-with-direnv/) are possible.

There are some [direnv YouTube videos](https://www.youtube.com/results?search_query=direnv) worth watching to get familar with the capabilities.

## Data Engineering

Default data tools installed in `~/bin`:

* [Miller](https://github.com/johnkerl/miller) is like awk, sed, cut, join, and sort for name\-indexed data such as CSV, TSV, and tabular JSON.
* [daff](https://github.com/paulfitz/daff) library for comparing tables, producing a summary of their differences.

If you run `homectl setup-data-engr-enhanced` you also get:

* [csvtk](https://github.com/shenwei356/csvtk) is a cross-platform, efficient and practical CSV/TSV toolkit in Golang.
* [xsv](https://github.com/BurntSushi/xsv) is a fast CSV command line toolkit written in Rust.
* [OctoSQL](https://github.com/cube2222/octosql) is a query tool that allows you to join, analyse and transform data from multiple databases and file formats using SQL.
* [q](http://harelba.github.io/q/) - Run SQL directly on CSV or TSV files.
* [Dasel](https://github.com/TomWright/dasel) jq/yq for JSON, YAML, TOML, XML and CSV with zero runtime dependencies.

## Beneficial Add-ons

### gitui terminal-ui for Git

[GitUI](https://github.com/extrawurst/gitui) provides you with the comfort of a git GUI but right in your terminal. Per their website, "this tool does not fully substitute the `git` CLI, however both tools work well in tandem". It can be installed using:

```bash
homectl setup-asdf-plugin-global gitui https://github.com/looztra/asdf-gitui
```

# TODO (Roadmap)

Need to consider adding the following over time.

## Install optional packages via chezmoi

See:

```bash
chezmoi execute-template '{{ .chezmoi.osRelease.id }}'      # e.g. debian or ubuntu
chezmoi execute-template '{{ .chezmoi.osRelease.idLike }}'  # e.g. debian if running ubuntu
```

If a release is Debian or Debian-like (e.g. Ubuntu and others) we should automatically install some packages through `chezmoi` [scripts to perform actions](https://www.chezmoi.io/docs/how-to/#use-scripts-to-perform-actions). This might be a better way to install `postgresql-client` and other database-specific functionality as well as other packages.

## IDEs and Editors

* Integrate [Helix](https://github.com/helix-editor/helix) as our opinionated terminal editor.

## File Management

* Integrate [Wildland](https://wildland.io/), a collection of protocols, conventions, and software, which creates a union file system across S3, WebDAV, K8s, and other storage providers.

## Data Publishing

* [Datasette](https://datasette.io/) multi-tool for exploring and publishing data. It helps data journalists and anyone else who has data that they wish to share with the world take data of any shape or size, analyze and explore it, and publish it as an interactive website and accompanying API.

## Data Engineering

* [db-to-sqlite](https://github.com/simonw/db-to-sqlite) CLI tool for exporting tables or queries from any SQL database to a SQLite file to make data portable.
* [sqlite-utils](https://github.com/simonw/sqlite-utils) CLI utility and Python library for manipulating SQLite databases
* [jOOQ Parser](https://www.jooq.org/translate/) to translate any SQL statement(s) to a different dialect
* A list of command line tools for manipulating structured text data is available at https://github.com/dbohdan/structured-text-tools
* [eBay's TSV Utilities](https://github.com/eBay/tsv-utils): Command line tools for large, tabular data files. Filtering, statistics, sampling, joins and more. 
* [pgLoader](https://pgloader.io/) can either load data from files, such as CSV or Fixed-File Format; or migrate a whole database to PostgreSQL
* [dbcrossbar](http://www.dbcrossbar.org/) copies large, tabular datasets between many different databases and storage formats. Data can be copied from any source to any destination.
