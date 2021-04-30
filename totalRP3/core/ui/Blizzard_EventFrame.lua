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

TRP3_EventFrameMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_EventFrameMixin:GenerateCallbackEvents(
	{
		"OnHide",
		"OnShow",
		"OnSizeChanged",
	}
);

function TRP3_EventFrameMixin:OnEventFrameLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);
end

function TRP3_EventFrameMixin:OnEventFrameHide()
	self:TriggerEvent("OnHide");
end

function TRP3_EventFrameMixin:OnEventFrameShow()
	self:TriggerEvent("OnShow");
end

function TRP3_EventFrameMixin:OnEventFrameSizeChanged(width, height)
	self:TriggerEvent("OnSizeChanged", width, height);
end
