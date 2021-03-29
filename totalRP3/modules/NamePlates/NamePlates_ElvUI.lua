--[[
	Copyright 2021 Total RP 3 Development Team

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]--

local TRP3 = AddOn_TotalRP3;
local TRP3_API = select(2, ...);
local TRP3_NamePlatesUtil = TRP3_NamePlatesUtil;
local L = TRP3_API.loc;

--
-- TODO: Investigate the hide nameplate options, as these are NYI.
-- TODO: Localization rework to not need to modify existing strings further.
-- TODO: Add localization note that icon size isn't supported.
-- TODO: Add localization strings for the module name/description.
-- TODO: Override more tags (name:short, :veryshort, etc.)
-- TODO: Implement cropping (depends on the above)
--

TRP3_ElvUINamePlates = {};

function TRP3_ElvUINamePlates:OnModuleInitialize()
	local E = ElvUI and ElvUI[1];

	if not E or not E.NamePlates or not E.NamePlates.Initialized then
		-- The ElvUI nameplate module isn't initialized.
		return false, L.NAMEPLATES_MODULE_DISABLED_BY_DEPENDENCY;
	elseif TRP3_NAMEPLATES_ADDON ~= nil then
		-- Another nameplate decorator module met its own activation criteria.
		return false, L.NAMEPLATES_MODULE_DISABLED_BY_EXTERNAL;
	end

	TRP3_NAMEPLATES_ADDON = "ElvUI";
end

function TRP3_ElvUINamePlates:OnModuleEnable()
	if TRP3_NAMEPLATES_ADDON ~= "ElvUI" then
		return false, L.NAMEPLATES_MODULE_DISABLED_BY_EXTERNAL;
	end

	TRP3.NamePlates.RegisterCallback("OnUnitDisplayInfoUpdated", self.OnUnitDisplayInfoUpdated, self);

	self.oUF = ElvUI[1].oUF;

	self:RegisterOverrideTag("name", self.GetUnitNameText);
	self:RegisterOverrideTag("namecolor", self.GetUnitNameColor);
	self:RegisterOverrideTag("title", self.GetUnitFullTitle);
end

function TRP3_ElvUINamePlates:RegisterOverrideTag(tag, method, ...)
	local original = self.oUF.Tags.Methods[tag];
	local args = { n = select("#", ...), ... };

	self.oUF.Tags.Methods[tag] = function(unitToken, realUnitToken)
		local result;

		if true then
			result = method(self, unitToken, realUnitToken, original, unpack(args, 1, args.n));
		end

		if result == nil then
			result = original(unitToken, realUnitToken);
		end

		return result;
	end
end

function TRP3_ElvUINamePlates:RegisterPostUpdateHook(object, method, handler)
	local original = object[method];

	object[method] = function(...)
		return handler(self, original, ...);
	end
end

function TRP3_ElvUINamePlates:OnUnitDisplayInfoUpdated(unitToken)
	self:UpdateUnitFrameForUnit(unitToken);
end

function TRP3_ElvUINamePlates:GetUnitFrameForUnit(unitToken)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken);
	return nameplate and nameplate.unitFrame or nil;
end

function TRP3_ElvUINamePlates:UpdateUnitFrameForUnit(unitToken)
	local unitframe = self:GetUnitFrameForUnit(unitToken);

	if not unitframe then
		return;
	end

	if not unitframe.TRP3_initialized then
		self:RegisterPostUpdateHook(unitframe.Health, "PostUpdateColor", self.UpdateHealthColor);
		self:RegisterPostUpdateHook(unitframe.Portrait, "PostUpdate", self.UpdateIcon);
		unitframe.TRP3_initialized = true;
	end

	unitframe:UpdateTags();
	unitframe.Health:ForceUpdate();
	unitframe.Portrait:ForceUpdate();
end

function TRP3_ElvUINamePlates:GetUnitNameText(unitToken, realUnitToken, originalFunc)
	local displayInfo = TRP3.NamePlates.GetUnitDisplayInfo(unitToken);

	if not displayInfo then
		return;
	end

	local customNameText;

	if displayInfo.name then
		customNameText = displayInfo.name;  -- TODO: Cropping.
	else
		customNameText = originalFunc(unitToken, realUnitToken);
	end

	if displayInfo.roleplayStatus then
		customNameText = TRP3_NamePlatesUtil.PrependRoleplayStatusToText(customNameText, displayInfo.roleplayStatus);
	end

	return customNameText;
end

function TRP3_ElvUINamePlates:GetUnitNameColor(unitToken)
	local displayInfo = TRP3.NamePlates.GetUnitDisplayInfo(unitToken);

	if displayInfo and displayInfo.color and displayInfo.shouldColorName then
		return ColorMixin.GenerateHexColorMarkup(displayInfo.color);
	end
end

function TRP3_ElvUINamePlates:GetUnitFullTitle(unitToken)
	local displayInfo = TRP3.NamePlates.GetUnitDisplayInfo(unitToken);

	if displayInfo and displayInfo.fullTitle then
		return displayInfo.fullTitle;  -- TODO: Cropping.
	end
end

function TRP3_ElvUINamePlates:UpdateHealthColor(originalFunc, healthbar, unit, ...)
	local displayInfo = TRP3.NamePlates.GetUnitDisplayInfo(unit);

	if displayInfo and displayInfo.color and displayInfo.shouldColorHealth then
		healthbar:SetStatusBarColor(ColorMixin.GetRGB(displayInfo.color));
	elseif originalFunc then
		return originalFunc(healthbar, unit, ...);
	end
end

function TRP3_ElvUINamePlates:UpdateIcon(originalFunc, portrait, unit, ...)
	local displayInfo = TRP3.NamePlates.GetUnitDisplayInfo(unit);

	if displayInfo and displayInfo.icon then
		portrait:SetTexture(TRP3_API.utils.getIconTexture(displayInfo.icon));
		portrait:SetTexCoord(0, 1, 0, 1);
		portrait.backdrop:Hide();
	elseif originalFunc then
		return originalFunc(portrait, unit, ...);
	end
end

--
-- Module Registration
--

TRP3_API.module.registerModule({
	id = "trp3_elvui_nameplates",
	name = L.ELVUI_NAMEPLATES_MODULE_NAME,
	description = L.ELVUI_NAMEPLATES_MODULE_DESCRIPTION,
	version = 1,
	minVersion = 92,
	requiredDeps = { { "trp3_nameplates", 1 } },
	onInit = function() return TRP3_ElvUINamePlates:OnModuleInitialize(); end,
	onStart = function() return TRP3_ElvUINamePlates:OnModuleEnable(); end,
});

