LUA ?= lua
LUAC ?= luac
LUACHECK ?= luacheck

.PHONY: check syntax lint test diff-check

check: syntax lint test diff-check

syntax:
	$(LUAC) -p automatic-guild-interactions.lua tests/settings.lua

lint:
	$(LUACHECK) .

test:
	$(LUA) tests/settings.lua

diff-check:
	git diff --check
