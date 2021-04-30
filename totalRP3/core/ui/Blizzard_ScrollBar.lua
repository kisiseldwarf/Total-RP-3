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

TRP3_ScrollBarMixin = CreateFromMixins(TRP3_CallbackRegistryMixin, TRP3_ScrollControllerMixin, TRP3_EventFrameMixin);
TRP3_ScrollBarMixin:GenerateCallbackEvents(
	{
		"OnScroll",
		"OnAllowScrollChanged",
	}
);

function TRP3_ScrollBarMixin:OnLoad()
	TRP3_ScrollControllerMixin.OnLoad(self);

	self.visibleExtentPercentage = 0;

	-- Levels are assigned here because it's the closest we can get to a relative
	-- frame level. The order of these components is an internal detail to this
	-- object, and we want to avoid defining an absolute frame level in the XML
	-- resulting in confusion as frames unintentionally appear out of the expected order.
	local level = self:GetFrameLevel();
	self:GetTrack():SetFrameLevel(level + 2);
	self:GetTrack():SetScript("OnMouseDown", TRP3_FunctionUtil.GenerateClosure(self.OnTrackMouseDown, self));

	local buttonLevel = level + 3;
	self:GetBackStepper():SetFrameLevel(buttonLevel);
	self:GetBackStepper():RegisterCallback("OnMouseDown", TRP3_FunctionUtil.GenerateClosure(self.OnStepperMouseDown, self, self:GetBackStepper()), self);

	self:GetForwardStepper():SetFrameLevel(buttonLevel);
	self:GetForwardStepper():RegisterCallback("OnMouseDown", TRP3_FunctionUtil.GenerateClosure(self.OnStepperMouseDown, self, self:GetForwardStepper()), self);

	self:GetThumb():SetFrameLevel(buttonLevel);
	self:GetThumb():RegisterCallback("OnMouseDown", TRP3_FunctionUtil.GenerateClosure(self.OnThumbMouseDown, self), self);

	self.scrollInternal = TRP3_FunctionUtil.GenerateClosure(self.SetScrollPercentageInternal, self);

	self:DisableControls();
end

function TRP3_ScrollBarMixin:Init(visibleExtentPercentage, panExtentPercentage)
	TRP3_ScrollControllerMixin.SetScrollPercentage(self, 0);
	self:SetPanExtentPercentage(panExtentPercentage);
	self:SetVisibleExtentPercentage(visibleExtentPercentage);
end

function TRP3_ScrollBarMixin:GetBackStepper()
	return self.Back;
end

function TRP3_ScrollBarMixin:GetForwardStepper()
	return self.Forward;
end

function TRP3_ScrollBarMixin:GetTrack()
	return self.Track;
end

function TRP3_ScrollBarMixin:GetThumb()
	return self:GetTrack().Thumb;
end

function TRP3_ScrollBarMixin:GetThumbAnchor()
	return self.thumbAnchor;
end

function TRP3_ScrollBarMixin:GetPanRepeatTime()
	return self.panRepeatTime;
end

function TRP3_ScrollBarMixin:GetPanRepeatDelay()
	return self.panDelay;
end

function TRP3_ScrollBarMixin:OnStepperMouseDown(stepper)
	local direction = stepper.direction;
	self:ScrollStepInDirection(direction);

	local elapsed = 0;
	local repeatTime = self:GetPanRepeatTime();
	local delay = self:GetPanRepeatDelay();
	self:SetScript("OnUpdate", function(tbl, dt)
		if not stepper.leave then
			elapsed = elapsed + dt;
			if elapsed > delay then
				elapsed = 0;
				delay = repeatTime;
				self:ScrollStepInDirection(direction);
			end
		end
	end);

	stepper:RegisterCallback("OnEnter", function()
		stepper.leave = nil;
	end, self);

	stepper:RegisterCallback("OnLeave", function()
		stepper.leave = true;
	end, self);

	stepper:RegisterCallback("OnMouseUp", TRP3_FunctionUtil.GenerateClosure(self.UnregisterUpdate, self), self);
end

function TRP3_ScrollBarMixin:GetTrackExtent()
	return self:GetFrameExtent(self:GetTrack());
end;

function TRP3_ScrollBarMixin:ScrollInDirection(percentage, direction)
	TRP3_ScrollControllerMixin.ScrollInDirection(self, percentage, direction);

	self:Update();

	self:TriggerEvent(TRP3_ScrollBarMixin.Event.OnScroll, self:GetScrollPercentage());
end

function TRP3_ScrollBarMixin:ScrollWheelInDirection(direction)
	self:ScrollInDirection(self:GetWheelExtent(), direction);
end

function TRP3_ScrollBarMixin:ScrollStepInDirection(direction)
	self:ScrollInDirection(self:GetPanExtentPercentage(), direction);
end

function TRP3_ScrollBarMixin:ScrollPageInDirection(direction)
	local visibleExtentPercentage = self:GetVisibleExtentPercentage();
	if visibleExtentPercentage > 0 then
		local pages = 1 / visibleExtentPercentage;
		local magnitude = .95;
		local span = pages - 1;
		if span > 0 then
			self:ScrollInDirection((1 / span) * magnitude, direction);
		end
	end
end

function TRP3_ScrollBarMixin:SetVisibleExtentPercentage(visibleExtentPercentage)
	self.visibleExtentPercentage = Saturate(visibleExtentPercentage);

	self:Update();
end

function TRP3_ScrollBarMixin:GetVisibleExtentPercentage()
	return self.visibleExtentPercentage or 0;
end

function TRP3_ScrollBarMixin:SetScrollPercentage(scrollPercentage, forceImmediate)
	if not forceImmediate and self:CanInterpolateScroll() then
		self:Interpolate(scrollPercentage, self.scrollInternal);
	else
		self:SetScrollPercentageInternal(scrollPercentage);
	end
end

function TRP3_ScrollBarMixin:SetScrollPercentageInternal(scrollPercentage)
	TRP3_ScrollControllerMixin.SetScrollPercentage(self, scrollPercentage);

	self:Update();

	self:TriggerEvent(TRP3_ScrollBarMixin.Event.OnScroll, self:GetScrollPercentage());
end

function TRP3_ScrollBarMixin:HasScrollableExtent()
	return TRP3_MathUtil.WithinRangeExclusive(self:GetVisibleExtentPercentage(), 0, 1);
end

function TRP3_ScrollBarMixin:SetScrollAllowed(allowScroll)
	local oldAllowScroll = self:IsScrollAllowed();
	if oldAllowScroll ~= allowScroll then
		TRP3_ScrollControllerMixin.SetScrollAllowed(self, allowScroll);

		self:Update();

		self:TriggerEvent(TRP3_ScrollBarMixin.Event.OnAllowScrollChanged, allowScroll);
	end
end

function TRP3_ScrollBarMixin:Update()
	if self:HasScrollableExtent() then
		local visibleExtentPercentage = self:GetVisibleExtentPercentage();
		local trackExtent = self:GetTrackExtent();

		local thumb = self:GetThumb();
		local thumbExtent;
		if self.useProportionalThumb then
			local minimumThumbExtent = self.minThumbExtent;
			thumbExtent = Clamp(trackExtent * visibleExtentPercentage, minimumThumbExtent, trackExtent);
			self:SetFrameExtent(thumb, thumbExtent);
		else
			thumbExtent = self:GetFrameExtent(thumb);
		end

		local allowScroll = self:IsScrollAllowed();
		local scrollPercentage = self:GetScrollPercentage();

		-- Consider interpolation so the enabled or disabled state is not delayed as it approaches
		-- 0 or 1.
		local targetScrollPercentage = scrollPercentage;
		local interpolateTo = self:GetScrollInterpolator():GetInterpolateTo();
		if interpolateTo then
			targetScrollPercentage = interpolateTo;
		end

		-- Small exponential representations of zero (ex. E-15) don't evaluate as > 0,
		-- and 1.0 can be represented by .99999XXXXXX.
		self:GetBackStepper():SetEnabled(allowScroll and targetScrollPercentage > TRP3_MathUtil.Epsilon);
		self:GetForwardStepper():SetEnabled(allowScroll and targetScrollPercentage < 1);

		local offset = (trackExtent - thumbExtent) * scrollPercentage;
		local x, y = 0, -offset;
		if self.isHorizontal then
			x, y = -y, x;
		end

		thumb:SetPoint(self:GetThumbAnchor(), self:GetTrack(), self:GetThumbAnchor(), x, y);
		thumb:Show();
		thumb:SetEnabled(allowScroll);
	else
		self:DisableControls();
	end
end

function TRP3_ScrollBarMixin:DisableControls()
	self:GetBackStepper():SetEnabled(false);
	self:GetForwardStepper():SetEnabled(false);
	self:GetThumb():Hide();
	self:GetThumb():SetEnabled(false);
end

function TRP3_ScrollBarMixin:CanCursorStepInDirection(direction)
	local c = self:SelectCursorComponent();
	if direction ==  TRP3_ScrollControllerMixin.Directions.Decrease then
		if self.isHorizontal then
			return c < self:GetUpper(self:GetThumb());
		else
			return c > self:GetUpper(self:GetThumb());
		end
	else
		if self.isHorizontal then
			return c > self:GetLower(self:GetThumb());
		else
			return c < self:GetLower(self:GetThumb());
		end
	end
end

function TRP3_ScrollBarMixin:OnTrackMouseDown(button, buttonName)
	if buttonName ~= "LeftButton" then
		return;
	end

	if not self:HasScrollableExtent() or not self:IsScrollAllowed() then
		return;
	end

	local direction;
	if self:CanCursorStepInDirection(TRP3_ScrollControllerMixin.Directions.Decrease) then
		direction = TRP3_ScrollControllerMixin.Directions.Decrease;
	elseif self:CanCursorStepInDirection(TRP3_ScrollControllerMixin.Directions.Increase) then
		direction = TRP3_ScrollControllerMixin.Directions.Increase;
	end

	if direction then
		self:ScrollPageInDirection(direction);

		local elapsed = 0;
		local repeatTime = self:GetPanRepeatTime();
		local delay = self:GetPanRepeatDelay();
		local stepCount = 0;
		self:SetScript("OnUpdate", function(tbl, dt)
			elapsed = elapsed + dt;
			if elapsed > delay then
				elapsed = 0;

				if self:CanCursorStepInDirection(direction) then
					self:ScrollPageInDirection(direction);
				end

				if stepCount < 1 then
					stepCount = stepCount + 1;
					delay = repeatTime;
				end
			end
		end);

		self:GetTrack():SetScript("OnMouseUp", TRP3_FunctionUtil.GenerateClosure(self.UnregisterUpdate, self));
	end
end

function TRP3_ScrollBarMixin:UnregisterUpdate(button, buttonName)
	if buttonName == "LeftButton" then
		self:SetScript("OnUpdate", nil);
	end
end

function TRP3_ScrollBarMixin:OnThumbMouseDown(button, buttonName)
	if buttonName ~= "LeftButton" then
		return;
	end

	local c = self:SelectCursorComponent();
	local scrollPercentage = self:GetScrollPercentage();
	local extentRemaining = self:GetTrackExtent() - self:GetFrameExtent(self:GetThumb());

	local min, max;
	if self.isHorizontal then
		min = c - scrollPercentage * extentRemaining;
		max = c + (1.0 - scrollPercentage) * extentRemaining;
	else
		min = c - (1.0 - scrollPercentage) * extentRemaining;
		max = c + scrollPercentage * extentRemaining;
	end

	self:SetScript("OnUpdate", function()
		local c = Clamp(self:SelectCursorComponent(), min, max);  -- luacheck: no redefined
		local scrollPercentage;  -- luacheck: no redefined
		if self.isHorizontal then
			scrollPercentage = PercentageBetween(c, min, max);
		else
			scrollPercentage = 1.0 - PercentageBetween(c, min, max);
		end
		self:SetScrollPercentage(scrollPercentage);
	end);

	self:GetThumb():RegisterCallback("OnMouseUp", TRP3_FunctionUtil.GenerateClosure(self.UnregisterUpdate, self), self);
end
