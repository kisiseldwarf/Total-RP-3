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

TRP3_ScrollDirectionMixin = {};

function TRP3_ScrollDirectionMixin:SetHorizontal(isHorizontal)
	self.isHorizontal = isHorizontal;
end

function TRP3_ScrollDirectionMixin:IsHorizontal()
	return self.isHorizontal;
end

function TRP3_ScrollDirectionMixin:GetFrameExtent(frame)
	local width, height = frame:GetSize();
	return self.isHorizontal and width or height;
end

function TRP3_ScrollDirectionMixin:SetFrameExtent(frame, value)
	if self.isHorizontal then
		frame:SetWidth(value);
	else
		frame:SetHeight(value);
	end
end

function TRP3_ScrollDirectionMixin:GetUpper(frame)
	return self.isHorizontal and frame:GetLeft() or frame:GetTop();
end

function TRP3_ScrollDirectionMixin:GetLower(frame)
	return self.isHorizontal and frame:GetRight() or frame:GetBottom();
end

function TRP3_ScrollDirectionMixin:SelectCursorComponent()
	local x, y = GetScaledCursorPosition();
	return self.isHorizontal and x or y;
end

function TRP3_ScrollDirectionMixin:SelectPointComponent(frame)
	local index = self.isHorizontal and 4 or 5;
	return select(index, frame:GetPoint("TOPLEFT"));
end

TRP3_ScrollControllerMixin = CreateFromMixins(TRP3_ScrollDirectionMixin);

TRP3_ScrollControllerMixin.Directions =
{
	Increase = 1,
	Decrease = -1,
}

function TRP3_ScrollControllerMixin:OnLoad()
	self.panExtentPercentage = .1;
	self.allowScroll = true;

	if not self.wheelPanScalar then
		self.wheelPanScalar = 2.0;
	end
end

function TRP3_ScrollControllerMixin:OnMouseWheel(value)
	if value < 0 then
		self:ScrollInDirection(self:GetWheelPanPercentage(), TRP3_ScrollControllerMixin.Directions.Increase);
	else
		self:ScrollInDirection(self:GetWheelPanPercentage(), TRP3_ScrollControllerMixin.Directions.Decrease);
	end
end

function TRP3_ScrollControllerMixin:ScrollInDirection(scrollPercentage, direction)
	if self:IsScrollAllowed() then
		local delta = scrollPercentage * direction;
		self:SetScrollPercentage(Saturate(self:GetScrollPercentage() + delta));
	end
end

function TRP3_ScrollControllerMixin:GetPanExtentPercentage()
	return self.panExtentPercentage;
end

function TRP3_ScrollControllerMixin:SetPanExtentPercentage(panExtentPercentage)
	self.panExtentPercentage = Saturate(panExtentPercentage);
end

function TRP3_ScrollControllerMixin:GetWheelPanPercentage()
	return Saturate(self:GetPanExtentPercentage() * self.wheelPanScalar);
end

function TRP3_ScrollControllerMixin:GetScrollPercentage()
	return self.scrollPercentage or 0;
end

function TRP3_ScrollControllerMixin:SetScrollPercentage(scrollPercentage)
	self.scrollPercentage = Saturate(scrollPercentage);
end

function TRP3_ScrollControllerMixin:CanInterpolateScroll()
	return self.canInterpolateScroll or false;
end

function TRP3_ScrollControllerMixin:SetInterpolateScroll(canInterpolateScroll)
	self.canInterpolateScroll = canInterpolateScroll;
end

function TRP3_ScrollControllerMixin:GetScrollInterpolator()
	if not self.interpolator then
		self.interpolator = CreateFromMixins(TRP3_InterpolatorMixin);
	end
	return self.interpolator;
end

function TRP3_ScrollControllerMixin:Interpolate(scrollPercentage, setter)
	local time = .11;
	local interpolator = self:GetScrollInterpolator();
	interpolator:Interpolate(self:GetScrollPercentage(), scrollPercentage, time, setter);
end

function TRP3_ScrollControllerMixin:IsScrollAllowed()
	return self.allowScroll;
end

function TRP3_ScrollControllerMixin:SetScrollAllowed(allowScroll)
	self.allowScroll = allowScroll;
end
