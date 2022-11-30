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
	"OnSelectedValuesChanged"
});

function TRP3_ColorPickerDataProviderMixin:Init(initialColor)
	CallbackRegistryMixin.OnLoad(self);

	if not initialColor then
		initialColor = TRP3.CreateColorFromHSLA(fastrandom(), 0.8, 0.5);
	end

	self.h, self.s, self.v, self.a = initialColor:GetHSVA();
end

function TRP3_ColorPickerDataProviderMixin:GetSelectedColor()
	return TRP3.CreateColorFromHSVA(self:GetSelectedValues());
end

function TRP3_ColorPickerDataProviderMixin:GetSelectedValues()
	return self.h, self.s, self.v, self.a;
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

function TRP3_ColorPickerWidgetBaseMixin:OnSelectedValuesChanged(h, s, v, a)  -- luacheck: no unused
	-- No-op; implement in a derived mixin to be notified of selected color changes.
end

function TRP3_ColorPickerWidgetBaseMixin:GetDataProvider()
	return self.dataProvider;
end

function TRP3_ColorPickerWidgetBaseMixin:GetSelectedColor()
	local color;

	if self.dataProvider then
		color = self.dataProvider:GetSelectedColor();
	else
		color = TRP3.Colors.WHITE;
	end

	return color;
end

function TRP3_ColorPickerWidgetBaseMixin:GetSelectedValues()
	local h, s, v, a;

	if self.dataProvider then
		h, s, v, a = self.dataProvider:GetSelectedValues();
	else
		h, s, v, a = TRP3.Colors.WHITE:GetHSVA();
	end

	return h, s, v, a;
end

function TRP3_ColorPickerWidgetBaseMixin:SetDataProvider(dataProvider)
	if self.dataProvider == dataProvider then
		return;
	end

	if self.dataProvider then
		self.dataProvider:UnregisterAllCallbacks(self);
	end

	self.dataProvider = dataProvider;

	if self.dataProvider then
		self.dataProvider:RegisterCallback("OnSelectedValuesChanged", self.OnSelectedValuesChanged, self);
	end

	self:OnDataProviderChanged(self.dataProvider);
end

function TRP3_ColorPickerWidgetBaseMixin:SetSelectedColor(color)
	if self.dataProvider then
		self.dataProvider:SetSelectedColor(color);
	end
end

function TRP3_ColorPickerWidgetBaseMixin:SetSelectedValues(h, s, v, a)
	if self.dataProvider then
		self.dataProvider:SetSelectedValues(h, s, v, a);
	end
end

--
-- "Neon yellow-green baby poop" Selector
--

TRP3_ColorPickerShadePickerMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerShadePickerMixin:OnSelectedValuesChanged(h, s, v)
	local width, height = select(3, self:GetCanvasRect());
	local padding = self:GetCanvasPadding();
	local scale = self:GetEffectiveScale();

	local xOffset = ((s * width) + padding) * scale;  -- TODO: Test with scaling.
	local yOffset = ((v * height) + padding) * scale;  -- TODO: Test with scaling.

	self.ThumbBorder:ClearAllPoints();
	self.ThumbBorder:SetPoint("CENTER", self, "BOTTOMLEFT", xOffset, yOffset);
	self.ThumbFill:SetVertexColor(self:GetSelectedColor():GetRGB());
	self.Color:SetColorTexture(TRP3.CreateColorFromHSVA(h, 1, 1):GetRGB());
end

function TRP3_ColorPickerShadePickerMixin:OnUpdate()
	self:DoTheThing();  -- TODO: Should this be throttled a bit?
end

function TRP3_ColorPickerShadePickerMixin:OnMouseDown()
	self:SetScript("OnUpdate", self.OnUpdate);
end

function TRP3_ColorPickerShadePickerMixin:OnMouseUp()
	self:SetScript("OnUpdate", nil);
end

function TRP3_ColorPickerShadePickerMixin:DoTheThing()
	local cx, cy = GetCursorPosition();
	local left, bottom, width, height = self:GetCanvasRect();

	local dx = Clamp(cx, left, left + width) - left;
	local dy = Clamp(cy, bottom, bottom + height) - bottom;

	local h, _, _, a = self:GetSelectedValues();
	local s = Saturate(dx / width);
	local v = Saturate(dy / height);

	self:SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerShadePickerMixin:GetCanvasRect()
	local left, bottom, width, height = self:GetRect();
	local padding = self:GetCanvasPadding();

	left = left + padding;
	bottom = bottom - padding;
	width = width - (padding * 2);
	height = height - (padding * 2);

	return left, bottom, width, height;
end

function TRP3_ColorPickerShadePickerMixin:GetCanvasPadding()
	return 3;
end

--
-- Common Slider Mixin
--

TRP3_ColorPickerSliderMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerSliderMixin:OnValueChanged(value)  -- luacheck: no unused
	-- No-op; override in a derived mixin to update the data provider.
end

function TRP3_ColorPickerSliderMixin:OnDataProviderChanged()
	self:UpdateDeferred();
end

function TRP3_ColorPickerSliderMixin:OnSelectedValuesChanged()
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

TRP3_ColorPickerHueSliderMixin = {};

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
	local _, s, v, a = self:GetSelectedValues();
	local h = value / 360;

	self:SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerHueSliderMixin:UpdateDisplayedColor()
	local h = self:GetSelectedValues();

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

TRP3_ColorPickerOpacitySliderMixin = {};


function TRP3_ColorPickerOpacitySliderMixin:OnValueChanged(value)
	local h, s, v = self:GetSelectedValues();
	local a = value / 100;

	self:SetSelectedValues(h, s, v, a);
end

function TRP3_ColorPickerOpacitySliderMixin:UpdateDisplayedColor()
	local h, s, v, a = self:GetSelectedValues();

	self:SetValue(math.floor(a * 100));

	local startColor = TRP3.CreateColorFromHSVA(h, s, v, 0);
	local endColor = TRP3.CreateColorFromHSVA(h, s, v, 1);
	self.Gradient:SetGradient("HORIZONTAL", startColor, endColor);
end

--
-- Preview Swatch
--

TRP3_ColorPickerPreviewSwatchMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerPreviewSwatchMixin:OnEnter()
	-- TODO: Tooltip stuff can be handled through better means.
	TRP3_MainTooltip:SetOwner(self, "ANCHOR_RIGHT");
	TRP3_MainTooltip:SetText(self:GetSelectedColor():GenerateColorString());
	TRP3_MainTooltip:Show();
end

function TRP3_ColorPickerPreviewSwatchMixin:OnLeave()
	TRP3_MainTooltip:Hide();
end

function TRP3_ColorPickerPreviewSwatchMixin:OnDataProviderChanged()
	self:UpdateDisplayedColor();
end

function TRP3_ColorPickerPreviewSwatchMixin:OnSelectedValuesChanged()
	self:UpdateDisplayedColor();
end

function TRP3_ColorPickerPreviewSwatchMixin:UpdateDisplayedColor()
	self.Color:SetColorTexture(self:GetSelectedColor():GetRGBA());
end

--
-- Color Picker Frame
--

TRP3_ColorPickerMixin = CreateFromMixins(TRP3_ColorPickerWidgetBaseMixin);

function TRP3_ColorPickerMixin:OnLoad()
	self:SetDataProvider(TRP3.CreateColorPickerDataProvider(self.initialColor));
end

function TRP3_ColorPickerMixin:GetDataProvider()
	return self.dataProvider;
end

function TRP3_ColorPickerMixin:GetHueSlider()
	return self.HueSlider;
end

function TRP3_ColorPickerMixin:GetOpacitySlider()
	return self.OpacitySlider;
end

function TRP3_ColorPickerMixin:GetShadePicker()
	return self.ShadePicker;
end

function TRP3_ColorPickerMixin:GetPreviewSwatch()
	return self.PreviewSwatch;
end

function TRP3_ColorPickerMixin:OnDataProviderChanged(dataProvider)
	self:GetHueSlider():SetDataProvider(dataProvider);
	self:GetOpacitySlider():SetDataProvider(dataProvider);
	self:GetShadePicker():SetDataProvider(dataProvider);
	self:GetPreviewSwatch():SetDataProvider(dataProvider);
end

