
-- luacheck: ignore _
-- luacheck: ignore self
-- luacheck: globals AutomaticGuildInteractionsDB Settings InterfaceOptions_AddCategory
-- luacheck: globals CreateFrame GameFontNormalLarge GameFontHighlightSmall GameFontNormal
-- luacheck: globals InputBoxTemplate UIPanelButtonTemplate

-- Global table for storing everything
-- luacheck: ignore UnitName
local AutoGuild = {
	patterns = {
		login = {
			"has come online."
		},
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
		min_message_time = 10
	},
	messages = {
		level_up = "ding",
		welcome_back = "wb",
		congratulations = "grats",
		welcome = "welcome"
	},
	channels = {
		guild = "GUILD"
	},
	subscription_events = {
		"CHAT_MSG_SYSTEM",
		"PLAYER_LEVEL_UP",
		"CHAT_MSG_GUILD"
	},
	frame = {},
	player_name = UnitName("player")
};

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
end

local function SaveSettings()
	AutomaticGuildInteractionsDB = {
		messages = {
			level_up = AutoGuild.messages.level_up,
			welcome_back = AutoGuild.messages.welcome_back,
			congratulations = AutoGuild.messages.congratulations,
			welcome = AutoGuild.messages.welcome
		},
		min_message_time = AutoGuild.rate_limit.min_message_time
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
function AutoGuild:WelcomeBack(message)

	-- Fetch the number of players in the guild
	-- luacheck: ignore GetNumGuildMembers
	local player_count = GetNumGuildMembers();

	-- Temp variable to store split results
	local splits

	-- Strip the player name of the person who just logged in
	splits = AutoGuild.StringSplit(_, message);
	local detected_player = splits[1];

	-- Loop over the player indexes and see if any of them were the player that logged in
	for i=1,player_count+1 do

		-- Get the name of the guild member of that index position
		-- luacheck: ignore GetGuildRosterInfo
		splits = AutoGuild.StringSplit(_, GetGuildRosterInfo(i), "-");
		local guild_member = splits[1];

		if guild_member == nil or guild_member == "" then
			return;
		end

		-- If the person that just logged in is in our guild then welcome them back
		if detected_player:match(guild_member) then
			AutoGuild.SendMessage(_, AutoGuild.messages.welcome_back, AutoGuild.channels.guild);
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

	-- Check if its a system message
	if event == "CHAT_MSG_SYSTEM" then

		-- Check if the message was a login message
		for _, pattern in pairs(AutoGuild.patterns.login) do
			if message:match(pattern) then
				AutoGuild.WelcomeBack(_, message);
				return;
			end
		end

		-- Check if the message was a join message
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
		AutoGuild.SendMessage(_, AutoGuild.messages.level_up, AutoGuild.channels.guild);
		return;
	-- end PLAYER_LEVEL_UP
	end

	-- Check if its a guild message
	if event == "CHAT_MSG_GUILD" then

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
optionsDescription:SetText("Customize the messages sent by the addon and the minimum time between messages.");

local controls = {};
local optionDefinitions = {
	{ key = "welcome_back", label = "Welcome-back message" },
	{ key = "welcome", label = "New guild member message" },
	{ key = "level_up", label = "Level-up message" },
	{ key = "congratulations", label = "Congratulations message" }
};

local function UpdateControlValues()
	for _, definition in ipairs(optionDefinitions) do
		controls[definition.key]:SetText(AutoGuild.messages[definition.key]);
	end
	controls.min_message_time:SetText(tostring(AutoGuild.rate_limit.min_message_time));
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

for index, definition in ipairs(optionDefinitions) do
	CreateTextOption(definition, -68 - ((index - 1) * 58));
end

local delayLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
delayLabel:SetPoint("TOPLEFT", 16, -68 - (#optionDefinitions * 58));
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

local restoreDefaultsButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate");
restoreDefaultsButton:SetSize(150, 24);
restoreDefaultsButton:SetPoint("TOPLEFT", delayEditBox, "BOTTOMLEFT", -6, -18);
restoreDefaultsButton:SetText("Restore Defaults");
restoreDefaultsButton:SetScript("OnClick", function()
	AutoGuild.messages.welcome_back = "wb";
	AutoGuild.messages.welcome = "welcome";
	AutoGuild.messages.level_up = "ding";
	AutoGuild.messages.congratulations = "grats";
	AutoGuild.rate_limit.min_message_time = 10;
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
