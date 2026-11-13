
-- luacheck: ignore _
-- luacheck: ignore self
-- luacheck: globals AutomaticGuildInteractionsDB Settings InterfaceOptions_AddCategory
-- luacheck: globals CreateFrame GameFontNormalLarge GameFontHighlightSmall GameFontNormal
-- luacheck: globals InputBoxTemplate UIPanelButtonTemplate
-- luacheck: globals GuildRoster C_GuildInfo
-- luacheck: globals C_Timer

-- Global table for storing everything
-- luacheck: ignore UnitName
local AutoGuild = {
	patterns = {
		level = {
			"^ding%p*$",
			"^Ding%p*$",
		},
		guild_join = {
			"has joined the guild."
		}
	},
	rate_limit = {
		last_message_sent = 0,
		min_message_time = 10,
		welcome_back_delay = 1
	},
	messages = {
		level_up = "ding",
		welcome_back = "wb",
		congratulations = "grats",
		welcome = "welcome"
	},
	features = {
		welcome_back = true,
		welcome = true,
		level_up = true,
		congratulations = true
	},
	channels = {
		guild = "GUILD"
	},
	subscription_events = {
		"CHAT_MSG_SYSTEM",
		"PLAYER_LEVEL_UP",
		"CHAT_MSG_GUILD",
		"PLAYER_LOGIN",
		"GUILD_ROSTER_UPDATE"
	},
	frame = {},
	player_name = UnitName("player")
};

local guildRosterReady = false;
local pendingWelcomePlayers = {};

if type(AutomaticGuildInteractionsDB) ~= "table" then
	AutomaticGuildInteractionsDB = {};
end

local function LoadSavedSettings()
	local saved = AutomaticGuildInteractionsDB;

	if type(saved.messages) == "table" then
		for setting, value in pairs(saved.messages) do
			if type(AutoGuild.messages[setting]) == "string" and type(value) == "string" then
				AutoGuild.messages[setting] = value;
			end
		end
	end

	if type(saved.min_message_time) == "number" and saved.min_message_time >= 0 then
		AutoGuild.rate_limit.min_message_time = saved.min_message_time;
	end

	if type(saved.welcome_back_delay) == "number" and saved.welcome_back_delay >= 0 then
		AutoGuild.rate_limit.welcome_back_delay = saved.welcome_back_delay;
	end

	if type(saved.features) == "table" then
		for feature, enabled in pairs(saved.features) do
			if type(AutoGuild.features[feature]) == "boolean" and type(enabled) == "boolean" then
				AutoGuild.features[feature] = enabled;
			end
		end
	end
end

local function SaveSettings()
	AutomaticGuildInteractionsDB = {
		messages = {
			level_up = AutoGuild.messages.level_up,
			welcome_back = AutoGuild.messages.welcome_back,
			congratulations = AutoGuild.messages.congratulations,
			welcome = AutoGuild.messages.welcome
		},
		min_message_time = AutoGuild.rate_limit.min_message_time,
		welcome_back_delay = AutoGuild.rate_limit.welcome_back_delay,
		features = {
			welcome_back = AutoGuild.features.welcome_back,
			welcome = AutoGuild.features.welcome,
			level_up = AutoGuild.features.level_up,
			congratulations = AutoGuild.features.congratulations
		}
	};
end

LoadSavedSettings();

-- Rate limited function to send messages to chat channel
function AutoGuild:SendMessage(message, channel)

	-- Check if the message is valid
	if message == nil or message == "" then
		return;
	end

	-- Check if the channel is valid
	if channel == nil or channel == "" then
		return;
	end

	-- Get the current timestamp (epoch in seconds)
	-- date and time are WoW APIs that map to the lua os.time and os.date APIs
	-- luacheck: push ignore 113
	local current_time = time(date("!*t"));
	-- luacheck: pop

	-- Check against the last timestamp
	-- The current time must be greater then the last time
	-- the message was sent plus the minimum time between messages
	if current_time > AutoGuild.rate_limit.min_message_time + AutoGuild.rate_limit.last_message_sent then

		-- Send the chat message
		-- luacheck: ignore SendChatMessage
		SendChatMessage(message, channel);

		-- Record the time we sent the message
		AutoGuild.rate_limit.last_message_sent = current_time;

	end

	return;
end

-- Trim any excess whitespace from the string
function AutoGuild:TrimString(input)

	-- Protect against a bad input
	if input == nil
	then
		return "";
	end

	-- Return the trimmed string
	return string.gsub(input, "%s+", "");
end

-- Return the first element from a string split operation
function AutoGuild:StringSplit(input, sep)

	-- Protect against a bad input
	if input == nil then
		return "";
	end

	-- Protect againt an optional argument
	if sep == nil then
		sep = "%s";
	end

	-- Table to store results
	local words = {};

	-- Insert the words into the table
	for word in string.gmatch(input, "([^"..sep.."]+)") do
		table.insert(words, word);
	end

	-- Return the results
	return words;
end

-- Check if the player that logged in was a guildy, and if so, send a welcome message
function AutoGuild:WelcomeBack(detected_player)
	if not AutoGuild.features.welcome_back then
		return;
	end

	-- Fetch the number of players in the guild
	-- luacheck: ignore GetNumGuildMembers
	local player_count = GetNumGuildMembers() or 0;
	local detected_name, detected_realm = detected_player:match("^([^%-]+)%-?(.*)$");

	-- Loop over the player indexes and see if any of them were the player that logged in
	for i=1,player_count do

		-- Get the name of the guild member of that index position
		-- luacheck: ignore GetGuildRosterInfo
		local guild_member = GetGuildRosterInfo(i);

		-- Roster names may include a realm when the system notice does not.
		local member_name, member_realm
		if type(guild_member) == "string" then
			member_name, member_realm = guild_member:match("^([^%-]+)%-?(.*)$");
		end
		if member_name == detected_name
			and (detected_realm == "" or member_realm == "" or detected_realm == member_realm) then
			C_Timer.After(AutoGuild.rate_limit.welcome_back_delay, function()
				if AutoGuild.features.welcome_back then
					AutoGuild.SendMessage(_, AutoGuild.messages.welcome_back, AutoGuild.channels.guild);
				end
			end);
			return;
		end
	end
end

-- Create a frame and register to the events we care about
-- luacheck: ignore CreateFrame
AutoGuild.frame = CreateFrame("Frame");
for _, event in pairs(AutoGuild.subscription_events) do
	AutoGuild.frame:RegisterEvent(event);
end

-- On receiving a message, run this function
AutoGuild.frame:SetScript("OnEvent", function (_, event, message, author)

	-- If we aren't in a guild then do nothing
	-- luacheck: ignore IsInGuild
	if not IsInGuild() then
		return;
	end

	if event == "PLAYER_LOGIN" then
		if C_GuildInfo and C_GuildInfo.GuildRoster then
			C_GuildInfo.GuildRoster();
		elseif GuildRoster then
			GuildRoster();
		end
		return;
	end

	if event == "GUILD_ROSTER_UPDATE" then
		guildRosterReady = true;
		for _, player in ipairs(pendingWelcomePlayers) do
			AutoGuild.WelcomeBack(_, player);
		end
		pendingWelcomePlayers = {};
		return;
	end

	-- Check if its a system message
	if event == "CHAT_MSG_SYSTEM" then

		-- Check if the message was a login message
		local logged_in_player
		if type(message) == "string" and message:match("has come online%.$") then
			logged_in_player = message:match("|Hplayer:([^|]+)|h")
				or message:match("^%[(.-)%] has come online%.$")
				or message:match("^(.+) has come online%.$");
		end
		if logged_in_player then
			if guildRosterReady then
				AutoGuild.WelcomeBack(_, logged_in_player);
			else
				table.insert(pendingWelcomePlayers, logged_in_player);
			end
			return;
		end

		-- Check if the message was a join message
		if not AutoGuild.features.welcome then
			return;
		end
		for _, pattern in pairs(AutoGuild.patterns.guild_join) do

			-- Don't check against our own messages
			if author:match(AutoGuild.player_name) then
				return;
			end

			if message:match(pattern) then
				AutoGuild.SendMessage(_, AutoGuild.messages.welcome, AutoGuild.channels.guild);
				return;
			end
		end

	-- end CHAT_MESSAGE_SYSTEM
	end

	-- Check if its a level up
	if event == "PLAYER_LEVEL_UP" then
		if AutoGuild.features.level_up then
			AutoGuild.SendMessage(_, AutoGuild.messages.level_up, AutoGuild.channels.guild);
		end
		return;
	-- end PLAYER_LEVEL_UP
	end

	-- Check if its a guild message
	if event == "CHAT_MSG_GUILD" then
		if not AutoGuild.features.congratulations then
			return;
		end

		-- Don't check against our own messages
		if author:match(AutoGuild.player_name) then
			return;
		end

		-- Check against the patterns for incoming level up messages
		for _, pattern in pairs(AutoGuild.patterns.level) do
			if message:match(pattern) then
				AutoGuild.SendMessage(_, AutoGuild.messages.congratulations, AutoGuild.channels.guild);
				return;
			end
		end

	-- end CHAT_MSG_GUILD
	end

end);

local optionsPanel = CreateFrame("Frame");
optionsPanel.name = "Automatic Guild Interactions";

local optionsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
optionsTitle:SetPoint("TOPLEFT", 16, -16);
optionsTitle:SetText(optionsPanel.name);

local optionsDescription = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
optionsDescription:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -8);
optionsDescription:SetText("Enable or disable features and customize messages and the minimum time between messages.");

local controls = {};
local featureDefinitions = {
	{ key = "welcome_back", label = "Welcome-back message" },
	{ key = "welcome", label = "New guild member message" },
	{ key = "level_up", label = "Level-up message" },
	{ key = "congratulations", label = "Congratulations message" }
};
local optionDefinitions = {
	{ key = "welcome_back", label = "Welcome-back message" },
	{ key = "welcome", label = "New guild member message" },
	{ key = "level_up", label = "Level-up message" },
	{ key = "congratulations", label = "Congratulations message" }
};

local function UpdateControlValues()
	for _, definition in ipairs(featureDefinitions) do
		controls["feature_" .. definition.key]:SetChecked(AutoGuild.features[definition.key]);
	end
	for _, definition in ipairs(optionDefinitions) do
		controls[definition.key]:SetText(AutoGuild.messages[definition.key]);
	end
	controls.min_message_time:SetText(tostring(AutoGuild.rate_limit.min_message_time));
	controls.welcome_back_delay:SetText(tostring(AutoGuild.rate_limit.welcome_back_delay));
end

local function CreateFeatureOption(definition, yOffset)
	local checkButton = CreateFrame("CheckButton", nil, optionsPanel, "UICheckButtonTemplate");
	checkButton:SetSize(24, 24);
	checkButton:SetPoint("TOPLEFT", 16, yOffset);

	local label = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	label:SetPoint("LEFT", checkButton, "RIGHT", 4, 0);
	label:SetText(definition.label);

	checkButton:SetScript("OnClick", function(self)
		AutoGuild.features[definition.key] = self:GetChecked();
		SaveSettings();
	end);
	controls["feature_" .. definition.key] = checkButton;
end

local function CreateTextOption(definition, yOffset)
	local label = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	label:SetPoint("TOPLEFT", 16, yOffset);
	label:SetText(definition.label);

	local editBox = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate");
	editBox:SetSize(250, 24);
	editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6);
	editBox:SetAutoFocus(false);
	editBox:SetScript("OnEnterPressed", function(self)
		AutoGuild.messages[definition.key] = self:GetText();
		SaveSettings();
		self:ClearFocus();
	end);
	editBox:SetScript("OnEditFocusLost", function(self)
		AutoGuild.messages[definition.key] = self:GetText();
		SaveSettings();
	end);
	editBox:SetScript("OnEscapePressed", function(self)
		self:SetText(AutoGuild.messages[definition.key]);
		self:ClearFocus();
	end);
	controls[definition.key] = editBox;
end

for index, definition in ipairs(featureDefinitions) do
	CreateFeatureOption(definition, -60 - ((index - 1) * 28));
end

for index, definition in ipairs(optionDefinitions) do
	CreateTextOption(definition, -180 - ((index - 1) * 58));
end

local delayLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
delayLabel:SetPoint("TOPLEFT", 16, -180 - (#optionDefinitions * 58));
delayLabel:SetText("Minimum time between messages (seconds)");

local delayEditBox = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate");
delayEditBox:SetSize(100, 24);
delayEditBox:SetPoint("TOPLEFT", delayLabel, "BOTTOMLEFT", 0, -6);
delayEditBox:SetAutoFocus(false);
delayEditBox:SetScript("OnEnterPressed", function(self)
	local delay = tonumber(self:GetText());
	if delay ~= nil and delay >= 0 then
		AutoGuild.rate_limit.min_message_time = delay;
		SaveSettings();
	end
	self:SetText(tostring(AutoGuild.rate_limit.min_message_time));
	self:ClearFocus();
end);
delayEditBox:SetScript("OnEditFocusLost", function(self)
	local delay = tonumber(self:GetText());
	if delay ~= nil and delay >= 0 then
		AutoGuild.rate_limit.min_message_time = delay;
		SaveSettings();
	end
	self:SetText(tostring(AutoGuild.rate_limit.min_message_time));
end);
delayEditBox:SetScript("OnEscapePressed", function(self)
	self:SetText(tostring(AutoGuild.rate_limit.min_message_time));
	self:ClearFocus();
end);
controls.min_message_time = delayEditBox;

local welcomeBackDelayLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
welcomeBackDelayLabel:SetPoint("TOPLEFT", delayEditBox, "BOTTOMLEFT", 0, -18);
welcomeBackDelayLabel:SetText("Welcome-back message delay (seconds)");

local welcomeBackDelayEditBox = CreateFrame("EditBox", nil, optionsPanel, "InputBoxTemplate");
welcomeBackDelayEditBox:SetSize(100, 24);
welcomeBackDelayEditBox:SetPoint("TOPLEFT", welcomeBackDelayLabel, "BOTTOMLEFT", 0, -6);
welcomeBackDelayEditBox:SetAutoFocus(false);
welcomeBackDelayEditBox:SetScript("OnEnterPressed", function(self)
	local delay = tonumber(self:GetText());
	if delay ~= nil and delay >= 0 then
		AutoGuild.rate_limit.welcome_back_delay = delay;
		SaveSettings();
	end
	self:SetText(tostring(AutoGuild.rate_limit.welcome_back_delay));
	self:ClearFocus();
end);
welcomeBackDelayEditBox:SetScript("OnEditFocusLost", function(self)
	local delay = tonumber(self:GetText());
	if delay ~= nil and delay >= 0 then
		AutoGuild.rate_limit.welcome_back_delay = delay;
		SaveSettings();
	end
	self:SetText(tostring(AutoGuild.rate_limit.welcome_back_delay));
end);
welcomeBackDelayEditBox:SetScript("OnEscapePressed", function(self)
	self:SetText(tostring(AutoGuild.rate_limit.welcome_back_delay));
	self:ClearFocus();
end);
controls.welcome_back_delay = welcomeBackDelayEditBox;

local restoreDefaultsButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate");
restoreDefaultsButton:SetSize(150, 24);
restoreDefaultsButton:SetPoint("TOPLEFT", welcomeBackDelayEditBox, "BOTTOMLEFT", -6, -18);
restoreDefaultsButton:SetText("Restore Defaults");
restoreDefaultsButton:SetScript("OnClick", function()
	AutoGuild.messages.welcome_back = "wb";
	AutoGuild.messages.welcome = "welcome";
	AutoGuild.messages.level_up = "ding";
	AutoGuild.messages.congratulations = "grats";
	AutoGuild.rate_limit.min_message_time = 10;
	AutoGuild.rate_limit.welcome_back_delay = 1;
	for _, definition in ipairs(featureDefinitions) do
		AutoGuild.features[definition.key] = true;
	end
	SaveSettings();
	UpdateControlValues();
end);

optionsPanel:SetScript("OnShow", UpdateControlValues);

if Settings and Settings.RegisterCanvasLayoutCategory then
	local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name);
	Settings.RegisterAddOnCategory(category);
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(optionsPanel);
end
