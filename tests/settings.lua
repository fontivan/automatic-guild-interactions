-- luacheck: globals AutomaticGuildInteractionsDB UnitName IsInGuild GetNumGuildMembers
-- luacheck: globals GetGuildRosterInfo GuildRoster SendChatMessage date time CreateFrame Settings
-- luacheck: ignore self

local sentMessages = {}
local frames = {}
local registeredCategory
local guildMembers = {}
local currentTime = 100
local rosterRequested = false

AutomaticGuildInteractionsDB = {
	messages = {
		welcome_back = "saved welcome"
	},
	min_message_time = 22
}

function UnitName()
	return "TestPlayer"
end

function IsInGuild()
	return true
end

function GetNumGuildMembers()
	return #guildMembers
end

function GetGuildRosterInfo(index)
	return guildMembers[index]
end

function GuildRoster()
	rosterRequested = true
end

function SendChatMessage(message, channel)
	table.insert(sentMessages, { message = message, channel = channel })
end

function date()
	return {}
end

function time()
	return currentTime
end

local function CreateWidget()
	local widget = { scripts = {} }

	function widget:SetPoint()
	end

	function widget:SetText(text)
		self.text = text
	end

	function widget:GetText()
		return self.text
	end

	function widget:SetSize()
	end

	function widget:SetAutoFocus()
	end

	function widget:SetScript(event, callback)
		self.scripts[event] = callback
	end

	function widget:ClearFocus()
	end

	function widget:RegisterEvent(event)
		self.events = self.events or {}
		table.insert(self.events, event)
	end

	function widget:CreateFontString()
		return CreateWidget()
	end

	return widget
end

function CreateFrame(_, _, _, template)
	local frame = CreateWidget()
	frame.template = template
	table.insert(frames, frame)
	return frame
end

Settings = {
	RegisterCanvasLayoutCategory = function(panel, name)
		registeredCategory = { panel = panel, name = name }
		return registeredCategory
	end,
	RegisterAddOnCategory = function(category)
		assert(category == registeredCategory, "registered unexpected options category")
	end
}

dofile("automatic-guild-interactions.lua")

assert(AutomaticGuildInteractionsDB.messages.welcome_back == "saved welcome", "saved message was not loaded")
assert(AutomaticGuildInteractionsDB.min_message_time == 22, "saved rate limit was not loaded")
assert(registeredCategory ~= nil, "modern options category was not registered")

local editBoxes = {}
local restoreDefaultsButton
local eventFrame
for _, frame in ipairs(frames) do
	if frame.template == "InputBoxTemplate" then
		table.insert(editBoxes, frame)
	elseif frame.template == "UIPanelButtonTemplate" then
		restoreDefaultsButton = frame
	elseif frame.scripts.OnEvent ~= nil then
		eventFrame = frame
	end
end

assert(#editBoxes == 5, "expected four message fields and one rate-limit field")
assert(restoreDefaultsButton ~= nil, "restore-defaults button was not created")
assert(eventFrame ~= nil, "event frame was not created")

editBoxes[1]:SetText("custom welcome")
editBoxes[1].scripts.OnEnterPressed(editBoxes[1])
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "message edit was not persisted")

editBoxes[5]:SetText("-1")
editBoxes[5].scripts.OnEnterPressed(editBoxes[5])
assert(AutomaticGuildInteractionsDB.min_message_time == 22, "invalid rate limit was saved")

eventFrame.scripts.OnEvent(eventFrame, "PLAYER_LEVEL_UP")
assert(#sentMessages == 1, "level-up event did not send a message")
assert(sentMessages[1].message == "ding" and sentMessages[1].channel == "GUILD", "level-up message behavior changed")

restoreDefaultsButton.scripts.OnClick()
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "wb", "restore defaults did not reset messages")
assert(AutomaticGuildInteractionsDB.messages.welcome == "welcome", "restore defaults did not reset welcome message")
assert(AutomaticGuildInteractionsDB.messages.level_up == "ding", "restore defaults did not reset level-up message")
assert(
	AutomaticGuildInteractionsDB.messages.congratulations == "grats",
	"restore defaults did not reset congratulations message"
)
assert(AutomaticGuildInteractionsDB.min_message_time == 10, "restore defaults did not reset rate limit")

eventFrame.scripts.OnEvent(eventFrame, "PLAYER_LOGIN")
assert(rosterRequested, "guild roster was not requested on login")
eventFrame.scripts.OnEvent(
	eventFrame,
	"CHAT_MSG_SYSTEM",
	"|Hplayer:First Last|h[First Last]|h has come online."
)
assert(#sentMessages == 1, "welcome-back message was sent before the roster was ready")

guildMembers = { "First Last-Realm" }
currentTime = 111
eventFrame.scripts.OnEvent(eventFrame, "GUILD_ROSTER_UPDATE")
assert(#sentMessages == 2, "multiword guild member was not welcomed after the roster update")
assert(
	sentMessages[2].message == "wb" and sentMessages[2].channel == "GUILD",
	"welcome-back message behavior changed"
)

guildMembers = { "SingleName" }
currentTime = 122
eventFrame.scripts.OnEvent(eventFrame, "CHAT_MSG_SYSTEM", "SingleName has come online.")
assert(#sentMessages == 3, "single-name guild member was not welcomed")
assert(sentMessages[3].message == "wb", "single-name welcome-back message changed")

print("Settings, persistence, defaults, single- and multiword login welcomes, and level-up behavior passed")
