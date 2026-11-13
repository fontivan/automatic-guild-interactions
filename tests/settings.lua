-- luacheck: globals AutomaticGuildInteractionsDB UnitName IsInGuild GetNumGuildMembers
-- luacheck: globals GetGuildRosterInfo GuildRoster SendChatMessage C_Timer date time CreateFrame Settings
-- luacheck: ignore self

local sentMessages = {}
local frames = {}
local registeredCategory
local guildMembers = {}
local currentTime = 100
local rosterRequested = false
local scheduledTimers = {}

AutomaticGuildInteractionsDB = {
	messages = {
		welcome_back = "saved welcome"
	},
	min_message_time = 22,
	welcome_back_delay = 0.5,
	features = {
		congratulations = false
	}
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

C_Timer = {
	After = function(delay, callback)
		table.insert(scheduledTimers, { delay = delay, callback = callback })
	end
}

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

	function widget:SetChecked(checked)
		self.checked = checked
	end

	function widget:GetChecked()
		if self.checked then
			return 1
		end
		return nil
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

local function RunNextTimer()
	local timer = table.remove(scheduledTimers, 1)
	assert(timer ~= nil, "expected a scheduled timer")
	timer.callback()
	return timer
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
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 0.5, "saved welcome-back delay was not loaded")
assert(registeredCategory ~= nil, "modern options category was not registered")
registeredCategory.panel.scripts.OnShow()

local editBoxes = {}
local featureButtons = {}
local restoreDefaultsButton
local eventFrame
for _, frame in ipairs(frames) do
	if frame.template == "InputBoxTemplate" then
		table.insert(editBoxes, frame)
	elseif frame.template == "UICheckButtonTemplate" then
		table.insert(featureButtons, frame)
	elseif frame.template == "UIPanelButtonTemplate" then
		restoreDefaultsButton = frame
	elseif frame.scripts.OnEvent ~= nil then
		eventFrame = frame
	end
end

assert(#editBoxes == 6, "expected four message fields and two timing fields")
assert(#featureButtons == 4, "expected one checkbox for each feature")
assert(restoreDefaultsButton ~= nil, "restore-defaults button was not created")
assert(eventFrame ~= nil, "event frame was not created")

assert(featureButtons[1].checked, "features should be enabled by default")
assert(not featureButtons[4].checked, "saved feature setting was not loaded")
featureButtons[4]:SetChecked(true)
featureButtons[4].scripts.OnClick(featureButtons[4])
featureButtons[3]:SetChecked(false)
featureButtons[3].scripts.OnClick(featureButtons[3])
assert(AutomaticGuildInteractionsDB.features.level_up == false, "feature toggle was not persisted")
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_LEVEL_UP")
assert(#sentMessages == 0, "disabled level-up feature sent a message")
featureButtons[3]:SetChecked(true)
featureButtons[3].scripts.OnClick(featureButtons[3])

featureButtons[2]:SetChecked(false)
featureButtons[2].scripts.OnClick(featureButtons[2])
eventFrame.scripts.OnEvent(eventFrame, "CHAT_MSG_SYSTEM", "Other has joined the guild.", "Other")
assert(#sentMessages == 0, "disabled new-member feature sent a message")
featureButtons[2]:SetChecked(true)
featureButtons[2].scripts.OnClick(featureButtons[2])

featureButtons[4]:SetChecked(false)
featureButtons[4].scripts.OnClick(featureButtons[4])
eventFrame.scripts.OnEvent(eventFrame, "CHAT_MSG_GUILD", "ding", "Other")
assert(#sentMessages == 0, "disabled congratulations feature sent a message")
featureButtons[4]:SetChecked(true)
featureButtons[4].scripts.OnClick(featureButtons[4])

editBoxes[1]:SetText("custom welcome")
editBoxes[1].scripts.OnEnterPressed(editBoxes[1])
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "message edit was not persisted")

editBoxes[5]:SetText("-1")
editBoxes[5].scripts.OnEnterPressed(editBoxes[5])
assert(AutomaticGuildInteractionsDB.min_message_time == 22, "invalid rate limit was saved")
editBoxes[6]:SetText("-1")
editBoxes[6].scripts.OnEnterPressed(editBoxes[6])
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 0.5, "invalid welcome-back delay was saved")
assert(editBoxes[6].text == "0.5", "invalid delay did not restore the saved welcome-back delay")

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
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 1, "restore defaults did not reset welcome-back delay")
assert(AutomaticGuildInteractionsDB.features.level_up, "restore defaults did not re-enable level-up")
assert(AutomaticGuildInteractionsDB.features.welcome_back, "restore defaults did not re-enable welcome-back")
assert(AutomaticGuildInteractionsDB.features.welcome, "restore defaults did not re-enable new-member welcomes")
assert(AutomaticGuildInteractionsDB.features.congratulations, "restore defaults did not re-enable congratulations")

editBoxes[6]:SetText("2.5")
editBoxes[6].scripts.OnEnterPressed(editBoxes[6])
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 2.5, "welcome-back delay was not saved")

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
assert(#sentMessages == 1, "welcome-back message was sent before its delay")
assert(#scheduledTimers == 1, "welcome-back message was not scheduled")
assert(scheduledTimers[1].delay == 2.5, "configured welcome-back message delay was not used")
RunNextTimer()
assert(#sentMessages == 2, "multiword guild member was not welcomed after the roster update")
assert(
	sentMessages[2].message == "wb" and sentMessages[2].channel == "GUILD",
	"welcome-back message behavior changed"
)

guildMembers = { "SingleName" }
currentTime = 122
eventFrame.scripts.OnEvent(eventFrame, "CHAT_MSG_SYSTEM", "SingleName has come online.")
assert(#sentMessages == 2, "single-name welcome-back message was sent before its delay")
RunNextTimer()
assert(#sentMessages == 3, "single-name guild member was not welcomed")
assert(sentMessages[3].message == "wb", "single-name welcome-back message changed")

featureButtons[1]:SetChecked(false)
featureButtons[1].scripts.OnClick(featureButtons[1])
currentTime = 133
eventFrame.scripts.OnEvent(eventFrame, "CHAT_MSG_SYSTEM", "SingleName has come online.")
assert(#sentMessages == 3, "disabled welcome-back feature sent a message")

print("Settings, feature toggles, persistence, defaults, single- and multiword login welcomes, and level-up behavior passed")
