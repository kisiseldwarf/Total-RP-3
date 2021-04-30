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

-- Common event definitions as a work-around for derivation problems with TRP3_CallbackRegistryMixin.
TRP3_BaseScrollBoxEvents =
{
	"OnAllowScrollChanged",
	"OnSizeChanged",
	"OnScroll",
	"OnLayout",
};

TRP3_BaseScrollBoxEvents = TRP3_TableUtil.CopyValuesAsKeys(TRP3_BaseScrollBoxEvents);

TRP3_ScrollBoxConstants =
{
	NoScrollInterpolation = true,
	RetainScrollPosition = true,
	AlignBegin = 0,
	AlignCenter = .5,
	AlignEnd = 1,
	AlignNearest = -1,
	ScrollBegin = TRP3_MathUtil.Epsilon,
	ScrollEnd = (1 - TRP3_MathUtil.Epsilon),
};

-- TRP3_ScrollBoxBaseMixin includes TRP3_CallbackRegistryMixin but the derived mixins are responsible
-- for generating the events.
TRP3_ScrollBoxBaseMixin = CreateFromMixins(TRP3_CallbackRegistryMixin, TRP3_ScrollControllerMixin);

function TRP3_ScrollBoxBaseMixin:OnLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);
	TRP3_ScrollControllerMixin.OnLoad(self);

	self.scrollInternal = TRP3_FunctionUtil.GenerateClosure(self.SetScrollPercentageInternal, self);

	local scrollTarget = self:GetScrollTarget();
	scrollTarget:RegisterCallback(TRP3_BaseScrollBoxEvents.OnSizeChanged, self.OnScrollTargetSizeChanged, self);

	self.Shadows:SetFrameLevel(scrollTarget:GetFrameLevel() + 2);
	self:GetUpperShadowTexture():SetAtlas(self.upperShadow, TRP3_TextureKitConstants.UseAtlasSize);
	self:GetLowerShadowTexture():SetAtlas(self.lowerShadow, TRP3_TextureKitConstants.UseAtlasSize);
end

function TRP3_ScrollBoxBaseMixin:Init(view)
	self:SetView(view);
	self:ScrollToBegin();
end

function TRP3_ScrollBoxBaseMixin:SetView(view)
	local oldDataProvider = nil;
	local oldView = self:GetView();
	if oldView then
		oldDataProvider = oldView:GetDataProvider();
		oldView:Flush();
	end

	self.view = view;
	view:SetScrollTarget(self:GetScrollTarget());

	local isHorizontal = view:IsHorizontal();
	self:SetHorizontal(isHorizontal);

	local upperShadowTexture = self:GetUpperShadowTexture();
	upperShadowTexture:ClearAllPoints();
	upperShadowTexture:SetPoint("TOPLEFT");
	upperShadowTexture:SetPoint(isHorizontal and "BOTTOMLEFT" or "TOPRIGHT");

	local lowerShadowTexture = self:GetLowerShadowTexture();
	lowerShadowTexture:ClearAllPoints();
	lowerShadowTexture:SetPoint(isHorizontal and "TOPRIGHT" or "BOTTOMLEFT");
	lowerShadowTexture:SetPoint(isHorizontal and "BOTTOMRIGHT" or "BOTTOMRIGHT");

	if oldDataProvider then
		view:SetDataProvider(oldDataProvider);
	end
end

function TRP3_ScrollBoxBaseMixin:GetView()
	return self.view;
end

function TRP3_ScrollBoxBaseMixin:GetScrollTarget()
	return self.ScrollTarget;
end

function TRP3_ScrollBoxBaseMixin:OnSizeChanged(width, height)
	self:Update();

	self:TriggerEvent("OnSizeChanged", width, height, self:GetVisibleExtentPercentage());
end

function TRP3_ScrollBoxBaseMixin:QueueUpdate()
	self:SetScript("OnUpdate", self.UpdateImmediately);
end

function TRP3_ScrollBoxBaseMixin:UpdateImmediately()
	self:SetScript("OnUpdate", nil);
	self:FullUpdate();
end

function TRP3_ScrollBoxBaseMixin:OnScrollTargetSizeChanged(width, height)
	self:QueueUpdate();
end

function TRP3_ScrollBoxBaseMixin:SetUpdateLocked(locked)
	self.updateLock = locked;
end

function TRP3_ScrollBoxBaseMixin:IsUpdateLocked()
	return self.updateLock;
end

function TRP3_ScrollBoxBaseMixin:FullUpdate()
	local oldScrollOffset = self:GetDerivedScrollOffset();

	local recalculate = true;
	self:GetDerivedExtent(recalculate);

	local scrollRange = self:GetDerivedScrollRange();
	if scrollRange > 0 then
		local deltaScrollOffset = (self:GetDerivedScrollOffset() - oldScrollOffset);
		local scrollPercentage = self:GetScrollPercentage() - (deltaScrollOffset / scrollRange);
		self:SetScrollPercentageInternal(scrollPercentage, TRP3_ScrollBoxConstants.NoScrollInterpolation);
	else
		self:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
	end

	self:SetPanExtentPercentage(self:CalculatePanExtentPercentage());

	local forceLayout = true;
	self:Update(forceLayout);

	self:TriggerEvent(TRP3_BaseScrollBoxEvents.OnLayout);
end

function TRP3_ScrollBoxBaseMixin:Layout()
	local view = self:GetView();
	if view then
		self:SetFrameExtent(self:GetScrollTarget(), view:Layout());
	end
end

function TRP3_ScrollBoxBaseMixin:SetScrollTargetOffset(offset)
	local view = self:GetView();
	if view then
		local scrollTarget = self:GetScrollTarget();
		if self:IsHorizontal() then
			scrollTarget:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, -self:GetTopPadding());
			scrollTarget:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -offset, self:GetBottomPadding());
		else
			scrollTarget:SetPoint("TOPLEFT", self, "TOPLEFT", self:GetLeftPadding(), offset);
			scrollTarget:SetPoint("TOPRIGHT", self, "TOPRIGHT", -self:GetRightPadding(), offset);
		end

		self:TriggerEvent(TRP3_BaseScrollBoxEvents.OnScroll, self:GetScrollPercentage(), self:GetVisibleExtentPercentage(), self:GetPanExtentPercentage());

		self:SetShadowsShown(self:HasScrollableExtent(), self:GetDerivedScrollOffset() > 0);
	end
end

function TRP3_ScrollBoxBaseMixin:ScrollInDirection(scrollPercentage, direction)
	TRP3_ScrollControllerMixin.ScrollInDirection(self, scrollPercentage, direction);

	self:Update();
end

function TRP3_ScrollBoxBaseMixin:ScrollToBegin(noInterpolation)
	self:SetScrollPercentage(0, noInterpolation);
end

function TRP3_ScrollBoxBaseMixin:ScrollToEnd(noInterpolation)
	self:SetScrollPercentage(1, noInterpolation);
end

function TRP3_ScrollBoxBaseMixin:IsAtBegin()
	return TRP3_MathUtil.ApproximatelyEqual(self:GetScrollPercentage(), 0);
end

function TRP3_ScrollBoxBaseMixin:IsAtEnd()
	return TRP3_MathUtil.ApproximatelyEqual(self:GetScrollPercentage(), 1);
end

function TRP3_ScrollBoxBaseMixin:SetScrollPercentage(scrollPercentage, noInterpolation)
	if not TRP3_MathUtil.ApproximatelyEqual(self:GetScrollPercentage(), scrollPercentage) then
		if not noInterpolation and self:CanInterpolateScroll() then
			self:Interpolate(scrollPercentage, self.scrollInternal);
		else
			self:SetScrollPercentageInternal(scrollPercentage);
		end
	end
end

function TRP3_ScrollBoxBaseMixin:SetScrollPercentageInternal(scrollPercentage)
	TRP3_ScrollControllerMixin.SetScrollPercentage(self, scrollPercentage);

	self:Update();
end

function TRP3_ScrollBoxBaseMixin:GetVisibleExtentPercentage()
	local extent = self:GetExtent();
	if extent > 0 then
		return self:GetVisibleExtent() / extent;
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetPanExtent()
	return self:GetView():GetPanExtent();
end

function TRP3_ScrollBoxBaseMixin:SetPanExtent(panExtent)
	self:GetView():SetPanExtent(panExtent);
end

function TRP3_ScrollBoxBaseMixin:GetExtent()
	return self:GetFrameExtent(self:GetScrollTarget());
end

function TRP3_ScrollBoxBaseMixin:GetVisibleExtent()
	return self:GetFrameExtent(self);
end

function TRP3_ScrollBoxBaseMixin:GetFrames()
	return self:GetView():GetFrames();
end

function TRP3_ScrollBoxBaseMixin:GetFrameCount()
	return self:GetView():GetFrameCount();
end

function TRP3_ScrollBoxBaseMixin:FindFrame(elementData)
	return self:GetView():FindFrame(elementData);
end

function TRP3_ScrollBoxBaseMixin:FindFrameByPredicate(predicate)
	return self:GetView():FindFrameByPredicate(predicate);
end

function TRP3_ScrollBoxBaseMixin:ScrollToFrame(frame, alignment, noInterpolation)
	local offset = self:SelectPointComponent(frame);
	local frameExtent = self:GetFrameExtent(frame);
	self:ScrollToOffset(offset, frameExtent, alignment, noInterpolation);
end

function TRP3_ScrollBoxBaseMixin:CalculatePanExtentPercentage()
	local scrollRange = self:GetDerivedScrollRange();
	if scrollRange > 0 then
		return self:GetPanExtent() / scrollRange;
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:CalculateScrollPercentage()
	local scrollRange = self:GetDerivedScrollRange();
	if scrollRange > 0 then
		return self:GetDerivedScrollOffset() / scrollRange;
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:HasScrollableExtent()
	return TRP3_MathUtil.WithinRangeExclusive(self:GetVisibleExtentPercentage(), 0, 1);
end

function TRP3_ScrollBoxBaseMixin:SetScrollAllowed(allowScroll)
	local oldAllowScroll = self:IsScrollAllowed();
	TRP3_ScrollControllerMixin.SetScrollAllowed(self, allowScroll);

	self:Update();

	if oldAllowScroll ~= allowScroll then
		self:TriggerEvent(TRP3_BaseScrollBoxEvents.OnAllowScrollChanged, allowScroll);
	end
end

function TRP3_ScrollBoxBaseMixin:GetDerivedScrollRange()
	return math.max(0, self:GetDerivedExtent() - self:GetVisibleExtent());
end

function TRP3_ScrollBoxBaseMixin:GetDerivedScrollOffset()
	return self:GetDerivedScrollRange() * self:GetScrollPercentage();
end

function TRP3_ScrollBoxBaseMixin:SetAlignmentOverlapIgnored(ignored)
	self.alignmentOverlapIgnored = ignored;
end

function TRP3_ScrollBoxBaseMixin:IsAlignmentOverlapIgnored()
	return self.alignmentOverlapIgnored;
end

function TRP3_ScrollBoxBaseMixin:SanitizeAlignment(alignment, extent)
	if not self:IsAlignmentOverlapIgnored() and extent > self:GetVisibleExtent() then
		return 0;
	end

	local centered = .5;
	return alignment and Saturate(alignment) or centered;
end

function TRP3_ScrollBoxBaseMixin:ScrollToOffset(offset, frameExtent, alignment, noInterpolation)
	alignment = self:SanitizeAlignment(alignment, frameExtent);
	local alignedOffset = offset + (frameExtent * alignment) - (self:GetVisibleExtent() * alignment);
	local scrollRange = self:GetDerivedScrollRange();
	if scrollRange > 0 then
		local scrollPercentage = alignedOffset / scrollRange;
		self:SetScrollPercentage(scrollPercentage, noInterpolation);
	end
end

function TRP3_ScrollBoxBaseMixin:GetVisibleExtentPercentage()
	local extent = self:GetDerivedExtent();
	if extent > 0 then
		return self:GetVisibleExtent() / extent;
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetDerivedExtent(recalculate)
	local view = self:GetView();
	if view then
		return view:GetExtent(recalculate, self);
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:SetPadding(padding)
	self:GetView():SetPadding(padding);
end

function TRP3_ScrollBoxBaseMixin:GetPadding()
	local view = self:GetView();
	if view then
		return view:GetPadding()
	end
	return nil;
end

function TRP3_ScrollBoxBaseMixin:GetLeftPadding()
	local padding = self:GetPadding();
	if padding then
		return padding:GetLeft();
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetTopPadding()
	local padding = self:GetPadding();
	if padding then
		return padding:GetTop();
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetRightPadding()
	local padding = self:GetPadding();
	if padding then
		return padding:GetRight();
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetBottomPadding()
	local padding = self:GetPadding();
	if padding then
		return padding:GetBottom();
	end
	return 0;
end

function TRP3_ScrollBoxBaseMixin:GetUpperPadding()
	if self:IsHorizontal() then
		return self:GetLeftPadding();
	else
		return self:GetTopPadding();
	end
end

function TRP3_ScrollBoxBaseMixin:GetLowerPadding()
	if self:IsHorizontal() then
		return self:GetRightPadding();
	else
		return self:GetBottomPadding();
	end
end

function TRP3_ScrollBoxBaseMixin:GetLowerShadowTexture(atlas)
	return self.Shadows.Lower;
end

function TRP3_ScrollBoxBaseMixin:GetUpperShadowTexture(atlas)
	return self.Shadows.Upper;
end

function TRP3_ScrollBoxBaseMixin:SetLowerShadowAtlas(atlas, useAtlasSize)
	self:GetLowerShadowTexture():SetAtlas(atlas, useAtlasSize);
end

function TRP3_ScrollBoxBaseMixin:SetUpperShadowAtlas(atlas, useAtlasSize)
	self:GetUpperShadowTexture():SetAtlas(atlas, useAtlasSize);
end

function TRP3_ScrollBoxBaseMixin:SetShadowsShown(showLower, showUpper)
	self:GetLowerShadowTexture():SetShown(showLower);
	self:GetUpperShadowTexture():SetShown(showUpper);
end

TRP3_ScrollBoxListMixin = CreateFromMixins(TRP3_ScrollBoxBaseMixin);

TRP3_ScrollBoxListMixin:GenerateCallbackEvents(
	{
		TRP3_BaseScrollBoxEvents.OnScroll,
		TRP3_BaseScrollBoxEvents.OnSizeChanged,
		TRP3_BaseScrollBoxEvents.OnAllowScrollChanged,
		TRP3_BaseScrollBoxEvents.OnLayout,
		"OnAcquiredFrame",
		"OnReleasedFrame",
		"OnDataRangeChanged",
	}
);

function TRP3_ScrollBoxListMixin:Init(view)
	self:Flush();

	TRP3_ScrollBoxBaseMixin.Init(self, view);
end

function TRP3_ScrollBoxListMixin:SetView(view)
	local oldView = self:GetView();
	if oldView then
		oldView:UnregisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnDataChanged, self);
		oldView:UnregisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnAcquiredFrame, self);
		oldView:UnregisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnReleasedFrame, self);
	end

	TRP3_ScrollBoxBaseMixin.SetView(self, view);

	view:RegisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnDataChanged, self.OnViewDataChanged, self);
	view:RegisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnAcquiredFrame, self.OnViewAcquiredFrame, self);
	view:RegisterCallback(TRP3_ScrollBoxListViewMixin.Event.OnReleasedFrame, self.OnViewReleasedFrame, self);
end

function TRP3_ScrollBoxListMixin:Flush()
	local view = self:GetView();
	if view then
		view:Flush();
	end
end

function TRP3_ScrollBoxListMixin:ForEachFrame(func)
	self:GetView():ForEachFrame(func);
end

function TRP3_ScrollBoxListMixin:EnumerateFrames()
	return self:GetView():EnumerateFrames();
end

function TRP3_ScrollBoxListMixin:FindElementDataByPredicate(predicate)
	return self:GetView():FindElementDataByPredicate(predicate);
end

function TRP3_ScrollBoxListMixin:FindElementDataIndexByPredicate(predicate)
	return self:GetView():FindElementDataIndexByPredicate(predicate);
end

function TRP3_ScrollBoxListMixin:FindByPredicate(predicate)
	return self:GetView():FindByPredicate(predicate);
end

function TRP3_ScrollBoxListMixin:Find(index)
	return self:GetView():Find(index);
end

function TRP3_ScrollBoxListMixin:FindIndex(elementData)
	return self:GetView():FindIndex(elementData);
end

function TRP3_ScrollBoxListMixin:InsertElementData(...)
	self:GetView():InsertElementData(...);
end

function TRP3_ScrollBoxListMixin:InsertElementDataTable(tbl)
	self:GetView():InsertElementDataTable(tbl);
end

function TRP3_ScrollBoxListMixin:InsertElementDataTableRange(tbl, indexBegin, indexEnd)
	self:GetView():InsertElementDataTableRange(tbl, indexBegin, indexEnd);
end

function TRP3_ScrollBoxListMixin:ContainsElementDataByPredicate(predicate)
	return self:GetView():ContainsElementDataByPredicate(predicate);
end

function TRP3_ScrollBoxListMixin:GetDataProvider()
	return self:GetView():GetDataProvider();
end

function TRP3_ScrollBoxListMixin:HasDataProvider()
	return self:GetView():HasDataProvider();
end

function TRP3_ScrollBoxListMixin:ClearDataProvider()
	self:GetView():ClearDataProvider();
end

function TRP3_ScrollBoxListMixin:GetDataIndexBegin()
	return self:GetView():GetDataIndexBegin();
end

function TRP3_ScrollBoxListMixin:GetDataIndexEnd()
	return self:GetView():GetDataIndexEnd();
end

function TRP3_ScrollBoxListMixin:IsVirtualized()
	return self:GetView():IsVirtualized();
end

function TRP3_ScrollBoxListMixin:GetElementExtent(dataIndex)
	return self:GetView():GetElementExtent(self, dataIndex);
end

function TRP3_ScrollBoxListMixin:GetExtentUntil(dataIndex)
	return self:GetView():GetExtentUntil(self, dataIndex);
end

function TRP3_ScrollBoxListMixin:SetDataProvider(dataProvider, retainScrollPosition)
	local view = self:GetView();
	if not view then
		error("A view is required before assigning the data provider.");
	end

	view:SetDataProvider(dataProvider);

	if not retainScrollPosition then
		self:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
	end
end

function TRP3_ScrollBoxListMixin:GetDataProviderSize()
	local view = self:GetView();
	if view then
		return view:GetDataProviderSize();
	end
	return 0;
end

function TRP3_ScrollBoxListMixin:OnViewDataChanged()
	self:UpdateImmediately();
end

function TRP3_ScrollBoxListMixin:Rebuild()
	self:GetView():Rebuild();
end

function TRP3_ScrollBoxListMixin:OnViewAcquiredFrame(frame, elementData, new)
	self:TriggerEvent(TRP3_ScrollBoxListMixin.Event.OnAcquiredFrame, frame, elementData, new);
end

function TRP3_ScrollBoxListMixin:OnViewReleasedFrame(frame, oldElementData)
	self:TriggerEvent(TRP3_ScrollBoxListMixin.Event.OnReleasedFrame, frame, oldElementData);
end

function TRP3_ScrollBoxListMixin:IsAcquireLocked()
	local view = self:GetView();
	return view and view:IsAcquireLocked();
end

function TRP3_ScrollBoxListMixin:FullUpdate()
	if not self:IsAcquireLocked() then
		TRP3_ScrollBoxBaseMixin.FullUpdate(self);
	end
end

function TRP3_ScrollBoxListMixin:Update(forceLayout)
	if self:IsUpdateLocked() or self:IsAcquireLocked() then
		return;
	end
	self:SetUpdateLocked(true);

	local view = self:GetView();
	if view then
		local changed = view:ValidateDataRange(self);
		if changed or forceLayout then
			self:Layout();
		end

		self:SetScrollTargetOffset(self:GetDerivedScrollOffset() - view:GetDataScrollOffset(self));
		self:SetPanExtentPercentage(self:CalculatePanExtentPercentage());

		if changed then
			self:TriggerEvent(TRP3_ScrollBoxListMixin.Event.OnDataRangeChanged);
		end
	end

	self:SetUpdateLocked(false);
end

function TRP3_ScrollBoxListMixin:ScrollToNearest(dataIndex, noInterpolation)
	local scrollOffset = self:GetDerivedScrollOffset();
	if self:GetExtentUntil(dataIndex) > (scrollOffset + self:GetVisibleExtent()) then
		return self:ScrollToElementDataIndex(dataIndex, TRP3_ScrollBoxConstants.AlignEnd, noInterpolation);
	elseif self:GetExtentUntil(dataIndex) < scrollOffset then
		return self:ScrollToElementDataIndex(dataIndex, TRP3_ScrollBoxConstants.AlignBegin, noInterpolation);
	end
	return nil;
end

function TRP3_ScrollBoxListMixin:ScrollToElementDataIndex(dataIndex, alignment, noInterpolation)
	if alignment == TRP3_ScrollBoxConstants.AlignNearest then
		return self:ScrollToNearest(dataIndex, noInterpolation);
	else
		local elementData = self:Find(dataIndex);
		if elementData then
			local extent = self:GetExtentUntil(dataIndex);
			local elementExtent = self:GetElementExtent(dataIndex);
			self:ScrollToOffset(extent, elementExtent, alignment, noInterpolation);
			return elementData;
		end
	end
	return nil;
end

function TRP3_ScrollBoxListMixin:ScrollToElementData(elementData, alignment, noInterpolation)
	local dataIndex = self:FindIndex(elementData);
	if dataIndex then
		return self:ScrollToElementDataIndex(dataIndex, alignment, noInterpolation);
	end
	return nil;
end

function TRP3_ScrollBoxListMixin:ScrollToElementDataByPredicate(predicate, alignment, noInterpolation)
	if alignment == TRP3_ScrollBoxConstants.AlignNearest then
		local dataIndex, elementData = self:FindByPredicate(predicate);
		if dataIndex then
			return self:ScrollToNearest(dataIndex, noInterpolation);
		end
	else
		local dataIndex = self:FindElementDataIndexByPredicate(predicate);
		if dataIndex then
			return self:ScrollToElementDataIndex(dataIndex, alignment, noInterpolation);
		end
	end

	return nil;
end

TRP3_ScrollBoxMixin = CreateFromMixins(TRP3_ScrollBoxBaseMixin);

TRP3_ScrollBoxMixin:GenerateCallbackEvents(
	{
		TRP3_BaseScrollBoxEvents.OnScroll,
		TRP3_BaseScrollBoxEvents.OnSizeChanged,
		TRP3_BaseScrollBoxEvents.OnAllowScrollChanged,
		TRP3_BaseScrollBoxEvents.OnLayout,
	}
);

function TRP3_ScrollBoxMixin:OnLoad()
	TRP3_ScrollBoxBaseMixin.OnLoad(self);

	if not self.panExtent then
		-- Intended to function, but be apparent it's untuned.
		self.panExtent = 3;
	end
end

function TRP3_ScrollBoxMixin:SetView(view)
	TRP3_ScrollBoxBaseMixin.SetView(self, view);

	view:ReparentScrollChildren(self:GetChildren());
end

function TRP3_ScrollBoxMixin:Update(forceLayout)
	if self:IsUpdateLocked() then
		return;
	end
	self:SetUpdateLocked(true);

	if forceLayout then
		self:Layout();
	end

	self:SetScrollTargetOffset(self:GetDerivedScrollOffset());

	self:SetUpdateLocked(false);
end
