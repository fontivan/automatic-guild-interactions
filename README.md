# automatic-guild-interactions
An addon for World of Warcraft: Classic to automatically perform some simple interactions, such as:
 - Welcome back after a guild member logs in
 - Dinging to guild chat after leveling
 - Congratulating other guild members when they let you know they leveled up

Open the addon's settings in the WoW Interface Options to customize its messages and minimum time between messages. Settings are saved per account. Use **Restore Defaults** in the options panel to reset them.

# Installation

The addon is available on Curseforge and can be installed with once click.

## Manual Installation

Run `install.sh` with the path to an existing World of Warcraft `AddOns` directory:

```sh
./install.sh "$HOME/Games/World of Warcraft/_classic_/Interface/AddOns"
```

Use `./install.sh --help` to display usage. The script replaces the existing `automatic-guild-interactions` addon folder in the destination.

# Development

The checks require Lua, LuaRocks, Lua development headers, Make, and a C compiler. On Fedora, install the system packages and Luacheck with:

```sh
sudo dnf install lua lua-devel luarocks make gcc
luarocks install --local luacheck
export PATH="$HOME/.luarocks/bin:$PATH"
```

Run `make check` to validate Lua syntax, run Luacheck, execute the settings behavior checks, and check the Git diff for whitespace errors. Individual checks are available as `make syntax`, `make lint`, `make test`, and `make diff-check`.
