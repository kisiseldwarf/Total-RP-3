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

TRP3_EventEditBoxMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_EventEditBoxMixin:GenerateCallbackEvents(
	{
		"OnMouseDown",
		"OnMouseUp",
		"OnTabPressed",
		"OnTextChanged",
		"OnCursorChanged",
		"OnEscapePressed",
		"OnEditFocusGained",
		"OnEditFocusLost",
	}
);

function TRP3_EventEditBoxMixin:OnEventEditBoxLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxMouseDown()
	self:SetFocus();
	self:TriggerEvent("OnMouseDown", self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxMouseUp()
	self:TriggerEvent("OnMouseUp", self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxTabPressed()
	self:TriggerEvent("OnTabPressed", self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxTextChanged(userChanged)
	if userChanged then
		self.defaulted = self.defaultText and self:GetText() == "";
	end

	self:TriggerEvent("OnTextChanged", self, userChanged);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxCursorChanged(x, y, width, height, context)
	self.cursorOffset = y;
	self.cursorHeight = height;

	if self:HasFocus() then
		self:TriggerEvent("OnCursorChanged", self, x, y, width, height, context);
	end
end

function TRP3_EventEditBoxMixin:OnEventEditBoxEscapePressed()
	self:ClearFocus();

	self:TriggerEvent("OnEscapePressed", self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxEditFocusGained()
	if self:IsDefaultTextDisplayed() then
		self:SetText("");
		self:SetTextColor(self:GetTextColorRGB());
		self:SetCursorPosition(0);
	end

	self:TriggerEvent("OnEditFocusGained", self);
end

function TRP3_EventEditBoxMixin:OnEventEditBoxEditFocusLost()
	self:ClearHighlightText();

	self:TryApplyDefaultText();

	self:TriggerEvent("OnEditFocusLost", self);
end

function TRP3_EventEditBoxMixin:GetCursorOffset()
	return self.cursorOffset or 0;
end

function TRP3_EventEditBoxMixin:GetCursorHeight()
	return self.cursorHeight or 0;
end

function TRP3_EventEditBoxMixin:GetFontHeight()
	return select(2, self:GetFont());
end

function TRP3_EventEditBoxMixin:ApplyText(text)
	self.defaulted = self.defaultText and text == "";
	if self.defaulted then
		self:SetText(self.defaultText);
		self:SetTextColor(GRAY_FONT_COLOR:GetRGB());
	else
		self:SetText(text);
		self:SetTextColor(self:GetTextColorRGB());
	end
	self:SetCursorPosition(0);
end

function TRP3_EventEditBoxMixin:ApplyDefaultText(defaultText)
	self.defaultText = defaultText;

	self:TryApplyDefaultText();
end

function TRP3_EventEditBoxMixin:TryApplyDefaultText()
	if self.defaultText then
		if self:GetText() == "" then
			self:SetText(self.defaultText);
			self:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			self:SetCursorPosition(0);
		end
	end
end

function TRP3_EventEditBoxMixin:GetInputText()
	if not self.defaulted then
		return self:GetText();
	end
	return "";
end

function TRP3_EventEditBoxMixin:IsDefaultTextDisplayed()
	if self.defaulted then
		return self:GetText() == self.defaultText;
	end
	return false;
end

function TRP3_EventEditBoxMixin:ApplyTextColor(color)
	self.textColor = color;

	if not self:IsDefaultTextDisplayed() then
		self:SetTextColor(self:GetTextColorRGB());
	end
end

function TRP3_EventEditBoxMixin:GetTextColorRGB()
	return self.textColor:GetRGB();
end
