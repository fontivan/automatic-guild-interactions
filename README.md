# automatic-guild-interactions
An addon for World of Warcraft: Classic to automatically perform some simple interactions, such as:
 - Welcome back after a guild member logs in
 - Dinging to guild chat after leveling
 - Congratulating other guild members when they let you know they leveled up

Open the addon's settings in the WoW Interface Options to enable or disable each feature, customize its messages, set the minimum time between messages, and configure the welcome-back message delay (1 second by default). Settings are saved per account. Use **Restore Defaults** in the options panel to reset them.

# Installation

The addon is available on Curseforge and can be installed with once click.

## Manual Installation

Run `install.sh` with the path to an existing World of Warcraft `AddOns` directory:

```sh
./install.sh "$HOME/Games/World of Warcraft/_classic_/Interface/AddOns"
```

Use `./install.sh --help` to display usage. The script replaces the existing `automatic-guild-interactions` addon folder in the destination.

# Development

The Lua checks use the version pinned in [`.lua-version`](./.lua-version), shared with CI and matching WoW's Lua 5.1 syntax baseline. Run `make tools` to download and build that Lua version and LuaRocks locally under `.tools/`, then install Luacheck 1.2.0 there. `make check` bootstraps these tools automatically. The bootstrap requires Make, curl, a C toolchain, Git, tar, and unzip; it does not install or rely on system Lua packages.

Optional shell linting for `install.sh` uses Python 3 to create a local virtual environment and install ShellCheck and bashate:

```sh
make venv
make shell-lint
```

Run `make check` to validate Lua syntax, run Luacheck, execute the settings behavior checks, and check the Git diff for whitespace errors. Individual checks are available as `make syntax`, `make lint`, `make venv`, `make shell-lint`, `make test`, and `make diff-check`.
