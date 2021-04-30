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

TRP3_WowScrollBarStepperButtonScriptsMixin = {};

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnEnter()
	TRP3_TextureUtil.SetTextureToAtlas(self.Overlay, self.overTexture, TRP3_TextureKitConstants.UseAtlasSize);
	self.Overlay:Show();
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnLeave()
	self.Overlay:Hide();
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnMouseDown()
	if self:IsEnabled() then
		TRP3_TextureUtil.SetTextureToAtlas(self.Texture, self.downTexture, TRP3_TextureKitConstants.UseAtlasSize);
		TRP3_RegionUtil.AdjustPointsOffset(self.Texture, -1, 0);
		TRP3_RegionUtil.AdjustPointsOffset(self.Overlay, -1, -1);
	end
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnMouseUp()
	if self:IsEnabled() then
		TRP3_TextureUtil.SetTextureToAtlas(self.Texture, self.normalTexture, TRP3_TextureKitConstants.UseAtlasSize);
		TRP3_RegionUtil.AdjustPointsOffset(self.Texture, 1, 0);
		TRP3_RegionUtil.AdjustPointsOffset(self.Overlay, 1, 1);
	end
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnDisable()
	TRP3_TextureUtil.SetTextureToAtlas(self.Texture, self.disabledTexture, TRP3_TextureKitConstants.UseAtlasSize);
	self.Texture:ClearPointsOffset();
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnEnable()
	TRP3_TextureUtil.SetTextureToAtlas(self.Texture, self.normalTexture, TRP3_TextureKitConstants.UseAtlasSize);
end

function TRP3_WowScrollBarStepperButtonScriptsMixin:OnDisable()
	TRP3_TextureUtil.SetTextureToAtlas(self.Texture, self.disabledTexture, TRP3_TextureKitConstants.UseAtlasSize);
end

TRP3_WowScrollBarThumbButtonScriptsMixin = {};

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnLoad()
	self:ApplyNormalAtlas();
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnEnter()
	TRP3_TextureUtil.SetTextureToAtlas(self.Begin, self.overBeginTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.End, self.overEndTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.Middle, self.overMiddleTexture, TRP3_TextureKitConstants.UseAtlasSize);
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:ApplyNormalAtlas()
	TRP3_TextureUtil.SetTextureToAtlas(self.Begin, self.normalBeginTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.End, self.normalEndTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.Middle, self.normalMiddleTexture, TRP3_TextureKitConstants.UseAtlasSize);
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnLeave()
	self:ApplyNormalAtlas();
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnEnable()
	self:ApplyNormalAtlas();
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnDisable()
	TRP3_TextureUtil.SetTextureToAtlas(self.Begin, self.disabledBeginTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.End, self.disabledEndTexture, TRP3_TextureKitConstants.UseAtlasSize);
	TRP3_TextureUtil.SetTextureToAtlas(self.Middle, self.disabledMiddleTexture, TRP3_TextureKitConstants.UseAtlasSize);
end

function TRP3_WowScrollBarThumbButtonScriptsMixin:OnSizeChanged(width, height)
	-- The original Blizzard code here does stuff with texcoords, however
	-- these seem to cause a rendering issue when used on pre-9.1 and if
	-- omitted don't cause any issue in 9.1 onwards.

	-- local info = TRP3_TextureUtil.GetAtlasInfo(TRP3_TextureUtil.GetAtlasForTexture(self.Middle));
	if self.isHorizontal then
		self.Middle:SetWidth(width);
		-- local u = width / info.width;
		-- self.Middle:SetTexCoord(0, u, 0, 1);
	else
		self.Middle:SetHeight(height);
		-- local v = height / info.height;
		-- self.Middle:SetTexCoord(0, 1, 0, v);
	end
end

TRP3_WowTrimScrollBarMixin = {};

function TRP3_WowTrimScrollBarMixin:OnLoad()
	TRP3_ScrollBarMixin.OnLoad(self);

	if self.hideBackground then
		self.Background:Hide();
	end

	if self.trackAlpha then
		self.Track:SetAlpha(self.trackAlpha);
	end
end

TRP3_ScrollingEditBoxMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);
TRP3_ScrollingEditBoxMixin:GenerateCallbackEvents(
	{
		"OnTabPressed",
		"OnTextChanged",
		"OnCursorChanged",
		"OnFocusGained",
		"OnFocusLost",
		"OnEnterPressed",
	}
);

function TRP3_ScrollingEditBoxMixin:OnLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);

	local scrollBox = self:GetScrollBox();
	scrollBox:SetAlignmentOverlapIgnored(true);

	local fontHeight = 10;
	local editBox = self:GetEditBox();
	if self.fontName then
		editBox:SetFontObject(self.fontName);
		fontHeight = editBox:GetFontHeight();
	end

	if self.maxLetters then
		editBox:SetMaxLetters(self.maxLetters);
	end

	if self.textColor then
		self:SetTextColor(self.textColor);
	end

	if self.defaultText then
		self:SetDefaultText(self.defaultText);
	end

	local bottomPadding = fontHeight * .5;
	local view = TRP3_ScrollUtil.CreateScrollBoxLinearView(0, bottomPadding, 0, 0, 0);
	view:SetPanExtent(fontHeight);
	scrollBox:Init(view);

	editBox:RegisterCallback("OnTabPressed", self.OnEditBoxTabPressed, self);
	editBox:RegisterCallback("OnTextChanged", self.OnEditBoxTextChanged, self);
	editBox:RegisterCallback("OnEnterPressed", self.OnEditBoxEnterPressed, self);
	editBox:RegisterCallback("OnCursorChanged", self.OnEditBoxCursorChanged, self);
	editBox:RegisterCallback("OnEditFocusGained", self.OnEditBoxFocusGained, self);
	editBox:RegisterCallback("OnEditFocusLost", self.OnEditBoxFocusLost, self);
	editBox:RegisterCallback("OnMouseUp", self.OnEditBoxMouseUp, self);
end

function TRP3_ScrollingEditBoxMixin:OnShow()
	local editBox = self:GetEditBox();
	editBox:TryApplyDefaultText();
end

function TRP3_ScrollingEditBoxMixin:OnMouseDown()
	local editBox = self:GetEditBox();
	editBox:SetFocus();
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxMouseUp()
	local allowCursorClipping = false;
	self:ScrollCursorIntoView(allowCursorClipping);
end

function TRP3_ScrollingEditBoxMixin:GetScrollBox()
	return self.ScrollBox;
end

function TRP3_ScrollingEditBoxMixin:HasScrollableExtent()
	local scrollBox = self:GetScrollBox();
	return scrollBox:HasScrollableExtent();
end

function TRP3_ScrollingEditBoxMixin:GetEditBox()
	return self:GetScrollBox().EditBox;
end

function TRP3_ScrollingEditBoxMixin:SetFontObject(fontName)
	local editBox = self:GetEditBox();
	editBox:SetFontObject(fontName);

	local scrollBox = self:GetScrollBox();
	local fontHeight = editBox:GetFontHeight();
	local padding = scrollBox:GetPadding();
	padding:SetBottom(fontHeight * .5);

	scrollBox:SetPanExtent(fontHeight);
	scrollBox:UpdateImmediately();
	scrollBox:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
end

function TRP3_ScrollingEditBoxMixin:ClearText()
	self:SetText("");
end

function TRP3_ScrollingEditBoxMixin:SetText(text)
	local editBox = self:GetEditBox();
	editBox:ApplyText(text);

	local scrollBox = self:GetScrollBox();
	scrollBox:UpdateImmediately();
	scrollBox:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
end

function TRP3_ScrollingEditBoxMixin:SetDefaultText(defaultText)
	local editBox = self:GetEditBox();
	editBox:ApplyDefaultText(defaultText);
end

function TRP3_ScrollingEditBoxMixin:SetTextColor(color)
	local editBox = self:GetEditBox();
	editBox:ApplyTextColor(color);
end

function TRP3_ScrollingEditBoxMixin:GetInputText()
	local editBox = self:GetEditBox();
	return editBox:GetInputText();
end

function TRP3_ScrollingEditBoxMixin:GetFontHeight()
	local editBox = self:GetEditBox();
	return editBox:GetFontHeight();
end

function TRP3_ScrollingEditBoxMixin:ClearFocus()
	local editBox = self:GetEditBox();
	editBox:ClearFocus();
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxTabPressed(editBox)
	self:TriggerEvent("OnTabPressed", editBox);
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxTextChanged(editBox, userChanged)
	local scrollBox = self:GetScrollBox();
	scrollBox:UpdateImmediately();

	self:TriggerEvent("OnTextChanged", editBox, userChanged);
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxEnterPressed(editBox)
	self:TriggerEvent("OnEnterPressed", editBox);
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxCursorChanged(editBox, x, y, width, height, context)
	local scrollBox = self:GetScrollBox();
	scrollBox:UpdateImmediately();

	local allowCursorClipping;

	if Enum.InputContext then
		allowCursorClipping = context ~= Enum.InputContext.Keyboard;
	else
		allowCursorClipping = false;
	end

	self:ScrollCursorIntoView(allowCursorClipping);

	self:TriggerEvent("OnCursorChanged", editBox, x, y, width, height);
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxFocusGained(editBox)
	self:TriggerEvent("OnFocusGained", editBox);
end

function TRP3_ScrollingEditBoxMixin:OnEditBoxFocusLost(editBox)
	self:TriggerEvent("OnFocusLost", editBox);
end

function TRP3_ScrollingEditBoxMixin:ScrollCursorIntoView(allowCursorClipping)
	local editBox = self:GetEditBox();
	local cursorOffset = -editBox:GetCursorOffset();
	local cursorHeight = editBox:GetCursorHeight();

	local scrollBox = self:GetScrollBox();
	local editBoxExtent = scrollBox:GetFrameExtent(editBox);
	if editBoxExtent <= 0 then
		return;
	end

	local scrollOffset = scrollBox:GetDerivedScrollOffset();
	if cursorOffset < scrollOffset then
		local visibleExtent = scrollBox:GetVisibleExtent();
		local deltaExtent = editBoxExtent - visibleExtent;
		if deltaExtent > 0 then
			local percentage = cursorOffset / deltaExtent;
			scrollBox:ScrollToFrame(editBox, percentage);
		end
	else
		local visibleExtent = scrollBox:GetVisibleExtent();
		local offset = allowCursorClipping and cursorOffset or (cursorOffset + cursorHeight);
		if offset >= (scrollOffset + visibleExtent) then
			local deltaExtent = editBoxExtent - visibleExtent;
			if deltaExtent > 0 then
				local descenderPadding = math.floor(cursorHeight * .3);
				local cursorDeltaExtent = offset - visibleExtent;
				if cursorDeltaExtent + descenderPadding > deltaExtent then
					scrollBox:ScrollToEnd();
				else
					local percentage = (cursorDeltaExtent + descenderPadding) / deltaExtent;
					scrollBox:ScrollToFrame(editBox, percentage);
				end
			end
		end
	end
end

TRP3_ScrollingFontMixin = {};

function TRP3_ScrollingFontMixin:OnLoad()
	TRP3_CallbackRegistryMixin.OnLoad(self);

	local fontHeight = 10;
	local fontString = self:GetFontString();
	if self.fontName then
		fontString:SetFontObject(self.fontName);
		fontHeight = select(2, fontString:GetFont());
	end

	local scrollBox = self:GetScrollBox();
	scrollBox:SetAlignmentOverlapIgnored(true);

	local bottomPadding = fontHeight * .5;
	local view = TRP3_ScrollUtil.CreateScrollBoxLinearView(0, bottomPadding, 0, 0, 0);
	view:SetPanExtent(fontHeight);
	scrollBox:Init(view);

	local width = scrollBox:GetWidth();
	local fontStringContainer = self:GetFontStringContainer();
	fontStringContainer:SetWidth(width);
	fontString:SetWidth(width);
end

function TRP3_ScrollingFontMixin:OnSizeChanged(width, height)
	local scrollBox = self:GetScrollBox();
	scrollBox:SetWidth(width);

	local fontStringContainer = self:GetFontStringContainer();
	fontStringContainer:SetWidth(width);

	local fontString = self:GetFontString();
	fontString:SetWidth(width);
end

function TRP3_ScrollingFontMixin:GetScrollBox()
	return self.ScrollBox;
end

function TRP3_ScrollingFontMixin:HasScrollableExtent()
	local scrollBox = self:GetScrollBox();
	return scrollBox:HasScrollableExtent();
end

function TRP3_ScrollingFontMixin:GetFontString()
	local fontStringContainer = self:GetFontStringContainer();
	return fontStringContainer.FontString;
end

function TRP3_ScrollingFontMixin:GetFontStringContainer()
	local scrollBox = self:GetScrollBox();
	return scrollBox.FontStringContainer;
end

function TRP3_ScrollingFontMixin:SetText(text)
	local fontString = self:GetFontString();
	fontString:SetText(text);
	local height = fontString:GetStringHeight();

	local fontStringContainer = self:GetFontStringContainer();
	fontStringContainer:SetHeight(height);

	local scrollBox = self:GetScrollBox();
	scrollBox:UpdateImmediately();
	scrollBox:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
end

function TRP3_ScrollingFontMixin:ClearText()
	self:SetText("");
end

function TRP3_ScrollingFontMixin:SetTextColor(color)
	local fontString = self:GetFontString();
	fontString:SetTextColor(color.r, color.g, color.b);
end

function TRP3_ScrollingFontMixin:SetFontObject(fontName)
	local fontString = self:GetFontString();
	fontString:SetFontObject(fontName);

	local scrollBox = self:GetScrollBox();
	local fontHeight = select(2, fontString:GetFont());
	local padding = scrollBox:GetPadding();
	padding:SetBottom(fontHeight * .5);

	scrollBox:SetPanExtent(fontHeight);
	scrollBox:UpdateImmediately();
	scrollBox:ScrollToBegin(TRP3_ScrollBoxConstants.NoScrollInterpolation);
end
