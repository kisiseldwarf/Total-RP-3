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

TRP3_AnchorMixin = {};

function TRP3_AnchorMixin:Init(point, relativeTo, relativePoint, x, y)
	self:Set(point, relativeTo, relativePoint, x, y);
end

function TRP3_AnchorMixin:Set(point, relativeTo, relativePoint, x, y)
	self.point = point;
	self.relativeTo = relativeTo;
	self.relativePoint = relativePoint;
	self.x = x;
	self.y = y;
end

function TRP3_AnchorMixin:SetFromPoint(region, pointIndex)
	self:Set(region:GetPoint(pointIndex));
end

function TRP3_AnchorMixin:Get()
	local point = self.point or "TOPLEFT";
	local relativePoint = self.relativePoint or self.point or "TOPLEFT";
	local x = self.x or 0;
	local y = self.y or 0;
	return point, self.relativeTo, relativePoint, x, y;
end

function TRP3_AnchorMixin:SetPoint(region, clearAllPoints)
	if clearAllPoints then
		region:ClearAllPoints();
	end
	region:SetPoint(self:Get());
end

function TRP3_AnchorMixin:SetPointWithExtraOffset(region, clearAllPoints, extraOffsetX, extraOffsetY)
	if clearAllPoints then
		region:ClearAllPoints();
	end
	local point, relativeTo, relativePoint, x, y = self:Get();
	region:SetPoint(point, relativeTo, relativePoint, x + extraOffsetX, y + extraOffsetY);
end

TRP3_GridLayoutMixin = {};

TRP3_GridLayoutMixin.Direction =
{
	TopLeftToBottomRight = { x = 1, y = -1 },
	TopRightToBottomLeft = { x = -1, y = -1 },
	TopLeftToBottomRightVertical = { x = 1, y = -1, isVertical = true },
	TopRightToBottomLeftVertical = { x = -1, y = -1, isVertical = true },
};

function TRP3_GridLayoutMixin:Init(direction, stride, paddingX, paddingY, horizontalSpacing, verticalSpacing)
	self.direction = direction or TRP3_GridLayoutMixin.Direction.TopLeftToBottomRight;
	self.stride = stride or 1;
	self.paddingX = paddingX or 0;
	self.paddingY = paddingY or 0;
	self.horizontalSpacing = horizontalSpacing;
	self.verticalSpacing = verticalSpacing;
end

function TRP3_GridLayoutMixin:SetCustomOffsetFunction(func)
	self.customOffsetFunction = func;
end

function TRP3_GridLayoutMixin:GetCustomOffset(row, col)
	if self.customOffsetFunction then
		return self.customOffsetFunction(row, col);
	end

	return 0, 0;
end

TRP3_AnchorUtil = {};

function TRP3_AnchorUtil.CreateAnchor(point, relativeTo, relativePoint, x, y)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_AnchorMixin, point, relativeTo, relativePoint, x, y);
end

function TRP3_AnchorUtil.CreateGridLayout(direction, stride, paddingX, paddingY, horizontalSpacing, verticalSpacing)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_GridLayoutMixin, direction, stride, paddingX, paddingY, horizontalSpacing, verticalSpacing);
end

function TRP3_AnchorUtil.CreateAnchorFromPoint(region, pointIndex)
	local anchor = TRP3_AnchorUtil.CreateAnchor();
	anchor:SetFromPoint(region, pointIndex);
	return anchor;
end

-- For initialAnchor and layout, use TRP3_AnchorUtil.CreateAnchor(...) and TRP3_AnchorUtil.CreateGridLayout(...)
function TRP3_AnchorUtil.GridLayout(frames, initialAnchor, layout)
	if #frames <= 0 then
		return;
	end

	local width = layout.horizontalSpacing or frames[1]:GetWidth();
	local height = layout.verticalSpacing or frames[1]:GetHeight();
	local stride = layout.stride;
	local paddingX = layout.paddingX;
	local paddingY = layout.paddingY;
	local direction = layout.direction;
	for i, frame in ipairs(frames) do
		local row = math.floor((i - 1) / stride) + 1;
		local col = (i - 1) % stride + 1;
		if direction.isVertical then
			local tempRow = row;
			row = col;
			col = tempRow;
		end
		local clearAllPoints = true;
		local customOffsetX, customOffsetY = layout:GetCustomOffset(row, col);
		local extraOffsetX = (col - 1) * (width + paddingX) * direction.x + customOffsetX;
		local extraOffsetY = (row - 1) * (height + paddingY) * direction.y + customOffsetY;
		initialAnchor:SetPointWithExtraOffset(frame, clearAllPoints, extraOffsetX, extraOffsetY);
	end
end

local function GetFrameSpacing(totalSize, numElements, elementSize)
	if numElements <= 1 then
		return 0;
	end

	return (totalSize - (numElements * elementSize)) / (numElements - 1);
end

local function SanitizeTotalSize(size)
	if not size or size == 0 then
		return math.huge;
	else
		return Round(size);
	end
end

-- For initialAnchor and layout, use TRP3_AnchorUtil.CreateAnchor(...) and TRP3_AnchorUtil.CreateGridLayout(...)
function TRP3_AnchorUtil.GridLayoutFactoryByCount(factoryFunction, count, initialAnchor, layout)
	if count <= 0 then
		return;
	end

	local frames = { };
	while #frames < count do
		local frame = factoryFunction(#frames + 1);
		if not frame then
			break;
		end

		table.insert(frames, frame);
	end

	TRP3_AnchorUtil.GridLayout(frames, initialAnchor, layout);
end

-- For initialAnchor, use TRP3_AnchorUtil.CreateAnchor(...)
function TRP3_AnchorUtil.GridLayoutFactory(factoryFunction, initialAnchor, totalWidth, totalHeight, overrideDirection, overridePaddingX, overridePaddingY)
	local frame = factoryFunction(1);
	if not frame then
		return;
	end

	totalWidth = SanitizeTotalSize(totalWidth);
	totalHeight = SanitizeTotalSize(totalHeight);

	-- If we have an override padding, count it in the frame width. We add a padding to totalWidth/totalHeight to account for the
	-- extra space we save for the last element which doesn't need padding.
	local width = Round(frame:GetWidth()) + (overridePaddingX or 0);
	local height = Round(frame:GetHeight()) + (overridePaddingY or 0);
	local rowSize = math.floor((totalWidth + (overridePaddingX or 0)) / width);
	local colSize = math.floor((totalHeight + (overridePaddingY or 0)) / height);

	local spacingX = overridePaddingX or GetFrameSpacing(totalWidth, rowSize, width);
	local spacingY = overridePaddingY or GetFrameSpacing(totalHeight, colSize, height);

	local frames = { frame };
	while #frames < rowSize * colSize do
		local frame = factoryFunction(#frames + 1);  -- luacheck: no redefined (Blizzard)
		if not frame then
			break;
		end

		table.insert(frames, frame);
	end

	local direction = overrideDirection or TRP3_GridLayoutMixin.Direction.TopLeftToBottomRight;

	TRP3_AnchorUtil.GridLayout(frames, initialAnchor, TRP3_AnchorUtil.CreateGridLayout(direction, rowSize, spacingX, spacingY));
end

-- Mirrors an array of regions along the specified axis. For example, if horizontal, a region
-- anchored LEFT TOPLEFT 20 20 will become anchored RIGHT TOPRIGHT -20 20.
-- Mirror description format: {region = region, mirrorUV = [true, false]}
local function MirrorRegionsAlongAxis(mirrorDescriptions, exchangeables, setPointWrapper, setTexCoordsWrapper)
	for _, description in ipairs(mirrorDescriptions) do
		local exchanged = {};

		local region = description.region;
		local mirrorUV = description.mirrorUV;
		for p in pairs(exchangeables) do
			if not exchanged[p] then
				local point1, relative1, relativePoint1, x1, y1 = region:GetPointByName(p);
				if point1 then
					-- Retrieve point information for what we're replacing, if any.
					local mirrorPoint1 = exchangeables[point1];
					local point2, relative2, relativePoint2, x2, y2 = region:GetPointByName(mirrorPoint1);
					setPointWrapper(region, point1, relative1, relativePoint1, x1, y1);

					-- If we replaced a point, mirror the information to the original point.
					if point2 then
						setPointWrapper(region, point2, relative2, relativePoint2, x2, y2);
					else
						-- Otherwise, clear the original point.
						region:ClearPointByName(point1);
					end

					exchanged[point1] = true;
					exchanged[mirrorPoint1] = true;
				end
			end
		end

		if mirrorUV then
			setTexCoordsWrapper(region);
		end
	end
end

local SetPointAlongAxis = function(points, region, point, relative, relativePoint, x, y)
	local mirrorPoint = points[point];
	local mirrorRelativePoint = points[relativePoint] or relativePoint;
	region:SetPoint(mirrorPoint, relative, mirrorRelativePoint, x, y);
end

local VERTICAL_MIRROR_POINTS =
{
	["TOPLEFT"] = "BOTTOMLEFT",
	["TOP"] = "BOTTOM",
	["TOPRIGHT"] = "BOTTOMRIGHT",
	["BOTTOMLEFT"] = "TOPLEFT",
	["BOTTOM"] = "TOP",
	["BOTTOMRIGHT"] = "TOPRIGHT",
	["CENTER"] = "CENTER", -- Mirrored only along x and y offsets.
	["LEFT"] = "LEFT", -- Mirrored only  along x and y offsets.
	["RIGHT"] = "RIGHT", -- Mirrored only along x and y offsets.
};

local SetPointVertical = function(region, point, relative, relativePoint, x, y)
	SetPointAlongAxis(VERTICAL_MIRROR_POINTS, region, point, relative, relativePoint, x, -y);
end;

local SetTexCoordVertical = function(region)
	local x1, y1, x2, y2, x3, y3, x4, y4 = region:GetTexCoord();
	region:SetTexCoord(x2, y2, x1, y1, x4, y4, x3, y3);
end

function TRP3_AnchorUtil.MirrorRegionsAlongVerticalAxis(mirrorDescriptions)
	MirrorRegionsAlongAxis(mirrorDescriptions, VERTICAL_MIRROR_POINTS, SetPointVertical, SetTexCoordVertical);
end

local HORIZONTAL_MIRROR_POINTS =
{
	["TOPLEFT"] = "TOPRIGHT",
	["LEFT"] = "RIGHT",
	["BOTTOMLEFT"] = "BOTTOMRIGHT",
	["TOPRIGHT"] = "TOPLEFT",
	["RIGHT"] = "LEFT",
	["BOTTOMRIGHT"] = "BOTTOMLEFT",
	["CENTER"] = "CENTER", -- Mirrored only along x and y offsets.
	["TOP"] = "TOP", -- Mirrored only along x and y offsets.
	["BOTTOM"] = "BOTTOM", -- Mirrored only along x and y offsets.
};

local SetPointHorizontal = function(region, point, relative, relativePoint, x, y)
	SetPointAlongAxis(HORIZONTAL_MIRROR_POINTS, region, point, relative, relativePoint, -x, y);
end

local SetTexCoordHorizontal = function(region)
	local x1, y1, x2, y2, x3, y3, x4, y4 = region:GetTexCoord();
	region:SetTexCoord(x3, y3, x4, y4, x1, y1, x2, y2);
end

function TRP3_AnchorUtil.MirrorRegionsAlongHorizontalAxis(mirrorDescriptions)
	MirrorRegionsAlongAxis(mirrorDescriptions, HORIZONTAL_MIRROR_POINTS, SetPointHorizontal, SetTexCoordHorizontal);
end
