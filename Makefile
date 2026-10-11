LUA ?= lua
LUAC ?= luac
LUACHECK ?= luacheck
PYTHON ?= python3
VENV ?= .venv
SHELLCHECK ?= $(VENV)/bin/shellcheck
BASHATE ?= $(VENV)/bin/bashate

.PHONY: check syntax lint venv shell-lint test diff-check

check: syntax lint test diff-check

syntax:
	$(LUAC) -p automatic-guild-interactions.lua tests/settings.lua

lint:
	$(LUACHECK) automatic-guild-interactions.lua tests/settings.lua

venv:
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/python -m pip install shellcheck-py bashate

shell-lint:
	$(SHELLCHECK) install.sh
	$(BASHATE) install.sh

test:
	$(LUA) tests/settings.lua

diff-check:
	git diff --check
