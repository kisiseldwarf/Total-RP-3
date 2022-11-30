-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local TRP3 = select(2, ...);

--
-- Data Provider
--
-- The colorpicker dataprovider stores colors in decomposed (HSVA) form to
-- ensure that selected values (like hue) don't reset if the user sets the
-- other components to white or black.
--

-- TODO: Merge across CBR changes.
TRP3_ColorPickerDataProviderMixin = CreateFromMixins(CallbackRegistryMixin);
TRP3_ColorPickerDataProviderMixin:GenerateCallbackEvents({
	"OnOpacityEnabledChanged",
	"OnSelectedValuesChanged",
});

function TRP3_ColorPickerDataProviderMixin:Init(initialColor)
	CallbackRegistryMixin.OnLoad(self);

	if not initialColor then
		initialColor = TRP3.CreateColorFromHSLA(fastrandom(), 0.8, 0.5);
	end

	self.h, self.s, self.v, self.a = initialColor:GetHSVA();
	self.opacityEnabled = true;
end

function TRP3_ColorPickerDataProviderMixin:GetSelectedColor()
	local h, s, v, a = self:GetSelectedValues();

	if not self:IsOpacityEnabled() then
		a = 1;
	end

	return TRP3.CreateColorFromHSVA(h, s, v, a);
end

function TRP3_ColorPickerDataProviderMixin:GetSelectedValues()
	return self.h, self.s, self.v, self.a;
end

function TRP3_ColorPickerDataProviderMixin:IsOpacityEnabled()
	return self.opacityEnabled;
end

function TRP3_ColorPickerDataProviderMixin:SetOpacityEnabled(enabled)
	if self.opacityEnabled == enabled then
		return;
	end

	self.opacityEnabled = enabled;

	-- Trigger both these events as toggling opacity has a "soft" effect on
	-- the alpha value, which should lead to some visual changes.

	self:TriggerEvent("OnOpacityEnabledChanged", self.opacityEnabled);
	self:TriggerEvent("OnSelectedValuesChanged", self:GetSelectedValues());
end

function TRP3_ColorPickerDataProviderMixin:SetSelectedValues(h, s, v, a)
	if self.h == h and self.s == s and self.v == v and self.a == a then
		return;
	end

	self.h, self.s, self.v, self.a = h, s, v, a;
	self:TriggerEvent("OnSelectedValuesChanged", self:GetSelectedValues());
end

function TRP3_ColorPickerDataProviderMixin:SetSelectedColor(color)
	local h, s, v, a = color:GetHSVA();

	-- If either saturation or value are zero then the calculated hue also
	-- ends up at zero. In such a case, preserve the existing hue for the UI.

	if s == 0 or v == 0 then
		h = self.h;
	end

	self:SetSelectedValues(h, s, v, a);
end

function TRP3.CreateColorPickerDataProvider(initialColor)
	return TRP3.CreateAndInitFromMetaMixin(TRP3_ColorPickerDataProviderMixin, initialColor);
end

--
-- Common Color Picker Widget Mixin
--
-- This provides a few common functions for using color picker data providers
-- and being notified of changes to the selected color.
--

TRP3_ColorPickerWidgetBaseMixin = {};

function TRP3_ColorPickerWidgetBaseMixin:OnDataProviderChanged(dataProvider)  -- luacheck: no unused
	-- No-op; implement in a derived mixin to be notified of data provider changes.
end

function TRP3_ColorPickerWidgetBaseMixin:GetDataProvider()
	return self.dataProvider;
end

function TRP3_ColorPickerWidgetBaseMixin:SetDataProvider(dataProvider)
	if self.dataProvider == dataProvider then
		return;
	end

	if self.dataProvider then
		self.dataProvider:UnregisterAllCallbacks(self);
	end

	self.dataProvider = dataProvider;
	self:OnDataProviderChanged(self.dataProvider);
end

--
-- "Neon yellow-green baby poop" Selector
--

TRP3_ColorPickerShadePickerMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerShadePickerMixin:OnDataProviderChanged(dataProvider)
	dataProvider:RegisterCallback("OnSelectedValuesChanged", self.UpdateDisplayedColor, self);
	self:UpdateDisplayedColor();
end

function TRP3_ColorPickerShadePickerMixin:OnUpdate()
	self:UpdateSelectedColor();
end

function TRP3_ColorPickerShadePickerMixin:OnMouseDown()
	self:SetScript("OnUpdate", self.OnUpdate);
end

function TRP3_ColorPickerShadePickerMixin:OnMouseUp()
	self:SetScript("OnUpdate", nil);
	self:UpdateSelectedColor();
end

function TRP3_ColorPickerShadePickerMixin:UpdateDisplayedColor()
	local h, s, v = self:GetDataProvider():GetSelectedValues();

	local width, height = select(3, self:GetCanvasRect());
	local padding = self:GetCanvasPadding();
	local scale = self:GetEffectiveScale();

	local xOffset = ((s * width) + padding) * scale;  -- TODO: Test with scaling.
	local yOffset = ((v * height) + padding) * scale;  -- TODO: Test with scaling.

	self.ThumbBorder:ClearAllPoints();
	self.ThumbBorder:SetPoint("CENTER", self, "BOTTOMLEFT", xOffset, yOffset);
	self.ThumbFill:SetVertexColor(self:GetDataProvider():GetSelectedColor():GetRGB());
	self.Color:SetColorTexture(TRP3.CreateColorFromHSVA(h, 1, 1):GetRGB());
end

function TRP3_ColorPickerShadePickerMixin:UpdateSelectedColor()
	local cx, cy = GetCursorPosition();
	local left, bottom, width, height = self:GetCanvasRect();

	local dx = Clamp(cx, left, left + width) - left;
	local dy = Clamp(cy, bottom, bottom + height) - bottom;

	local h, _, _, a = self:GetDataProvider():GetSelectedValues();
	local s = Saturate(dx / width);
	local v = Saturate(dy / height);

	self:GetDataProvider():SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerShadePickerMixin:GetCanvasRect()
	local left, bottom, width, height = self:GetRect();
	local padding = self:GetCanvasPadding();

	left = left + padding;
	bottom = bottom + padding;
	width = width - (padding * 2);
	height = height - (padding * 2);

	return left, bottom, width, height;
end

function TRP3_ColorPickerShadePickerMixin:GetCanvasPadding()
	return 12;
end

--
-- Common Slider Mixin
--

TRP3_ColorPickerSliderMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerSliderMixin:OnValueChanged(value)  -- luacheck: no unused
	-- No-op; override in a derived mixin to update the data provider.
end

function TRP3_ColorPickerSliderMixin:OnDataProviderChanged(dataProvider)
	dataProvider:RegisterCallback("OnSelectedValuesChanged", self.UpdateDeferred, self);
	self:UpdateDeferred();
end

function TRP3_ColorPickerSliderMixin:UpdateDeferred()
	self:SetScript("OnUpdate", self.UpdateImmediately);
end

function TRP3_ColorPickerSliderMixin:UpdateImmediately()
	self:SetScript("OnUpdate", nil);
	self:UpdateDisplayedColor();
end

function TRP3_ColorPickerSliderMixin:UpdateDisplayedColor()
	-- No-op; override in a derived mixin to update the slider.
end

--
-- Hue Slider
--

TRP3_ColorPickerHueSliderMixin = CreateFromMixins(TRP3_ColorPickerSliderMixin);

function TRP3_ColorPickerHueSliderMixin:OnLoad()
	-- Anchors to <ThumbTexture> elements don't work in XML.
	self.ThumbFill:SetAllPoints(self.ThumbBorder);
end

function TRP3_ColorPickerHueSliderMixin:OnSizeChanged()
	local extent = self:GetGradientElementExtent();
	local padding = self:GetGradientPadding();

	for i, texture in ipairs(self.backgroundTextures) do
		texture:ClearAllPoints();
		texture:SetPoint("TOPLEFT", (i - 1) * extent + padding, -padding);
		texture:SetPoint("BOTTOM", 0, padding);
		texture:SetWidth(extent);
	end
end

function TRP3_ColorPickerHueSliderMixin:OnValueChanged(value)
	local _, s, v, a = self:GetDataProvider():GetSelectedValues();
	local h = value / 360;

	self:GetDataProvider():SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerHueSliderMixin:UpdateDisplayedColor()
	local h = self:GetDataProvider():GetSelectedValues();

	if h == 1 then
		h = 0;
	end

	self:SetValue(math.floor(h * 360));
	self.ThumbFill:SetVertexColor(TRP3.CreateColorFromHSVA(h, 1, 1):GetRGB());
end

function TRP3_ColorPickerHueSliderMixin:GetGradientElementExtent()
	local widthPadding = (self:GetGradientPadding() * 2);
	return (self:GetWidth() - widthPadding) / self:GetGradientStride();
end

function TRP3_ColorPickerHueSliderMixin:GetGradientStride()
	return #self.backgroundTextures;
end

function TRP3_ColorPickerHueSliderMixin:GetGradientPadding()
	return 3;
end

--
-- Opacity Slider
--

TRP3_ColorPickerOpacitySliderMixin = CreateFromMixins(TRP3_ColorPickerSliderMixin);

function TRP3_ColorPickerOpacitySliderMixin:OnDataProviderChanged(dataProvider)
	TRP3_ColorPickerSliderMixin.OnDataProviderChanged(self, dataProvider);
	dataProvider:RegisterCallback("OnOpacityEnabledChanged", self.UpdateVisibility, self);
end

function TRP3_ColorPickerOpacitySliderMixin:OnValueChanged(value)
	local h, s, v = self:GetDataProvider():GetSelectedValues();
	local a = value / 100;

	self:GetDataProvider():SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerOpacitySliderMixin:UpdateDisplayedColor()
	local h, s, v, a = self:GetDataProvider():GetSelectedValues();

	self:SetValue(math.floor(a * 100));

	local startColor = TRP3.CreateColorFromHSVA(h, s, v, 0);
	local endColor = TRP3.CreateColorFromHSVA(h, s, v, 1);
	self.Gradient:SetGradient("HORIZONTAL", startColor, endColor);
end

function TRP3_ColorPickerOpacitySliderMixin:UpdateVisibility()
	self:SetShown(self:GetDataProvider():IsOpacityEnabled());
end

--
-- Preview Swatch
--

TRP3_ColorPickerPreviewSwatchMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerPreviewSwatchMixin:OnEnter()
	-- TODO: Tooltip stuff can be handled through better means.
	TRP3_MainTooltip:SetOwner(self, "ANCHOR_RIGHT");
	TRP3_MainTooltip:SetText(self:GetDataProvider():GetSelectedColor():GenerateColorString());
	TRP3_MainTooltip:Show();
end

function TRP3_ColorPickerPreviewSwatchMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_ColorPickerPreviewSwatchMixin:OnDataProviderChanged(dataProvider)
	dataProvider:RegisterCallback("OnSelectedValuesChanged", self.UpdateDisplayedColor, self);
	dataProvider:RegisterCallback("OnOpacityEnabledChanged", self.UpdateVisibility, self);
	self:UpdateDisplayedColor();
end

function TRP3_ColorPickerPreviewSwatchMixin:UpdateDisplayedColor()
	self.Color:SetColorTexture(self:GetDataProvider():GetSelectedColor():GetRGBA());
end

function TRP3_ColorPickerPreviewSwatchMixin:UpdateVisibility()
	if self:GetDataProvider():IsOpacityEnabled() then
		self:SetSize(44, 44);
	else
		self:SetSize(20, 20);
	end
end

--
-- Color Picker Frame
--

TRP3_ColorPickerMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerMixin:OnLoad()
	self:SetDataProvider(TRP3.CreateColorPickerDataProvider(self.initialColor));
end

function TRP3_ColorPickerMixin:GetSelectedColor()
	return self:GetDataProvider():GetSelectedColor();
end

function TRP3_ColorPickerMixin:GetSelectedValues()
	return self:GetDataProvider():GetSelectedValues();
end

function TRP3_ColorPickerMixin:IsOpacityEnabled()
	return self:GetDataProvider():IsOpacityEnabled();
end

function TRP3_ColorPickerMixin:SetOpacityEnabled(enabled)
	self:GetDataProvider():SetOpacityEnabled(enabled);
end

function TRP3_ColorPickerMixin:SetSelectedColor(color)
	self:GetDataProvider():SetSelectedColor(color);
end

function TRP3_ColorPickerMixin:SetSelectedValues(h, s, v, a)
	self:GetDataProvider():SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerMixin:OnDataProviderChanged(dataProvider)
	-- Opacity enable state changes should re-layout the frame.
	dataProvider:RegisterCallback("OnOpacityEnabledChanged", self.MarkDirty, self);

	self.HueSlider:SetDataProvider(dataProvider);
	self.OpacitySlider:SetDataProvider(dataProvider);
	self.ShadePicker:SetDataProvider(dataProvider);
	self.PreviewSwatch:SetDataProvider(dataProvider);
end
