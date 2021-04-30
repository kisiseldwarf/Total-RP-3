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

	------------------------------------------------------------------------

	This file is largely a verbatim copy of the ScrollBox infrastructure
	implemented in retail patch 9.1 and TBC patch 2.5.1 for compatibility
	with Classic. When Classic receives this support, these will be removed.
]]--

-- luacheck: no unused (unused arguments are from the original source)

TRP3_ScrollUtil = {};

-- For convenience of public addons.
function TRP3_ScrollUtil.AddAcquiredFrameCallback(scrollBox, callback, owner, iterateExisting)
	if iterateExisting then
		scrollBox:ForEachFrame(callback);
	end

	local function OnAcquired(o, frame, elementData, new)
		callback(frame, elementData, new);
	end
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnAcquiredFrame, OnAcquired, owner);
end

function TRP3_ScrollUtil.AddReleasedFrameCallback(scrollBox, callback, owner)
	local function OnReleased(o, frame, elementData)
		callback(frame, elementData);
	end
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnReleasedFrame, OnReleased, owner);
end

local function RegisterWithScrollBox(scrollBox, scrollBar)
	local onScrollBoxScroll = function(o, scrollPercentage, visibleExtentPercentage, panExtentPercentage)
		scrollBar:SetScrollPercentage(scrollPercentage, TRP3_ScrollBoxConstants.NoScrollInterpolation);
		scrollBar:SetVisibleExtentPercentage(visibleExtentPercentage);
		scrollBar:SetPanExtentPercentage(panExtentPercentage);
	end;
	scrollBox:RegisterCallback(TRP3_BaseScrollBoxEvents.OnScroll, onScrollBoxScroll, scrollBar);

	local onSizeChanged = function(o, width, height, visibleExtentPercentage)
		scrollBar:SetVisibleExtentPercentage(visibleExtentPercentage);
	end;
	scrollBox:RegisterCallback(TRP3_BaseScrollBoxEvents.OnSizeChanged, onSizeChanged, scrollBar);

	local onScrollBoxAllowScroll = function(o, allowScroll)
		scrollBar:SetScrollAllowed(allowScroll);
	end;
	scrollBox:RegisterCallback(TRP3_BaseScrollBoxEvents.OnAllowScrollChanged, onScrollBoxAllowScroll, scrollBar);
end

local function RegisterWithScrollBar(scrollBox, scrollBar)
	local onScrollBarScroll = function(o, scrollPercentage)
		scrollBox:SetScrollPercentage(scrollPercentage, TRP3_ScrollBoxConstants.NoScrollInterpolation);
	end;
	scrollBar:RegisterCallback(TRP3_BaseScrollBoxEvents.OnScroll, onScrollBarScroll, scrollBox);

	local onScollBarAllowScroll = function(o, allowScroll)
		scrollBox:SetScrollAllowed(allowScroll);
	end;

	scrollBar:RegisterCallback(TRP3_BaseScrollBoxEvents.OnAllowScrollChanged, onScollBarAllowScroll, scrollBox);
end

local function InitScrollBar(scrollBox, scrollBar)
	scrollBar:Init(scrollBox:GetVisibleExtentPercentage(), scrollBox:CalculatePanExtentPercentage());
end

-- ScrollBoxList variant intended for the majority of registration and initialization cases.
function TRP3_ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollBoxView)
	TRP3_ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar);
	scrollBox:Init(scrollBoxView);
	InitScrollBar(scrollBox, scrollBar);
end

-- ScrollBox variant intended for the majority of registration and initialization cases.
-- Currently implemented identically to InitScrollBoxListWithScrollBar but allows for
-- changes to be made easier without public deprecation problems.
function TRP3_ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, scrollBoxView)
	TRP3_ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar);
	scrollBox:Init(scrollBoxView);
	InitScrollBar(scrollBox, scrollBar);
end

-- Rarely used in cases where the ScrollBox was previously initialized.
function TRP3_ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar)
	RegisterWithScrollBox(scrollBox, scrollBar);
	RegisterWithScrollBar(scrollBox, scrollBar);

	if not scrollBar:CanInterpolateScroll() or not scrollBox:CanInterpolateScroll() then
		scrollBar:SetInterpolateScroll(false);
		scrollBox:SetInterpolateScroll(false);
	end
end

-- Rarely used in cases where a ScrollBox was previously initialized.
function TRP3_ScrollUtil.InitScrollBar(scrollBox, scrollBar)
	RegisterWithScrollBar(scrollBox, scrollBar);
	InitScrollBar(scrollBox, scrollBar);
end

-- Utility for managing the visibility of a ScrollBar and reanchoring of the
-- ScrollBox as the visibility changes.
TRP3_ManagedScrollBarVisibilityBehaviorMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_ManagedScrollBarVisibilityBehaviorMixin:GenerateCallbackEvents(
	{
		"OnVisibilityChanged",
	}
);

function TRP3_ManagedScrollBarVisibilityBehaviorMixin:Init(scrollBox, scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)
	TRP3_CallbackRegistryMixin.OnLoad(self);

	self.scrollBox = scrollBox;
	self.scrollBar = scrollBar;

	if scrollBoxAnchorsWithBar and scrollBoxAnchorsWithoutBar then
		self.scrollBoxAnchorsWithBar = scrollBoxAnchorsWithBar;
		self.scrollBoxAnchorsWithoutBar = scrollBoxAnchorsWithoutBar;
	end

	scrollBox:RegisterCallback(TRP3_BaseScrollBoxEvents.OnLayout, self.EvaluateVisibility, self);

	local onSizeChanged = function(o, width, height, visibleExtentPercentage)
		self:EvaluateVisibility();
	end;
	scrollBox:RegisterCallback(TRP3_BaseScrollBoxEvents.OnSizeChanged, onSizeChanged, scrollBar);

	local force = true;
	self:EvaluateVisibility(force);
end

function TRP3_ManagedScrollBarVisibilityBehaviorMixin:GetScrollBox()
	return self.scrollBox;
end

function TRP3_ManagedScrollBarVisibilityBehaviorMixin:GetScrollBar()
	return self.scrollBar;
end

function TRP3_ManagedScrollBarVisibilityBehaviorMixin:EvaluateVisibility(force)
	local visible = self:GetScrollBox():HasScrollableExtent();
	if not force and visible == self:GetScrollBar():IsShown() then
		return;
	end

	self:GetScrollBar():SetShown(visible);

	if self.scrollBoxAnchorsWithBar and self.scrollBoxAnchorsWithoutBar then
		local anchors = visible and self.scrollBoxAnchorsWithBar or self.scrollBoxAnchorsWithoutBar;
		if self.appliedAnchors == anchors then
			return;
		end
		self.appliedAnchors = anchors;

		local scrollBox = self:GetScrollBox();
		scrollBox:ClearAllPoints();

		local clearAllPoints = false;
		for index, anchor in ipairs(anchors) do
			anchor:SetPoint(scrollBox, clearAllPoints);
		end
	end

	self:TriggerEvent(TRP3_ManagedScrollBarVisibilityBehaviorMixin.Event.OnVisibilityChanged, visible);
end

function TRP3_ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar)
	local behavior = CreateFromMixins(TRP3_ManagedScrollBarVisibilityBehaviorMixin);
	behavior:Init(scrollBox, scrollBar, scrollBoxAnchorsWithBar, scrollBoxAnchorsWithoutBar);
	return behavior;
end

TRP3_SelectionBehaviorMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_SelectionBehaviorPolicy =
{
	Deselectable = 1,
};

TRP3_SelectionBehaviorMixin:GenerateCallbackEvents(
	{
		"OnSelectionChanged",
	}
);

function TRP3_SelectionBehaviorMixin.IsSelected(frame)
	return frame and TRP3_SelectionBehaviorMixin.IsElementDataSelected(frame:GetElementData()) or false;
end

function TRP3_SelectionBehaviorMixin.IsElementDataSelected(elementData)
	return elementData and elementData.selected or false;
end

function TRP3_SelectionBehaviorMixin:OnLoad(scrollBox, selectionPolicy)
	TRP3_CallbackRegistryMixin.OnLoad(self);

	self.scrollBox = scrollBox;

	self:SetSelectionPolicy(selectionPolicy);
end

function TRP3_SelectionBehaviorMixin:SetSelectionPolicy(selectionPolicy)
	self.selectionPolicy = selectionPolicy;
end

function TRP3_SelectionBehaviorMixin:HasSelection()
	return #self:GetSelectedElementData() > 0;
end

function TRP3_SelectionBehaviorMixin:GetSelectedElementData()
	local selected = {};
	local dataProvider = self.scrollBox:GetDataProvider();
	if dataProvider then
		for index, elementData in dataProvider:Enumerate() do
			if elementData.selected then
				table.insert(selected, elementData);
			end
		end
	end
	return selected;
end

function TRP3_SelectionBehaviorMixin:IsDeselectable()
	return self.selectionPolicy == TRP3_SelectionBehaviorPolicy.Deselectable;
end

function TRP3_SelectionBehaviorMixin:DeselectByPredicate(predicate)
	local deselected = {};
	local dataProvider = self.scrollBox:GetDataProvider();
	if dataProvider then
		for index, elementData in dataProvider:Enumerate() do
			if predicate(elementData) then
				elementData.selected = nil;
				table.insert(deselected, elementData);
			end
		end
	end
	return deselected;
end

function TRP3_SelectionBehaviorMixin:DeselectSelectedElements()
	return self:DeselectByPredicate(function(elementData)
		return elementData.selected;
	end);
end

function TRP3_SelectionBehaviorMixin:ClearSelections()
	local deselected = self:DeselectSelectedElements();
	for index, data in ipairs(deselected) do
		self:TriggerEvent(TRP3_SelectionBehaviorMixin.Event.OnSelectionChanged, data, false);
	end
end

function TRP3_SelectionBehaviorMixin:ToggleSelectElementData(elementData)
	local oldSelected = elementData.selected;
	if oldSelected and not self:IsDeselectable() then
		return;
	end

	local newSelected = not oldSelected;
	self:SetElementDataSelected_Internal(elementData, newSelected);
end

function TRP3_SelectionBehaviorMixin:SelectElementData(elementData)
	self:SetElementDataSelected_Internal(elementData, true);
end

function TRP3_SelectionBehaviorMixin:SetElementDataSelected_Internal(elementData, newSelected)
	local deselected = nil;
	if newSelected then
		-- Works under the current single selection policy. When multi-select is added,
		-- change this.
		deselected = self:DeselectByPredicate(function(data)
			return data.selected and data ~= elementData;
		end);
	end

	local changed = (not not elementData.selected) ~= newSelected;
	elementData.selected = newSelected;

	if deselected then
		for index, data in ipairs(deselected) do
			self:TriggerEvent(TRP3_SelectionBehaviorMixin.Event.OnSelectionChanged, data, false);
		end
	end

	if changed then
		if elementData.scrollBoxChild then
			self:TriggerEvent(TRP3_SelectionBehaviorMixin.Event.OnSelectionChanged, elementData, newSelected);
		end
	end
end

function TRP3_SelectionBehaviorMixin:Select(frame)
	self:SelectElementData(frame:GetElementData());
end

function TRP3_SelectionBehaviorMixin:ToggleSelect(frame)
	self:ToggleSelectElementData(frame:GetElementData());
end

function TRP3_ScrollUtil.AddSelectionBehavior(scrollBox, selectionPolicy)
	local behavior = CreateFromMixins(TRP3_SelectionBehaviorMixin);
	behavior:OnLoad(scrollBox, selectionPolicy);
	return behavior;
end

-- Frame must be a EventButton to support the OnSizeChanged callback.
function TRP3_ScrollUtil.AddResizableChildrenBehavior(scrollBox)
	local onSizeChanged = function(o, width, height)
		scrollBox:QueueUpdate();
	end;
	local onSubscribe = function(frame, elementData)
		frame:RegisterCallback(TRP3_BaseScrollBoxEvents.OnSizeChanged, onSizeChanged, scrollBox);
	end

	local onAcquired = function(o, frame, elementData)
		onSubscribe(frame, elementData);
	end;
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnAcquiredFrame, onAcquired, onAcquired);

	local onReleased = function(o, frame, elementData)
		frame:UnregisterCallback(TRP3_BaseScrollBoxEvents.OnSizeChanged, scrollBox);
	end;
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnReleasedFrame, onReleased, onReleased);

	scrollBox:ForEachFrame(onSubscribe);
end

function TRP3_ScrollUtil.RegisterTableBuilder(scrollBox, tableBuilder, elementDataTranslator)
	local onAcquired = function(o, frame, elementData)
		tableBuilder:AddRow(frame, elementDataTranslator(elementData));
	end;
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnAcquiredFrame, onAcquired, onAcquired);

	local onReleased = function(o, frame, elementData)
		tableBuilder:RemoveRow(frame, elementDataTranslator(elementData));
	end;
	scrollBox:RegisterCallback(TRP3_ScrollBoxListMixin.Event.OnReleasedFrame, onReleased, onReleased);
end

function TRP3_ScrollUtil.CreateScrollBoxPadding(top, bottom, left, right, spacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxPaddingMixin, top, bottom, left, right, spacing);
end

function TRP3_ScrollUtil.CreateScrollBoxLinearPadding(top, bottom, left, right, spacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxLinearPaddingMixin, top, bottom, left, right, spacing);
end

function TRP3_ScrollUtil.CreateScrollBoxListLinearView(top, bottom, left, right, spacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxListLinearViewMixin, top or 0, bottom or 0, left or 0, right or 0, spacing or 0);
end

function TRP3_ScrollUtil.CreateScrollBoxLinearView(top, bottom, left, right, spacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxLinearViewMixin, top or 0, bottom or 0, left or 0, right or 0, spacing or 0);
end

function TRP3_ScrollUtil.CreateScrollBoxGridPadding(top, bottom, left, right, horizontalSpacing, verticalSpacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxGridPaddingMixin, top, bottom, left, right, horizontalSpacing, verticalSpacing);
end

function TRP3_ScrollUtil.CreateScrollBoxListGridView(stride, top, bottom, left, right, horizontalSpacing, verticalSpacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_ScrollBoxListGridViewMixin, stride or 1, top or 0, bottom or 0, left or 0, right or 0, horizontalSpacing or 0, verticalSpacing or 0);
end
