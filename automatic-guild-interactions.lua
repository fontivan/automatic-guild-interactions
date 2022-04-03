
-- Global table for storing everything
-- luacheck: ignore UnitName
local AutoGuild = {
	patterns = {
		login = {
			"has come online."
		},
		level = {
			"ding"
		}
	},
	rate_limit = {
		last_message_sent = 0,
		min_message_time = 10
	},
	frame = {},
	player_name = UnitName("player"),
	debug_logs = false
};

-- Log a debug message if the debug flag is set
function AutoGuild:LogDebugMessage(message)

	-- Return if debug logs is not enabled
	if not AutoGuild.debug_logs then
		return;
	end

	-- Print the debug message
	print(message)
end

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
	-- luacheck ignore: time
	-- luacheck ignore: date
	local current_time = time(date("!*t"));

	-- Check against the last timestamp
	-- The current time must be greater then the last time
	-- the message was sent plus the minimum time between messages
	if current_time > AutoGuild.rate_limit.min_message_time + AutoGuild.rate_limit.last_message_sent then

		-- Send the chat message
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

	AutoGuild.LogDebugMessage(_, "StringSplit input:" .. input)

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
	AutoGuild.LogDebugMessage(_, "WelcomeBack message: " .. message);
	splits = AutoGuild.StringSplit(_, message);
	local detected_player = splits[1];
	AutoGuild.LogDebugMessage(_, "WelcomeBack detected_player: " .. detected_player);

	-- Loop over the player indexes and see if any of them were the player that logged in
	for i=1,player_count+1 do

		-- Get the name of the guild member of that index position
		splits = AutoGuild.StringSplit(_, GetGuildRosterInfo(i), "-");
		local guild_member = splits[1];

		-- If the person that just logged in is in our guild then welcome them back
		if detected_player:match(guild_member) then
			AutoGuild.SendMessage(_, "wb", "GUILD");
			return;
		end
	end
end

-- Create a frame and register to the system messages
AutoGuild.frame = CreateFrame("Frame");
AutoGuild.frame:RegisterEvent("CHAT_MSG_SYSTEM");
AutoGuild.frame:RegisterEvent("PLAYER_LEVEL_UP");
AutoGuild.frame:RegisterEvent("CHAT_MSG_GUILD");

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

	-- end CHAT_MESSAGE_SYSTEM
	end

	-- Check if its a level up
	if event == "PLAYER_LEVEL_UP" then
		AutoGuild.SendMessage(_, "ding", "GUILD");
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
				AutoGuild.SendMessage(_, "grats", "GUILD");
				return;
			end
		end

	-- end CHAT_MSG_GUILD
	end

end);
