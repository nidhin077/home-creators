# Managed Git (mGit) workspaces (repos) governance

## Governed directory structure

mGit workspaces are managed by either GitHub or cloud/on-premise GitLab or any other supplier which offers HTTPs based Git repository management.

A very specific convention is used to structure "managed" Git workspaces (repos) in current directory where each Git manager (e.g. github.com or git.company.io) has a home path under workspaces and the repos from that server are placed in the exact same directory structure as they appear in the home server (e.g. github.com or git.company.io). For GitHub, there is only github.com/org/repo combination but for GitLab there can be unlimited depth like git.company.io/group1/subgroup1/repo.

```bash
❯ tree -d -L 4 `pwd`
└── workspaces
    ├── github.com
    │   └── shah
    │       ├── vscode-team
    │       ├── uniform-resource
    └── gitlab.company.io
        └── gitlab-group-parent
            └── child
                └── grandchild
                    ├── repo1
                    └── repo2
```     

## Governed code-workspace files

All the `vscws-*` tasks use VS Code `*.code-workspace` files whose folders assume that the `*.code-workspace` file is in the current directory root. This allows Visual Studio Code users to set their folders for all Git managers relative to the current directory as the root. 

With this feature, VSC workspaces are all fully portable using relative directories and can easily mix repos from different Git managers (e.g. GitHub, GitLab).

For example, to produce the structure shown above the following `my.code-workspace` can be used:

```json
{
  "folders": [
    {
      "path": "github.com/shah/vscode-team"
    },
    {
      "path": "github.com/shah/uniform-resource"
    },
    {
      "path": "gitlab.company.io/gitlab-group-parent/child/grandchild/repo1"
    },
    {
      "path": "gitlab.company.io/gitlab-group-parent/child/grandchild/repo2"
    }
  ],
  "settings": {
    "git.autofetch": true
  }
}
```

## Creating managed Git workspaces

Typically, the following alias is setup for Managed Git Controller (`mgitctl`):

```bash
MANAGED_GIT_CONF_HOME=${MANAGED_GIT_CONF_HOME:-$HOME/.config/managed-git}
alias mgitctl="just --justfile $MANAGED_GIT_CONF_HOME/mgitctl.justfile --working-directory `pwd`"
alias mgitcd="cd \$MANAGED_GIT_WORKSPACES_HOME"
```

Either you can use the alias or run the full `Just` command to create a workspace. This is the most common setup:

```bash
mgitctl workspaces-init $HOME/workspaces
```

As you clone repos and move around inside `$HOME/workspaces` you may want to easily come back to the top of the workspaces root. You can do that using the `mgitcd` alias. If you're inside a directory or descendant of a path created using `mgitctl workspaces-init`, the `mgitcd` alias will bring you to root of workspaces (e.g. `$HOME/workspaces`). For example:

```bash
$HOME/workspaces/github.com/shah/vscode-team
mgitcd
```

## Using managed Git workspaces

After using `mgitctl workspaces-init $HOME/workspaces` you can use commands like:

```bash
cd $HOME/workspaces
just --list                                    # to see a list of available commands
just repo-ensure github.com/shah/vscode-team   # clone or pull the given repo
just vscws-inspect-git-managers                # see which Git managers (GitHub.com, etc.) are used in all *.code-workspace files
just vscws-repos-ensure-ref my.code-workspace  # Clone/pull all repos in my.code-workspace and prepare for opening in VS Code
just vscws-inspect                             # find all *.code-workspace files
just vscws-inspect-ensure                      # find all *.code-workspace files and pick which ones to pull/clone 
just vscws-inspect-ensure | sh                 # find all *.code-workspace files and clone/pull them all
```

### Cloning or pulling repos directly from managed Git sources

Work with managed Git repos using the `just repo-ensure` command:

```bash
mgitcd    # or $HOME/workspaces
❯ just repo-ensure github.com/shah/my-repo
my-repo found, pulling latest in github.com/shah/my-repo
Ready: cd github.com/shah/my-repo
   or: just vscws-repos-ensure-ref github.com/shah/my-repo/my.code-workspace
```

After the `Ready: ` prompt you will see suggested commands you can copy/paste and run. In the example above, `just vscws-repos-ensure-ref github.com/shah/vscode-team/my.code-workspace` was shown after `or:` because it found a `my.code-workspace` and suggests that you can *either* `cd` into the directory *or* run the `just` command to automatically clone all the repos contained in `my.code-workspace`

### Cloning or pulling repos referenced in VS Code *.code-workspace files

Because most real-world development involves working with multiple related repositories, the Managed Git system allows you to use repo aggregators, like Visual Studio Code `*.code-workspace` files, to drive which repos to clone/pull. 

To find the unique repo managers referenced in all `*.code-workspace` files at the current directory and descendants:

```bash
just vscws-inspect-git-managers
```

To find all the code-workspace files available in all descendant directories:

```bash
just vscws-inspect
just vscws-inspect-ensure
just vscws-inspect-ensure | sh
just vscws-repos-ensure-ref my.code-workspace
```

There are slight differences between each of the above:

* The first one just shows the `*.code-workspace` files.
* The second one will find `*.code-workspace` files and shows you the commands to run to clone the repos inside each `*.code-workspace` file.
* The third one will not just show the commands but execute them as well.
* The fourth one will clone/pull repos only a single `.code-workspace` file (this is the command used by `vscws-inspect-ensure`)

There are two similar `just` tasks: 

* `vscws-repos-ensure` will clone/pull all repos in a single `.code-workspace` file
* `vscws-repos-ensure-ref` will first run `vscws-repos-ensure` but then also sets a symlink to the `.code-workspace` in the root workspace (e.g. `$HOME/workspaces`). This is helpful if you want to use Visual Studio Code to work on your project across multiple repos.

When you run `just vscws-inspect-ensure | sh` for multiple workspaces or `vscws-repos-ensure-ref` for a single workspace, you'll see something like this in the `$HOME/workspaces` directory:

```
❯ ls -al $HOME/workspaces
-rw-rw-r--  1 snshah snshah   59 Jun  8 10:16 .envrc
drwxr-xr-x 10 snshah snshah 4.0K Sep 17 18:01 github.com
drwxr-xr-x  8 snshah snshah 4.0K Sep 25 11:09 gitlab.company.io
lrwxrwxrwx  1 snshah snshah   42 Jun  8 10:16 Justfile -> ../.config/managed-git/workspaces.justfile
lrwxrwxrwx  1 snshah snshah  115 Sep 28 10:01 my.code-workspace -> github.com/shah/my-repo/my.code-workspace
lrwxrwxrwx  1 snshah snshah  115 Sep 28 10:01 repo1.code-workspace -> gitlab.company.io/gitlab-group-parent/child/grandchild/repo1.code-workspace
...
```

The `vscws-repos-ensure-ref` command, which is used by `just vscws-inspect-ensure | sh`, will create a *reference* (symbolic link, or *symlink*) to the `*.code-workspace`. The symlink'd `*.code-workspace` is the one that should be opened in Visual Studio Code so that all the repos are resolved through relative paths from the root of the `workspaces` directory.

## Semantic Versioning and Git Tagging

We use [Semantic Versioning](https://semver.org/) so be sure to learn and regularly use the [semtag](https://github.com/nico2sh/semtag) bash script. 

For example:

```bash
git commit -am "git commit message"
git-semtag final -v v0.5.0
# or 'git-semtag final' without version to auto-compute semver based on heuristics
git push
```
