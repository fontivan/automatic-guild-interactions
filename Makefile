TOOLS_DIR ?= .tools
LUA_VERSION ?= 5.4.8
LUA_ABI_VERSION ?= 5.4
LUAROCKS_VERSION ?= 3.13.0
LUACHECK_VERSION ?= 1.2.0-1

LUA_PREFIX := $(abspath $(TOOLS_DIR)/lua-$(LUA_VERSION))
LUAROCKS_PREFIX := $(abspath $(TOOLS_DIR)/luarocks-$(LUAROCKS_VERSION))
LUAROCKS_TREE := $(abspath $(TOOLS_DIR)/rocks)
LUA_SOURCE_DIR := $(TOOLS_DIR)/src/lua-$(LUA_VERSION)
LUAROCKS_SOURCE_DIR := $(TOOLS_DIR)/src/luarocks-$(LUAROCKS_VERSION)
LUA_ARCHIVE := $(TOOLS_DIR)/downloads/lua-$(LUA_VERSION).tar.gz
LUAROCKS_ARCHIVE := $(TOOLS_DIR)/downloads/luarocks-$(LUAROCKS_VERSION).tar.gz
LUAROCKS_BIN := $(LUAROCKS_PREFIX)/bin/luarocks
LUACHECK_BIN := $(LUAROCKS_TREE)/bin/luacheck

LOCAL_LUA := $(LUA_PREFIX)/bin/lua
LOCAL_LUAC := $(LUA_PREFIX)/bin/luac
LOCAL_LUACHECK := $(LUACHECK_BIN)
LUA = $(LOCAL_LUA)
LUAC = $(LOCAL_LUAC)
LUACHECK = $(LOCAL_LUACHECK)
PYTHON ?= python3
VENV ?= .venv
SHELLCHECK ?= $(VENV)/bin/shellcheck
BASHATE ?= $(VENV)/bin/bashate

.PHONY: check tools syntax lint venv shell-lint test diff-check

check: syntax lint test diff-check

tools: $(LUACHECK_BIN)

$(LUA_ARCHIVE):
	mkdir -p $(@D)
	curl -fL --retry 3 https://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz -o $@

$(LUAROCKS_ARCHIVE):
	mkdir -p $(@D)
	curl -fL --retry 3 https://luarocks.org/releases/luarocks-$(LUAROCKS_VERSION).tar.gz -o $@

$(LUA_PREFIX)/.installed: $(LUA_ARCHIVE)
	mkdir -p $(TOOLS_DIR)/src
	tar -xzf $< -C $(TOOLS_DIR)/src
	$(MAKE) -C $(LUA_SOURCE_DIR) linux
	$(MAKE) -C $(LUA_SOURCE_DIR) install INSTALL_TOP=$(LUA_PREFIX)
	touch $@

$(LUAROCKS_PREFIX)/.installed: $(LUAROCKS_ARCHIVE) $(LUA_PREFIX)/.installed
	mkdir -p $(TOOLS_DIR)/src
	tar -xzf $(LUAROCKS_ARCHIVE) -C $(TOOLS_DIR)/src
	cd $(LUAROCKS_SOURCE_DIR) && ./configure --prefix=$(LUAROCKS_PREFIX) --with-lua=$(LUA_PREFIX) --lua-version=$(LUA_ABI_VERSION)
	$(MAKE) -C $(LUAROCKS_SOURCE_DIR)
	$(MAKE) -C $(LUAROCKS_SOURCE_DIR) install
	touch $@

$(LUACHECK_BIN): $(LUAROCKS_PREFIX)/.installed
	mkdir -p $(LUAROCKS_TREE)
	$(LUAROCKS_BIN) --lua-dir=$(LUA_PREFIX) --lua-version=$(LUA_ABI_VERSION) --tree=$(LUAROCKS_TREE) install --no-doc luacheck $(LUACHECK_VERSION)

syntax test: $(LUA_PREFIX)/.installed

lint: $(LUACHECK_BIN)

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
