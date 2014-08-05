--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Total RP 3
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- imports
local Globals, Utils, Comm, Events = TRP3_API.globals, TRP3_API.utils, TRP3_API.communication, TRP3_API.events;
local loc = TRP3_API.locale.getText;
local unitIDToInfo, unitInfoToID = Utils.str.unitIDToInfo, Utils.str.unitInfoToID;
local get = TRP3_API.profile.getData;
local IsUnitIDKnown = TRP3_API.register.isUnitIDKnown;
local getUnitIDCurrentProfile, isIDIgnored = TRP3_API.register.getUnitIDCurrentProfile, TRP3_API.register.isIDIgnored;
local strsub, strlen, format, _G, pairs, tinsert, time = strsub, strlen, format, _G, pairs, tinsert, time;
local GetPlayerInfoByGUID, RemoveExtraSpaces, GetTime, PlaySound = GetPlayerInfoByGUID, RemoveExtraSpaces, GetTime, PlaySound;
local getConfigValue, registerConfigKey = TRP3_API.configuration.getValue, TRP3_API.configuration.registerConfigKey;
local oldChatFrameOnEvent;
local handleCharacterMessage;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Config
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local POSSIBLE_CHANNELS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM"
};

local CONFIG_HOOK_METHOD = "chat_method";
local CONFIG_NAME_METHOD = "chat_name";
local CONFIG_NAME_COLOR = "chat_color";
local CONFIG_NPC_TALK = "chat_npc_talk";
local CONFIG_NPC_TALK_PREFIX = "chat_npc_talk_p";
local CONFIG_USAGE = "chat_use_";

local function configHookingMethod()
	return getConfigValue(CONFIG_HOOK_METHOD);
end

local function configNameMethod()
	return getConfigValue(CONFIG_NAME_METHOD);
end

local function configShowNameCustomColors()
	return getConfigValue(CONFIG_NAME_COLOR);
end

local function configIsChannelUsed(channel)
	return getConfigValue(CONFIG_USAGE .. channel);
end

local function configDoHandleNPCTalk()
	return getConfigValue(CONFIG_NPC_TALK);
end

local function configNPCTalkPrefix()
	return getConfigValue(CONFIG_NPC_TALK_PREFIX);
end

local function createConfigPage()
	-- Config default value
	registerConfigKey(CONFIG_HOOK_METHOD, 1);
	registerConfigKey(CONFIG_NAME_METHOD, 2);
	registerConfigKey(CONFIG_NAME_COLOR, true);
	registerConfigKey(CONFIG_NPC_TALK, true);
	registerConfigKey(CONFIG_NPC_TALK_PREFIX, "|| ");

	local HOOK_METHOD_TAB = {
		{loc("CO_CHAT_MAIN_METHOD_1"), 1},
		{loc("CO_CHAT_MAIN_METHOD_2"), 2},
	}

	local NAMING_METHOD_TAB = {
		{loc("CO_CHAT_MAIN_NAMING_1"), 1},
		{loc("CO_CHAT_MAIN_NAMING_2"), 2},
		{loc("CO_CHAT_MAIN_NAMING_3"), 3},
	}

	-- Build configuration page
	local CONFIG_STRUCTURE = {
		id = "main_config_chatframe",
		menuText = loc("CO_CHAT"),
		pageText = loc("CO_CHAT"),
		elements = {
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_MAIN"),
			},
			{
				inherit = "TRP3_ConfigDropDown",
				widgetName = "TRP3_ConfigurationTooltip_Chat_HookMethod",
				title = loc("CO_CHAT_MAIN_METHOD"),
				help = loc("CO_CHAT_MAIN_METHOD_TT"),
				listContent = HOOK_METHOD_TAB,
				configKey = CONFIG_HOOK_METHOD,
				listWidth = nil,
				listCancel = true,
			},
			{
				inherit = "TRP3_ConfigDropDown",
				widgetName = "TRP3_ConfigurationTooltip_Chat_NamingMethod",
				title = loc("CO_CHAT_MAIN_NAMING"),
				listContent = NAMING_METHOD_TAB,
				configKey = CONFIG_NAME_METHOD,
				listWidth = nil,
				listCancel = true,
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_COLOR"),
				configKey = CONFIG_NAME_COLOR,
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_NPC"),
				configKey = CONFIG_NPC_TALK,
			},
			{
				inherit = "TRP3_ConfigEditBox",
				title = loc("CO_CHAT_MAIN_NPC_PREFIX"),
				configKey = CONFIG_NPC_TALK_PREFIX,
				help = loc("CO_CHAT_MAIN_NPC_PREFIX_TT")
			},
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_USE"),
			},
		}
	};

	for _, channel in pairs(POSSIBLE_CHANNELS) do
		registerConfigKey(CONFIG_USAGE .. channel, true);
		tinsert(CONFIG_STRUCTURE.elements, {
			inherit = "TRP3_ConfigCheck",
			title = _G[channel],
			configKey = CONFIG_USAGE .. channel,
		});
	end

	TRP3_API.configuration.registerConfigurationPage(CONFIG_STRUCTURE);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Utils
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function getCharacterClassColor(chatInfo, event, text, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, GUID)
	local color;
	if ( chatInfo and chatInfo.colorNameByClass and GUID ) then
		local localizedClass, englishClass = GetPlayerInfoByGUID(GUID);
		if englishClass and RAID_CLASS_COLORS[englishClass] then
			local classColorTable = RAID_CLASS_COLORS[englishClass];
			return ("|cff%.2x%.2x%.2x"):format(classColorTable.r*255, classColorTable.g*255, classColorTable.b*255);
		end
	end
end

local function getCharacterInfoTab(unitID)
	if unitID == Globals.player_id then
		return get("player");
	elseif IsUnitIDKnown(unitID) then
		return getUnitIDCurrentProfile(unitID) or {};
	end
	return {};
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Emote and OOC detection
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function configDoEmoteDetection()
	return true; -- TODO config
end

local function configEmoteDetectionPattern()
	return "(%*.-%*)"; -- TODO config
end

local function detectEmoteAndOOC(type, message)
	if configDoEmoteDetection() and message:find(configEmoteDetectionPattern()) then
		message = message:gsub(configEmoteDetectionPattern(), function(content)
			return "|cffff9900" .. content .. "|r";
		end);
	end
	return message;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- NPC talk detection
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local NPC_TALK_CHANNELS = {
	CHAT_MSG_SAY = 1, CHAT_MSG_EMOTE = 1, CHAT_MSG_PARTY = 1, CHAT_MSG_RAID = 1, CHAT_MSG_PARTY_LEADER = 1, CHAT_MSG_RAID_LEADER = 1
};
local NPC_TALK_PATTERNS;

local function handleNPCTalk(chatFrame, message, characterID, messageID)
	local playerLink = "|Hplayer:".. characterID .. ":" .. messageID .. "|h";
	for TALK_TYPE, TALK_CHANNEL in pairs(NPC_TALK_PATTERNS) do
		if message:find(TALK_TYPE) then
			local chatInfo = ChatTypeInfo[TALK_CHANNEL];
			local name = message:sub(4, message:find(TALK_TYPE) - 2); -- Isolate the name
			local content = message:sub(name:len() + 4);
			playerLink = playerLink .. name;
			chatFrame:AddMessage("|cffff9900" .. playerLink .. "|h|r" .. content, chatInfo.r, chatInfo.g, chatInfo.b, chatInfo.id);
			return;
		end
	end
	local chatInfo = ChatTypeInfo["MONSTER_EMOTE"];
	chatFrame:AddMessage(playerLink .. message:sub(4) .. "|h", chatInfo.r, chatInfo.g, chatInfo.b, chatInfo.id);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Chatframe management
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- Ideas:
-- Ignored to another chatframe (config)
-- Limit name length (config)

function handleCharacterMessage(chatFrame, event, ...)
	local characterName, characterColor;
	local message, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16 = ...;
	local languageHeader = "";
	local character, realm = unitIDToInfo(characterID);
	if not realm then -- Thanks Blizzard to not always send a full character ID
		realm = Globals.player_realm_id;
		characterID = unitInfoToID(character, realm);
	end
	local info = getCharacterInfoTab(characterID);
	
	-- Get chat type and configuration
	local type = strsub(event, 10);
	local chatInfo = ChatTypeInfo[type];
	
	-- Detect NPC talk pattern on authorized channels
	if message:sub(1, 3) == configNPCTalkPrefix() and configDoHandleNPCTalk() and NPC_TALK_CHANNELS[event] then
		handleNPCTalk(chatFrame, message, characterID, messageID);
		return false;
	end

	-- WHISPER and WHISPER_INFORM have the same chat info
	if ( strsub(type, 1, 7) == "WHISPER" ) then
		chatInfo = ChatTypeInfo["WHISPER"];
	end

	-- WHISPER respond
	if type == "WHISPER" then
		ChatEdit_SetLastTellTarget(characterID, type);
		if ( chatFrame.tellTimer and (GetTime() > chatFrame.tellTimer) ) then
			PlaySound("TellMessage");
		end
		chatFrame.tellTimer = GetTime() + CHAT_TELL_ALERT_TIME;
	end

	-- Character name
	if realm == Globals.player_realm_id then
		characterName = character;
	else
		characterName = characterID;
	end

	local nameMethod = configNameMethod();
	if nameMethod == 2 or nameMethod == 3 then -- TRP3 names
		if info.characteristics and info.characteristics.FN then
			characterName = info.characteristics.FN;
		end
		if nameMethod == 3 and info.characteristics and info.characteristics.LN then -- With last name
			characterName = characterName .. " " .. info.characteristics.LN;
		end
	end

	-- Custom character name color first
	if configShowNameCustomColors() and info.characteristics and info.characteristics.CH then
		characterColor = "|cff" .. info.characteristics.CH;
	end
	-- Then class color
	if not characterColor then
		characterColor = getCharacterClassColor(chatInfo, event, ...);
	end
	if characterColor then
		characterName = characterColor .. characterName .. "|r";
	end

	-- Language
	if ( (strlen(language) > 0) and (language ~= chatFrame.defaultLanguage) ) then
		languageHeader = "[" .. language .. "] ";
	end

	-- Show
	message = RemoveExtraSpaces(message);
	message = detectEmoteAndOOC(type, message);
	local playerLink = "|Hplayer:".. characterID .. ":" .. messageID .. "|h";
	local body;
	if type == "EMOTE" then
		body = format(_G["CHAT_"..type.."_GET"] .. message, playerLink .. characterName .. "|h");
	elseif type == "TEXT_EMOTE" then
		body = message;
		if characterID ~= Globals.player_id then
			body = body:gsub("^([^%s]+)", playerLink .. characterName .. "|h");
		end
	else
		body = format(_G["CHAT_"..type.."_GET"] .. languageHeader .. message, playerLink .. "[" .. characterName .. "]" .. "|h");
	end

	--Add Timestamps
	if ( CHAT_TIMESTAMP_FORMAT ) then
		body = BetterDate(CHAT_TIMESTAMP_FORMAT, time()) .. body;
	end

	chatFrame:AddMessage(body, chatInfo.r, chatInfo.g, chatInfo.b, chatInfo.id, false);

	return false;
end

local TREATABLE_EVENTS = {
	CHAT_MSG_SAY = handleCharacterMessage,
	CHAT_MSG_YELL = handleCharacterMessage,
	CHAT_MSG_PARTY = handleCharacterMessage,
	CHAT_MSG_RAID = handleCharacterMessage,
	CHAT_MSG_GUILD = handleCharacterMessage,
	CHAT_MSG_EMOTE = handleCharacterMessage,
	CHAT_MSG_TEXT_EMOTE = handleCharacterMessage,
	CHAT_MSG_PARTY_LEADER = handleCharacterMessage,
	CHAT_MSG_RAID_LEADER = handleCharacterMessage,
	CHAT_MSG_OFFICER = handleCharacterMessage,
	CHAT_MSG_WHISPER = handleCharacterMessage,
	CHAT_MSG_WHISPER_INFORM = handleCharacterMessage,
}

local function secureHook(event, func, ...)
	if configIsChannelUsed(event) and func then
		func(DEFAULT_CHAT_FRAME, event, ...);
	end
end

local function hooking()
	local hookingMethod = configHookingMethod();

	if hookingMethod == 1 then
		--[[
		The method 1 consists on replacing the original ChatFrame_OnEvent.
		The advantage is that we can prevent the original ChatFrame_OnEvent to show the messages we treated.
		The disadvantage is that it can create compatibility issues with any Chat addon, and must be maintained as Blizzard could change its code at any patch.
		]]

		-- Replace original chat frame on event
		oldChatFrameOnEvent = ChatFrame_OnEvent;
		local function chatFrameOnEvent(chatFrame, event, ...)
			if TREATABLE_EVENTS[event] and configIsChannelUsed(event) then
				local doOriginal = TREATABLE_EVENTS[event](chatFrame, event, ...);
				if doOriginal then
					oldChatFrameOnEvent(chatFrame, event, ...);
				end
			else
				oldChatFrameOnEvent(chatFrame, event, ...);
			end
		end
		ChatFrame_OnEvent = chatFrameOnEvent;

	else
		--[[
		The second method consists of staying completely independent from Blizzard code, only using events.
		The advantage is that there will be no compatibilities issues with others addon.
		The disadvantage is that we can't prevent the original ChatFrame_OnEvent to happend, so the user must configure himself the chat frame to not show the treated channels.
		]]

		-- Listen to event
		for event, func in pairs(TREATABLE_EVENTS) do
			Utils.event.registerHandler(event, function(...) secureHook(event, func, ...); end);
		end

	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Init
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function onLoaded()
	NPC_TALK_PATTERNS = {
		[loc("NPC_TALK_SAY_PATTERN")] = "MONSTER_SAY",
		[loc("NPC_TALK_YELL_PATTERN")] = "MONSTER_YELL",
		[loc("NPC_TALK_WHISPER_PATTERN")] = "MONSTER_WHISPER",
	};
	createConfigPage();
	hooking();
end

local MODULE_STRUCTURE = {
	["name"] = "Chat frames",
	["description"] = "Global enhancement for chat frames. Use roleplay information, detect emotes and OOC sentences and use colors.",
	["version"] = 1.000,
	["id"] = "trp3_chatframes",
	["onLoaded"] = onLoaded,
	["minVersion"] = 3,
};

TRP3_API.module.registerModule(MODULE_STRUCTURE);