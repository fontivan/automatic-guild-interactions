-- luacheck: globals AutomaticGuildInteractionsDB UnitName IsInGuild GetNumGuildMembers
-- luacheck: globals GetGuildRosterInfo GuildRoster SendChatMessage C_Timer date time CreateFrame Settings
-- luacheck: ignore self

local sentMessages = {}
local frames = {}
local fontStrings = {}
local registeredCategory
local guildMembers = {}
local currentTime = 100
local rosterRequested = false
local scheduledTimers = {}

AutomaticGuildInteractionsDB = {
	messages = {
		welcome_back = "saved welcome",
		welcome = "",
		level_up = " ",
		congratulations = ""
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

	function widget:SetPoint(...)
		self.point = { ... }
	end

	function widget:SetText(text)
		self.text = text
		if self.scripts.OnTextChanged ~= nil then
			self.scripts.OnTextChanged(self)
		end
	end

	function widget:GetText()
		return self.text
	end

	function widget:SetSize()
	end

	function widget:SetAutoFocus()
	end

	function widget:SetCursorPosition(position)
		self.cursorPosition = position
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

	function widget:HookScript(event, callback)
		local previous = self.scripts[event]
		self.scripts[event] = function(...)
			if previous ~= nil then
				previous(...)
			end
			callback(...)
		end
	end

	function widget:ClearFocus()
	end

	function widget:RegisterEvent(event)
		self.events = self.events or {}
		table.insert(self.events, event)
	end

	function widget:CreateFontString()
		local fontString = CreateWidget()
		table.insert(fontStrings, fontString)
		return fontString
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
assert(AutomaticGuildInteractionsDB.messages.welcome == "welcome", "empty welcome message was not reset")
assert(AutomaticGuildInteractionsDB.messages.level_up == "ding", "blank level-up message was not reset")
assert(
	AutomaticGuildInteractionsDB.messages.congratulations == "grats",
	"empty congratulations message was not reset"
)
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

local welcomeBackMessageBox = editBoxes[1]
local welcomeBackDelayBox = editBoxes[2]
local welcomeMessageBox = editBoxes[3]
local levelUpMessageBox = editBoxes[4]
local congratulationsMessageBox = editBoxes[5]
local minMessageTimeBox = editBoxes[6]

assert(welcomeBackMessageBox.text == "saved welcome", "welcome-back field was not initialized")
assert(welcomeMessageBox.text == "welcome", "empty welcome field was not initialized with its default")
assert(levelUpMessageBox.text == "ding", "blank level-up field was not initialized with its default")
assert(congratulationsMessageBox.text == "grats", "empty congratulations field was not initialized with its default")
assert(welcomeBackMessageBox.cursorPosition == 0, "welcome-back field did not reset its cursor")

local function FindFontString(text, anchor)
	for _, fontString in ipairs(fontStrings) do
		if fontString.text == text and (anchor == nil or fontString.point[2] == anchor) then
			return fontString
		end
	end
end

local function assertFeatureGroup(index, headingText, messageBox, previousControl)
	local heading = FindFontString(headingText)
	assert(heading ~= nil, "missing feature heading: " .. headingText)
	assert(featureButtons[index].point[2] == heading, "feature toggle was not grouped under its heading")
	if previousControl ~= nil then
		assert(heading.point[2] == previousControl, "feature heading was not placed after the previous group")
	end
	local messageLabel = FindFontString("Message", featureButtons[index])
	assert(messageLabel ~= nil, "feature message label was not grouped under its toggle")
	assert(messageBox.point[2] == messageLabel, "feature message field was not grouped under its label")
end

assertFeatureGroup(1, "Welcome-back message", welcomeBackMessageBox)
assertFeatureGroup(2, "New guild member message", welcomeMessageBox, welcomeBackDelayBox)
assertFeatureGroup(3, "Level-up message", levelUpMessageBox, welcomeMessageBox)
assertFeatureGroup(4, "Congratulations message", congratulationsMessageBox, levelUpMessageBox)
local welcomeBackDelayLabel = FindFontString("Welcome-back message delay (seconds)", welcomeBackMessageBox)
assert(welcomeBackDelayLabel ~= nil, "welcome-back delay was not grouped with its feature")
assert(
	welcomeBackDelayBox.point[2] == welcomeBackDelayLabel,
	"welcome-back delay field was not grouped under its label"
)
local generalHeading = FindFontString("General settings", congratulationsMessageBox)
assert(generalHeading ~= nil, "general settings were not separated from feature groups")
local minMessageTimeLabel = FindFontString("Minimum time between messages (seconds)", generalHeading)
assert(minMessageTimeLabel ~= nil, "minimum message interval was not grouped under general settings")
assert(
	minMessageTimeBox.point[2] == minMessageTimeLabel,
	"minimum message interval field was not grouped under its label"
)

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

welcomeBackMessageBox.scripts.OnEditFocusGained(welcomeBackMessageBox)
welcomeBackMessageBox:SetText("custom welcome")
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "message edit was not saved immediately")
welcomeBackMessageBox.scripts.OnEnterPressed(welcomeBackMessageBox)
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "message edit was not persisted")
welcomeBackMessageBox.scripts.OnEditFocusGained(welcomeBackMessageBox)
welcomeBackMessageBox:SetText("unsaved message")
welcomeBackMessageBox.scripts.OnEscapePressed(welcomeBackMessageBox)
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "escape did not restore the message")
welcomeBackMessageBox:SetText("")
assert(welcomeBackMessageBox.text == "", "blank message should remain editable until committed")
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "custom welcome", "blank edit was saved prematurely")
welcomeBackMessageBox.scripts.OnEnterPressed(welcomeBackMessageBox)
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "wb", "blank message did not restore its default")
assert(welcomeBackMessageBox.text == "wb", "blank message field did not show its default")
welcomeMessageBox:SetText("")
assert(AutomaticGuildInteractionsDB.messages.welcome == "welcome", "blank welcome edit was saved prematurely")
welcomeMessageBox.scripts.OnEditFocusLost(welcomeMessageBox)
assert(AutomaticGuildInteractionsDB.messages.welcome == "welcome", "focus loss did not restore the welcome default")
assert(welcomeMessageBox.text == "welcome", "focus loss did not update the welcome field")

minMessageTimeBox:SetText("-1")
minMessageTimeBox.scripts.OnEnterPressed(minMessageTimeBox)
assert(AutomaticGuildInteractionsDB.min_message_time == 22, "invalid rate limit was saved")
welcomeBackDelayBox:SetText("-1")
welcomeBackDelayBox.scripts.OnEnterPressed(welcomeBackDelayBox)
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 0.5, "invalid welcome-back delay was saved")
assert(welcomeBackDelayBox.text == "0.5", "invalid delay did not restore the saved welcome-back delay")

eventFrame.scripts.OnEvent(eventFrame, "PLAYER_LEVEL_UP")
assert(#sentMessages == 1, "level-up event did not send a message")
assert(sentMessages[1].message == "ding" and sentMessages[1].channel == "GUILD", "level-up message behavior changed")

welcomeBackMessageBox:SetText("")
restoreDefaultsButton.scripts.OnClick()
RunNextTimer()
assert(AutomaticGuildInteractionsDB.messages.welcome_back == "wb", "restore defaults did not reset messages")
assert(AutomaticGuildInteractionsDB.messages.welcome == "welcome", "restore defaults did not reset welcome message")
assert(AutomaticGuildInteractionsDB.messages.level_up == "ding", "restore defaults did not reset level-up message")
assert(
	AutomaticGuildInteractionsDB.messages.congratulations == "grats",
	"restore defaults did not reset congratulations message"
)
assert(welcomeBackMessageBox.text == "wb", "restore defaults did not update the welcome-back field")
assert(welcomeMessageBox.text == "welcome", "restore defaults did not update the welcome field")
assert(levelUpMessageBox.text == "ding", "restore defaults did not update the level-up field")
assert(congratulationsMessageBox.text == "grats", "restore defaults did not update the congratulations field")
assert(welcomeBackMessageBox.cursorPosition == 0, "restore defaults did not reset the welcome-back field cursor")
assert(AutomaticGuildInteractionsDB.min_message_time == 10, "restore defaults did not reset rate limit")
assert(AutomaticGuildInteractionsDB.welcome_back_delay == 1, "restore defaults did not reset welcome-back delay")
assert(AutomaticGuildInteractionsDB.features.level_up, "restore defaults did not re-enable level-up")
assert(AutomaticGuildInteractionsDB.features.welcome_back, "restore defaults did not re-enable welcome-back")
assert(AutomaticGuildInteractionsDB.features.welcome, "restore defaults did not re-enable new-member welcomes")
assert(AutomaticGuildInteractionsDB.features.congratulations, "restore defaults did not re-enable congratulations")

welcomeBackDelayBox:SetText("2.5")
welcomeBackDelayBox.scripts.OnEnterPressed(welcomeBackDelayBox)
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

print(
	"Settings, feature toggles, persistence, defaults, single- and multiword login welcomes, "
		.. "and level-up behavior passed"
)
