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

TRP3_ScrollBoxGridPaddingMixin = CreateFromMixins(TRP3_ScrollBoxPaddingMixin);

function TRP3_ScrollBoxGridPaddingMixin:Init(top, bottom, left, right, horizontalSpacing, verticalSpacing)
	TRP3_ScrollBoxPaddingMixin.Init(self, top, bottom, left, right);
	self:SetHorizontalSpacing(horizontalSpacing or 0);
	self:SetVerticalSpacing(verticalSpacing or 0);
end

function TRP3_ScrollBoxGridPaddingMixin:GetHorizontalSpacing()
	return self.horizontalSpacing;
end

function TRP3_ScrollBoxGridPaddingMixin:SetHorizontalSpacing(spacing)
	self.horizontalSpacing = spacing;
end

function TRP3_ScrollBoxGridPaddingMixin:GetVerticalSpacing()
	return self.verticalSpacing;
end

function TRP3_ScrollBoxGridPaddingMixin:SetVerticalSpacing(spacing)
	self.verticalSpacing = spacing;
end

TRP3_ScrollBoxListGridViewMixin = CreateFromMixins(TRP3_ScrollBoxListViewMixin);

function TRP3_ScrollBoxListGridViewMixin:Init(stride, top, bottom, left, right, horizontalSpacing, verticalSpacing)
	TRP3_ScrollBoxListViewMixin.Init(self);
	self:SetStride(stride);
	self:SetPadding(top, bottom, left, right, horizontalSpacing, verticalSpacing);
end

function TRP3_ScrollBoxListGridViewMixin:SetPadding(top, bottom, left, right, horizontalSpacing, verticalSpacing)
	local padding = TRP3_ScrollUtil.CreateScrollBoxGridPadding(top, bottom, left, right, horizontalSpacing, verticalSpacing);
	TRP3_ScrollBoxViewMixin.SetPadding(self, padding);
end

function TRP3_ScrollBoxListGridViewMixin:GetHorizontalSpacing()
	return self.padding:GetHorizontalSpacing();
end

function TRP3_ScrollBoxListGridViewMixin:GetVerticalSpacing()
	return self.padding:GetVerticalSpacing();
end

function TRP3_ScrollBoxListGridViewMixin:SetStride(stride)
	self.stride = stride;
end

function TRP3_ScrollBoxListGridViewMixin:SetHorizontal(isHorizontal)
	-- Horizontal layout not current supported at this time.
	isHorizontal = false;
	TRP3_ScrollDirectionMixin.SetHorizontal(self, isHorizontal);
end

function TRP3_ScrollBoxListGridViewMixin:GetStride()
	local strideExtent = self:GetStrideExtent();
	if strideExtent then
		local scrollTarget = self:GetScrollTarget();
		local extent = scrollTarget:GetWidth();
		local spacing = self:GetHorizontalSpacing();
		local stride = math.max(1, math.floor(extent / strideExtent));
		local extentWithSpacing = (stride * strideExtent) + ((stride-1) * spacing);
		while stride > 1 and extentWithSpacing > extent do
			stride = stride - 1;
			extentWithSpacing = extentWithSpacing - (strideExtent + spacing);
		end
		return stride;
	end

	return self.stride;
end

function TRP3_ScrollBoxListGridViewMixin:SetStrideExtent(extent)
	self.strideExtent = extent;
end

function TRP3_ScrollBoxListGridViewMixin:GetStrideExtent()
	return self.strideExtent;
end

function TRP3_ScrollBoxListGridViewMixin:Layout()
	local frames = self:GetFrames();
	local frameCount = #frames;
	if frameCount == 0 then
		return 0;
	end

	local stride = self:GetStride();
	local horizontalSpacing = self:GetHorizontalSpacing();
	local verticalSpacing = self:GetVerticalSpacing();
	local layout = TRP3_AnchorUtil.CreateGridLayout(TRP3_GridLayoutMixin.Direction.TopLeftToBottomRight, stride, horizontalSpacing, verticalSpacing);
	local anchor = TRP3_AnchorUtil.CreateAnchor("TOPLEFT", self:GetScrollTarget(), "TOPLEFT", 0, 0);
	TRP3_AnchorUtil.GridLayout(frames, anchor, layout);

	local extent = self:GetFrameExtent(frames[1]) * math.ceil(frameCount / stride);
	local space = TRP3_ScrollBoxViewUtil.CalculateSpacingUntil(frameCount, stride, verticalSpacing);
	return extent + space;
end

function TRP3_ScrollBoxListGridViewMixin:CalculateDataIndices(scrollBox)
	return TRP3_ScrollBoxListViewMixin.CalculateDataIndices(self, scrollBox, self:GetStride(), self:GetVerticalSpacing());
end

function TRP3_ScrollBoxListGridViewMixin:GetExtent(recalculate, scrollBox)
	return TRP3_ScrollBoxListViewMixin.GetExtent(self, recalculate, scrollBox, self:GetStride(), self:GetVerticalSpacing());
end

function TRP3_ScrollBoxListGridViewMixin:GetExtentUntil(scrollBox, dataIndex)
	return TRP3_ScrollBoxListViewMixin.GetExtentUntil(self, scrollBox, dataIndex, self:GetStride(), self:GetVerticalSpacing());
end

function TRP3_ScrollBoxListGridViewMixin:GetPanExtent()
	return TRP3_ScrollBoxListViewMixin.GetPanExtent(self, self:GetVerticalSpacing());
end
