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

TRP3_ScrollingHTMLMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_ScrollingHTMLMixin:GenerateCallbackEvents(
	{
		"OnHyperlinkClick",
		"OnHyperlinkEnter",
		"OnHyperlinkLeave",
	}
);

function TRP3_ScrollingHTMLMixin:OnLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);

	local scrollBox = self:GetScrollBox();
	local view = TRP3_ScrollUtil.CreateScrollBoxLinearView(0, 0, 0, 0);
	scrollBox:SetAlignmentOverlapIgnored(true);
	scrollBox:Init(view);

	local simpleHTML = self:GetSimpleHTML();

	if self.fontNameH1 then
		simpleHTML:SetFontObject("H1", self.fontNameH1);
	end

	if self.fontNameH2 then
		simpleHTML:SetFontObject("H2", self.fontNameH2);
	end

	if self.fontNameH3 then
		simpleHTML:SetFontObject("H3", self.fontNameH3);
	end

	if self.fontName then
		simpleHTML:SetFontObject("P", self.fontName);
	end

	if self.textColor then
		self:SetTextColor(self.textColor);
	end

	if self.hyperlinkFormat then
		self:SetHyperlinkFormat(self.hyperlinkFormat);
	end

	if self.panExtent then
		self:SetPanExtent(self.panExtent);
	else
		self:SetPanExtent(self:GetElementFontHeight("P") * 4);
	end

	simpleHTML:RegisterCallback("OnHyperlinkClick", self.OnHyperlinkClick, self);
	simpleHTML:RegisterCallback("OnHyperlinkEnter", self.OnHyperlinkEnter, self);
	simpleHTML:RegisterCallback("OnHyperlinkLeave", self.OnHyperlinkLeave, self);

	self:UpdatePadding();
end

function TRP3_ScrollingHTMLMixin:GetText()
	return self.textData or "";
end

function TRP3_ScrollingHTMLMixin:SetText(text)
	local simpleHTML = self:GetSimpleHTML();
	simpleHTML:SetText(text);
	simpleHTML:SetHeight(simpleHTML:GetContentHeight());

	self.textData = text;  -- Classic: SimpleHTML lacks a getter for raw HTML data.
	self:UpdateImmediately();
end

function TRP3_ScrollingHTMLMixin:ClearText()
	self:SetText("");
end

function TRP3_ScrollingHTMLMixin:SetTextColor(color)
	local simpleHTML = self:GetSimpleHTML();
	simpleHTML:SetTextColor(color.r, color.g, color.b);
end

function TRP3_ScrollingHTMLMixin:GetHyperlinkFormat()
	local simpleHTML = self:GetSimpleHTML();
	return simpleHTML:GetHyperlinkFormat();
end

function TRP3_ScrollingHTMLMixin:SetHyperlinkFormat(format)
	local simpleHTML = self:GetSimpleHTML();
	simpleHTML:SetHyperlinkFormat(format);
end

function TRP3_ScrollingHTMLMixin:GetElementFontHeight(element)
	local elementFont = self:GetElementFontObject(element);
	return (select(2, elementFont:GetFont()));
end

function TRP3_ScrollingHTMLMixin:GetElementFontObject(element)
	local simpleHTML = self:GetSimpleHTML();
	return simpleHTML:GetFontObject(element);
end

function TRP3_ScrollingHTMLMixin:SetElementFontObject(element, fontName)
	local simpleHTML = self:GetSimpleHTML();
	simpleHTML:SetFontObject(element, fontName);

	self:UpdatePadding();
end

function TRP3_ScrollingHTMLMixin:GetScrollBox()
	return self.ScrollBox;
end

function TRP3_ScrollingHTMLMixin:HasScrollableExtent()
	local scrollBox = self:GetScrollBox();
	return scrollBox:HasScrollableExtent();
end

function TRP3_ScrollingHTMLMixin:GetSimpleHTML()
	return self:GetScrollBox().SimpleHTML;
end

function TRP3_ScrollingHTMLMixin:GetPanExtent()
	local scrollBox = self:GetScrollBox();
	return scrollBox:GetPanExtent();
end

function TRP3_ScrollingHTMLMixin:SetPanExtent(panExtent)
	local scrollBox = self:GetScrollBox();
	scrollBox:SetPanExtent(panExtent);
end

function TRP3_ScrollingHTMLMixin:GetScrollPercentage()
	local scrollBox = self:GetScrollBox();
	return scrollBox:GetScrollPercentage();
end

function TRP3_ScrollingHTMLMixin:SetScrollPercentage(scrollPercentage, interpolation)
	local scrollBox = self:GetScrollBox();
	scrollBox:SetScrollPercentage(scrollPercentage, interpolation);
end

function TRP3_ScrollingHTMLMixin:ScrollToBegin(interpolation)
	local scrollBox = self:GetScrollBox();
	scrollBox:ScrollToBegin(interpolation);
end

function TRP3_ScrollingHTMLMixin:ScrollToEnd(interpolation)
	local scrollBox = self:GetScrollBox();
	scrollBox:ScrollToEnd(interpolation);
end

function TRP3_ScrollingHTMLMixin:OnSizeChanged(width, height)  -- luacheck: no unused (height)
	local simpleHTML = self:GetSimpleHTML();
	simpleHTML:SetWidth(width);
	simpleHTML:SetHeight(simpleHTML:GetContentHeight());

	self:UpdateImmediately();
end

function TRP3_ScrollingHTMLMixin:OnHyperlinkClick(link, text, button)
	self:TriggerEvent("OnHyperlinkClick", link, text, button);
end

function TRP3_ScrollingHTMLMixin:OnHyperlinkEnter(link, text)
	self:TriggerEvent("OnHyperlinkEnter", link, text);
end

function TRP3_ScrollingHTMLMixin:OnHyperlinkLeave(link, text)
	self:TriggerEvent("OnHyperlinkLeave", link, text);
end

function TRP3_ScrollingHTMLMixin:UpdatePadding()
	local scrollBox = self:GetScrollBox();
	local fontHeight = self:GetElementFontHeight("p");
	local padding = scrollBox:GetPadding();

	padding:SetBottom(fontHeight * 0.5);
	scrollBox:UpdateImmediately();
end

function TRP3_ScrollingHTMLMixin:UpdateImmediately()
	local scrollBox = self:GetScrollBox();
	scrollBox:UpdateImmediately();
end
