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

-- Points are cleared first to avoid some complications related to drag and drop.
local function SetHorizontalPoint(frame, offset, scrollTarget)
	local width = frame:GetWidth();
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", scrollTarget, "TOPLEFT", offset, 0);
	frame:SetPoint("BOTTOMLEFT", scrollTarget, "BOTTOMLEFT", offset, 0);
	return width;
end

local function SetVerticalPoint(frame, offset, scrollTarget)
	local height = frame:GetHeight();
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", scrollTarget, "TOPLEFT", 0, -offset);
	frame:SetPoint("TOPRIGHT", scrollTarget, "TOPRIGHT", 0, -offset);
	return height;
end

TRP3_ScrollBoxLinearPaddingMixin = CreateFromMixins(TRP3_ScrollBoxPaddingMixin);

function TRP3_ScrollBoxLinearPaddingMixin:Init(top, bottom, left, right, spacing)
	TRP3_ScrollBoxPaddingMixin.Init(self, top, bottom, left, right);
	self:SetSpacing(spacing or 0);
end

function TRP3_ScrollBoxLinearPaddingMixin:GetSpacing()
	return self.spacing;
end

function TRP3_ScrollBoxLinearPaddingMixin:SetSpacing(spacing)
	self.spacing = spacing;
end

TRP3_ScrollBoxLinearBaseViewMixin = CreateFromMixins(TRP3_ScrollBoxViewMixin);

function TRP3_ScrollBoxLinearBaseViewMixin:SetPadding(top, bottom, left, right, spacing)
	local padding = TRP3_ScrollUtil.CreateScrollBoxLinearPadding(top, bottom, left, right, spacing);
	TRP3_ScrollBoxViewMixin.SetPadding(self, padding);
end

function TRP3_ScrollBoxLinearBaseViewMixin:GetSpacing()
	return self.padding:GetSpacing();
end

function TRP3_ScrollBoxLinearBaseViewMixin:GetStride()
	return 1;
end

function TRP3_ScrollBoxLinearBaseViewMixin:Layout()
	local frames = self:GetFrames();
	local frameCount = frames and #frames or 0;
	if frameCount == 0 then
		return 0;
	end

	local spacing = self:GetSpacing();
	local scrollTarget = self:GetScrollTarget();
	local setPoint = self:IsHorizontal() and SetHorizontalPoint or SetVerticalPoint;
	local frameLevelCounter = TRP3_ScrollBoxViewUtil.CreateFrameLevelCounter(self:GetFrameLevelPolicy(), scrollTarget:GetFrameLevel(), frameCount);

	local total = 0;
	local offset = 0;
	for index, frame in ipairs(frames) do
		local extent = setPoint(frame, offset, scrollTarget);
		offset = offset + extent + spacing;
		total = total + extent;

		if frameLevelCounter then
			frame:SetFrameLevel(frameLevelCounter());
		end
	end

	local spacingTotal = math.max(0, frameCount - 1) * spacing;
	local extentTotal = total + spacingTotal;
	return extentTotal;
end

TRP3_ScrollBoxListLinearViewMixin = CreateFromMixins(TRP3_ScrollBoxListViewMixin, TRP3_ScrollBoxLinearBaseViewMixin);

function TRP3_ScrollBoxListLinearViewMixin:Init(top, bottom, left, right, spacing)
	TRP3_ScrollBoxListViewMixin.Init(self);
	self:SetPadding(top, bottom, left, right, spacing);
end

function TRP3_ScrollBoxListLinearViewMixin:CalculateDataIndices(scrollBox)
	return TRP3_ScrollBoxListViewMixin.CalculateDataIndices(self, scrollBox, self:GetStride(), self:GetSpacing());
end

function TRP3_ScrollBoxListLinearViewMixin:GetExtent(recalculate, scrollBox)
	return TRP3_ScrollBoxListViewMixin.GetExtent(self, recalculate, scrollBox, self:GetStride(), self:GetSpacing());
end

function TRP3_ScrollBoxListLinearViewMixin:GetExtentUntil(scrollBox, dataIndex)
	return TRP3_ScrollBoxListViewMixin.GetExtentUntil(self, scrollBox, dataIndex, self:GetStride(), self:GetSpacing());
end

function TRP3_ScrollBoxListLinearViewMixin:GetPanExtent()
	return TRP3_ScrollBoxListViewMixin.GetPanExtent(self, self:GetSpacing());
end

TRP3_ScrollBoxLinearViewMixin = CreateFromMixins(TRP3_ScrollBoxLinearBaseViewMixin);

function TRP3_ScrollBoxLinearViewMixin:Init(top, bottom, left, right, spacing)
	TRP3_ScrollBoxViewMixin.Init(self);
	self:SetPadding(top, bottom, left, right, spacing);
end

function TRP3_ScrollBoxLinearViewMixin:ReparentScrollChildren(...)
	local scrollTarget = self:GetScrollTarget();
	for index = 1, select("#", ...) do
		local child = select(index, ...);
		if child.scrollable then
			child:SetParent(scrollTarget);
			table.insert(self.frames, child);
		end
	end
end

function TRP3_ScrollBoxLinearViewMixin:GetPanExtent()
	if not self.panExtent then
		local firstFrame = self:GetFrames()[1];
		if firstFrame then
			self.panExtent = self:GetFrameExtent(firstFrame) + self:GetSpacing();
		end
	end

	return self.panExtent or 0;
end

function TRP3_ScrollBoxLinearViewMixin:GetExtent(recalculate, scrollBox)
	if recalculate or not self.extent then
		local extent = 0;

		local frames = self:GetFrames();
		for index, frame in ipairs(frames) do
			extent = extent + self:GetFrameExtent(frame);
		end

		local space = TRP3_ScrollBoxViewUtil.CalculateSpacingUntil(#frames, self:GetStride(), self:GetSpacing());
		self.extent = extent + space + scrollBox:GetUpperPadding() + scrollBox:GetLowerPadding();
	end

	return self.extent;
end
