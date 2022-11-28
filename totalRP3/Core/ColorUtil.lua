-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local P = CreateFrame("Frame");
P:SetPoint("RIGHT", -100, 0);
P:SetSize(300, 200);

local C = P:CreateTexture(nil, "ARTWORK", nil, 0);
C:SetAllPoints(P);
C:SetColorTexture(CreateColor(1, 0, 0, 1):GetRGBA());

local W = P:CreateTexture(nil, "ARTWORK", nil, 1);
W:SetAllPoints(P);
W:SetColorTexture(1, 1, 1, 1);
W:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 0));

local B = P:CreateTexture(nil, "ARTWORK", nil, 2);
B:SetAllPoints(P);
B:SetColorTexture(1, 1, 1, 1);
B:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0));

local Bb = CreateFrame("Button")
Bb:SetPoint("LEFT", 128, 0)
Bb:SetSize(256, 256)

local t1 = Bb:CreateTexture(nil, "ARTWORK")
t1:SetPoint("LEFT")
t1:SetSize(256, 256)

local t2 = Bb:CreateTexture(nil, "OVERLAY")
t2:SetPoint("LEFT", t1)
t2:SetSize(128, 128)

local t3 = Bb:CreateTexture(nil, "OVERLAY")
t3:SetPoint("RIGHT", t1)
t3:SetSize(128, 128)

local wh = true

Bb:SetScript("OnClick", function()
	wh = not wh
end)

local bg = TRP3_API.Colors.BLACK;
local fg = TRP3_API.Colors.WHITE;

local TRP3 = select(2, ...);

local function Redraw()
	local pc = TRP3.CreateColor(ColorPickerFrame:GetColorRGB());
	bg = wh and bg or pc;
	fg = wh and pc or fg;
	local ag = TRP3.GenerateReadableColor(fg, bg, 60);
	t1:SetColorTexture(bg:GetRGB());
	t2:SetColorTexture(fg:GetRGB());
	t3:SetColorTexture(ag:GetRGB());
	C:SetColorTexture(fg:GetRGB());
end

C_Timer.After(0, function()
	ColorPickerFrame.func = Redraw;
	ShowUIPanel(ColorPickerFrame)
	Redraw();
end)
