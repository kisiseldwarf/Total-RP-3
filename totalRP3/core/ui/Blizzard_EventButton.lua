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

TRP3_EventButtonMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_EventButtonMixin:GenerateCallbackEvents(
	{
		"OnMouseUp",
		"OnMouseDown",
		"OnClick",
		"OnEnter",
		"OnLeave",
		"OnSizeChanged",
	}
);

local function PlaySoundKit(button, soundKitID)
	if soundKitID and button:IsEnabled() then
		PlaySound(soundKitID);
	end
end

function TRP3_EventButtonMixin:OnEventButtonLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);
end

function TRP3_EventButtonMixin:OnEventButtonMouseUp(buttonName, upInside)
	self:TriggerEvent("OnMouseUp", buttonName, upInside);
	PlaySoundKit(self, self.mouseUpSoundKitID);
end

function TRP3_EventButtonMixin:OnEventButtonMouseDown(buttonName)
	if self:IsEnabled() then
		self:TriggerEvent("OnMouseDown", buttonName);
		PlaySoundKit(self, self.mouseDownSoundKitID);
	end
end

function TRP3_EventButtonMixin:OnEventButtonClick(buttonName, down)
	if self:IsEnabled() then
		self:TriggerEvent("OnClick", buttonName, down);
		PlaySoundKit(self, self.clickSoundKitID);
	end
end

function TRP3_EventButtonMixin:OnEventButtonEnter()
	if self:IsEnabled() then
		self:TriggerEvent("OnEnter");
	end
end

function TRP3_EventButtonMixin:OnEventButtonLeave()
	self:TriggerEvent("OnLeave");
end

function TRP3_EventButtonMixin:OnEventButtonSizeChanged(width, height)
	self:TriggerEvent("OnSizeChanged", width, height);
end
