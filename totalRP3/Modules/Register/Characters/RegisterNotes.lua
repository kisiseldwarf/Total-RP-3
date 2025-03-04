-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

---@type TRP3_API
local _, TRP3_API = ...;
local Ellyb = Ellyb(...);

local loc = TRP3_API.loc;
local Globals = TRP3_API.globals;
local isUnitIDKnown = TRP3_API.register.isUnitIDKnown;
local hasProfile = TRP3_API.register.hasProfile;
local openMainFrame = TRP3_API.navigation.openMainFrame;
local getCurrentContext = TRP3_API.navigation.page.getCurrentContext;
local setupFieldSet = TRP3_API.ui.frame.setupFieldPanel;
local setTooltipForSameFrame = TRP3_API.ui.tooltip.setTooltipForSameFrame;
local stEtN = TRP3_API.utils.str.emptyToNil;

local GetCurrentUser = AddOn_TotalRP3.Player.GetCurrentUser;
local getPlayerCurrentProfile = TRP3_API.profile.getPlayerCurrentProfile;
local getPlayerCurrentProfileID = TRP3_API.profile.getPlayerCurrentProfileID;
local getConfigValue = TRP3_API.configuration.getValue;

local function displayNotes(context)

	local profileID = context.profileID;
	if context.isPlayer then
		profileID = getPlayerCurrentProfileID();
		TRP3_RegisterNotesViewAccount:Hide();
		TRP3_RegisterNotesViewProfile:SetPoint("BOTTOM", TRP3_RegisterNotesView, "BOTTOM", 0, 10);
	else
		TRP3_RegisterNotesViewProfile:SetPoint("BOTTOM", TRP3_RegisterNotesViewPoint, "TOP", 0, 5);
		TRP3_RegisterNotesViewAccount:Show();
	end

	local currentName = GetCurrentUser():GetRoleplayingName();
	local profileNotesTitle = loc.REG_PLAYER_NOTES_PROFILE_NONAME;
	if currentName then
		profileNotesTitle = string.format(loc.REG_PLAYER_NOTES_PROFILE, currentName);
	end
	TRP3_RegisterNotesViewProfileTitle:SetText(profileNotesTitle);

	assert(profileID, "No profileID in context !");

	local profileNotes = getPlayerCurrentProfile().notes;
	TRP3_RegisterNotesViewProfileScrollText:SetText(profileNotes and profileNotes[profileID] or "");
	TRP3_RegisterNotesViewAccountScrollText:SetText(TRP3_Notes and TRP3_Notes[profileID] or "");
end

local function onProfileNotesChanged()
	local context = getCurrentContext();
	local profileID = context.profileID;
	if context.isPlayer then
		profileID = getPlayerCurrentProfileID();
	end

	local profile = getPlayerCurrentProfile();
	if not profile.notes then
		profile.notes = {};
	end

	profile.notes[profileID] = stEtN(TRP3_RegisterNotesViewProfileScrollText:GetText());
end

local function onAccountNotesChanged()
	local context = getCurrentContext();
	local profileID = context.profileID;
	if context.isPlayer then
		profileID = getPlayerCurrentProfileID();
	end

	TRP3_Notes[profileID] = stEtN(TRP3_RegisterNotesViewAccountScrollText:GetText());
end

local function showNotesTab()
	local context = getCurrentContext();
	assert(context, "No context for page player_main !");
	assert(context.profile, "No profile in context");
	context.isEditMode = false;
	TRP3_ProfileReportButton:Hide();
	displayNotes(context);
	TRP3_RegisterNotes:Show();
end
TRP3_API.register.ui.showNotesTab = showNotesTab;

function TRP3_API.register.inits.notesInit()

	if not TRP3_Notes then
		TRP3_Notes = {};
	end

	setupFieldSet(TRP3_RegisterNotesView, loc.REG_PLAYER_NOTES, 150);

	TRP3_RegisterNotesViewAccountTitle:SetText(loc.REG_PLAYER_NOTES_ACCOUNT);

	setTooltipForSameFrame(TRP3_RegisterNotesViewProfileHelp, "LEFT", 0, 10, loc.REG_PLAYER_NOTES_PROFILE_NONAME, loc.REG_PLAYER_NOTES_PROFILE_HELP);
	setTooltipForSameFrame(TRP3_RegisterNotesViewAccountHelp, "LEFT", 0, 10, loc.REG_PLAYER_NOTES_ACCOUNT, loc.REG_PLAYER_NOTES_ACCOUNT_HELP);

	TRP3_RegisterNotesViewAccountScrollText:SetScript("OnTextChanged", onAccountNotesChanged);
	TRP3_RegisterNotesViewProfileScrollText:SetScript("OnTextChanged", onProfileNotesChanged);

	TRP3_API.Events.registerCallback(TRP3_API.Events.WORKFLOW_ON_LOADED, function()
		if not TRP3_API.target then
			-- Target bar module disabled.
			return;
		end

		local openPageByUnitID = TRP3_API.register.openPageByUnitID;
		local openNotesTab = TRP3_TabBar_Tab_5:GetScript("OnClick");    -- This was a quick workaround for RP.IO, is there a better option ?
		TRP3_API.target.registerButton({
			id = "za_notes",
			configText = loc.REG_NOTES_PROFILE,
			onlyForType = AddOn_TotalRP3.Enums.UNIT_TYPE.CHARACTER,
			condition = function(_, unitID)
				return (unitID == Globals.player_id and getPlayerCurrentProfileID() ~= getConfigValue("default_profile_id")) or (isUnitIDKnown(unitID) and hasProfile(unitID));
			end,
			onClick = function(unitID)
				openMainFrame();
				openPageByUnitID(unitID);
				openNotesTab();
			end,
			tooltip = loc.REG_NOTES_PROFILE,
			tooltipSub = loc.REG_NOTES_PROFILE_TT,
			icon = Ellyb.Icon(TRP3_InterfaceIcons.TargetNotes),
		});
	end)
end
