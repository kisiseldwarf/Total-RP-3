-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local L = TRP3_API.loc;

TRP3_ProfileListElementMixin = {};

function TRP3_ProfileListElementMixin:OnLoad()
	self.NineSlice:SetCenterColor(0, 0, 0, 1);
	self.NineSlice:SetBorderColor(0.5, 0.5, 0.5, 1);
end

function TRP3_ProfileListElementMixin:OnEnter()
end

function TRP3_ProfileListElementMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_ProfileListElementMixin:Init(elementData)
end

TRP3_ProfileListFrameMixin = {};

function TRP3_ProfileListFrameMixin:OnLoad()
	self.EmptyText:SetText(L.PR_PROFILEMANAGER_EMPTY);

	self.ScrollView = CreateScrollBoxListLinearView();
	self.ScrollView:SetPadding(self.paddingTop, self.paddingBottom, self.paddingLeft, self.paddingRight, self.spacing);

	if TRP3_ClientFeatures.ScrollBox_10_0 then
		self.ScrollView:SetElementInitializer("TRP3_ProfileListElementTemplate", TRP3_ProfileListElementMixin.Init);
	else
		self.ScrollView:SetElementExtent(65);  -- Must match <Size> in XML.
		self.ScrollView:SetElementInitializer("Button", "TRP3_ProfileListElementTemplate", TRP3_ProfileListElementMixin.Init);
	end

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView);
end

function TRP3_ProfileListFrameMixin:OnProfileListUpdate()
	self:MarkDirty();
end

function TRP3_ProfileListFrameMixin:OnShow()
	TRP3_API.events.registerCallback("PROFILE_LIST_UPDATE", GenerateClosure(self.OnProfileListUpdate, self), "ProfileUITemp");
	self:UpdateImmediately();
end

function TRP3_ProfileListFrameMixin:OnHide()
	TRP3_API.events.unregisterCallback("ProfileUITemp");
end

function TRP3_ProfileListFrameMixin:OnUpdate()
	self:MarkClean();
	self:UpdateImmediately();
end

function TRP3_ProfileListFrameMixin:MarkDirty()
	self:SetScript("OnUpdate", self.OnUpdate);
end

function TRP3_ProfileListFrameMixin:MarkClean()
	self:SetScript("OnUpdate", nil);
end

function TRP3_ProfileListFrameMixin:UpdateImmediately()
	self:MarkClean();

	local provider = self:CreateDataProvider();
	self.EmptyText:SetShown(provider:IsEmpty());
	self.ScrollBox:SetDataProvider(provider);
end

local function CaseInsensitiveStringSearch(haystack, needle)
	haystack = string.utf8lower(haystack);
	needle = string.utf8lower(needle);

	local offset = 1;
	local plain = true;
	return string.find(haystack, needle, offset, plain);
end

local function SortProfilesByName(a, b)
	local profileNameA = TRP3_Profiles[a];
	local profileNameB = TRP3_Profiles[b];

	return strcmputf8i(profileNameA, profileNameB) < 0;
end

function TRP3_ProfileListFrameMixin:CreateDataProvider()
	local defaultProfileID = TRP3_API.configuration.getValue("default_profile_id");
	local searchText = string.utf8lower(TRP3_ProfileManagerSearch:GetText());

	local profiles = {};

	for profileID, profileData in pairs(TRP3_Profiles) do
		local searchName = profileData.profileName;

		if profileID ~= defaultProfileID and CaseInsensitiveStringSearch(searchName, searchText) then
			table.insert(profiles, profileID);
		end
	end

	table.sort(profiles, SortProfilesByName);

	if #profiles ~= 0 then
		table.insert(profiles, 1, defaultProfileID);
	end

	return CreateDataProvider(profiles);
end

