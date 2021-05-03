-- Copyright 2021 Total RP 3 Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

TRP3_EventHTMLMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_EventHTMLMixin:GenerateCallbackEvents(
	{
		"OnHide",
		"OnShow",
		"OnSizeChanged",
		"OnHyperlinkClick",
		"OnHyperlinkEnter",
		"OnHyperlinkLeave",
	}
);

function TRP3_EventHTMLMixin:OnEventHTMLLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);
end

function TRP3_EventHTMLMixin:OnEventHTMLHide()
	self:TriggerEvent("OnHide");
end

function TRP3_EventHTMLMixin:OnEventHTMLShow()
	self:TriggerEvent("OnShow");
end

function TRP3_EventHTMLMixin:OnEventHTMLSizeChanged(width, height)
	self:TriggerEvent("OnSizeChanged", width, height);
end

function TRP3_EventHTMLMixin:OnEventHTMLHyperlinkClick(link, text, button)
	self:TriggerEvent("OnHyperlinkClick", link, text, button);
end

function TRP3_EventHTMLMixin:OnEventHTMLHyperlinkEnter(link, text)
	self:TriggerEvent("OnHyperlinkEnter", link, text);
end

function TRP3_EventHTMLMixin:OnEventHTMLHyperlinkLeave(link, text)
	self:TriggerEvent("OnHyperlinkLeave", link, text);
end
