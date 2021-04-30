----------------------------------------------------------------------------------
--- Total RP 3
--- ---------------------------------------------------------------------------
--- Copyright 2020 Total RP 3 Development Team
---
--- Licensed under the Apache License, Version 2.0 (the "License");
--- you may not use this file except in compliance with the License.
--- You may obtain a copy of the License at
---
---   http://www.apache.org/licenses/LICENSE-2.0
---
--- Unless required by applicable law or agreed to in writing, software
--- distributed under the License is distributed on an "AS IS" BASIS,
--- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--- See the License for the specific language governing permissions and
--- limitations under the License.
----------------------------------------------------------------------------------

--[[
	TRP3_TruncatedTextMixin
--]]

TRP3_TruncatedTextMixin = CreateFromMixins(FontableFrameMixin);

function TRP3_TruncatedTextMixin:OnLoad()
	self.Text = self:CreateFontString(nil, self.fontStringLayer, self.fontStringTemplate, self.fontStringSubLayer);
	self.Text:SetAllPoints(self);

	if self.fontStringColor then
		self.Text:SetTextColor(self.fontStringColor);
	end

	if self.fontStringJustifyH then
		self.Text:SetJustifyH(self.fontStringJustifyH);
	end

	if self.fontStringJustifyV then
		self.Text:SetJustifyV(self.fontStringJustifyV);
	end
end

function TRP3_TruncatedTextMixin:GetText()
	return self.Text:GetText();
end

function TRP3_TruncatedTextMixin:IsTruncated()
	return self.Text:IsTruncated();
end

function TRP3_TruncatedTextMixin:SetFormattedText(format, ...)
	return self.Text:SetFormattedText(format, ...)
end

function TRP3_TruncatedTextMixin:SetText(text)
	return self.Text:SetText(text);
end

--[[override]] function TRP3_TruncatedTextMixin:OnFontObjectUpdated()
	self.Text:SetFontObject(self:GetFontObject());
end
