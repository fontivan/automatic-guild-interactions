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

The Lua checks use the versions pinned in [`.lua-version`](./.lua-version), [`.luarocks-version`](./.luarocks-version), and [`.luacheck-version`](./.luacheck-version), shared with CI. SHA-256 checksums for the downloaded Lua, LuaRocks, and Luacheck archives are pinned in [`.lua-sha256`](./.lua-sha256), [`.luarocks-sha256`](./.luarocks-sha256), and [`.luacheck-sha256`](./.luacheck-sha256). The Lua version matches WoW's Lua 5.1 syntax baseline. Run `make tools` to download and build the tools locally under `.tools/`; `make check` bootstraps them automatically. The bootstrap requires Make, curl, sha256sum, a C toolchain, Git, tar, and unzip; it does not install or rely on system Lua packages.

Run `make all` to run the Lua syntax check, Luacheck, settings tests, whitespace check, ShellCheck, and bashate. This also creates/updates a local Python virtual environment for the optional shell lint tools:

```sh
make all
```

Run `make check` for the Lua checks and whitespace check only. Individual checks are available as `make syntax`, `make lint`, `make venv`, `make shell-lint`, `make test`, and `make diff-check`.
