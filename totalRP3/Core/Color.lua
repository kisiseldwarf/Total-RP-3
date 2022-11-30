-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local TRP3 = select(2, ...);

local CalculateLightnessContrast;
local CalculateLuminance;
local ConvertHSLToHSV;
local ConvertHSLToRGB;
local ConvertHSVToHSL;
local ConvertHSVToRGB;
local ConvertHWBToRGB;
local ConvertRGBToHSL;
local ConvertRGBToHSV;
local ConvertRGBToHWB;

local function CreateColorObject(r, g, b, a)
	return TRP3.ApplyMetaMixin({ r = r, g = g, b = b, a = a }, TRP3.ColorMixin);
end

local function GenerateColorKey(r, g, b, a)
	return string.format("#%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255);
end

local function AcquireColor(r, g, b, a)
	assert(type(r) == "number" and r >= 0 and r <= 1, "invalid color component: r");
	assert(type(g) == "number" and g >= 0 and g <= 1, "invalid color component: g");
	assert(type(b) == "number" and b >= 0 and b <= 1, "invalid color component: b");
	assert(type(a) == "number" and a >= 0 and a <= 1, "invalid color component: a");

	return TRP3.ColorCache:Acquire(r, g, b, a);
end

TRP3.ColorMixin = {};
TRP3.ColorCache = TRP3.CreateObjectCache(CreateColorObject, GenerateColorKey);

--
-- Color Constructors and Utilities
--

function TRP3.CreateColor(r, g, b, a)
	return AcquireColor(r, g, b, a or 1);
end

function TRP3.CreateColorFromBytes(r, g, b, a)
	return AcquireColor(r / 255, g / 255, b / 255, (a or 255) / 255);
end

function TRP3.CreateColorFromTable(t)
	return AcquireColor(t.r, t.g, t.b, t.a or 1);
end

function TRP3.CreateColorFromHSLA(h, s, l, a)
	local r, g, b = ConvertHSLToRGB(h, s, l);
	return AcquireColor(r, g, b, a or 1);
end

function TRP3.CreateColorFromHSVA(h, s, v, a)
	local r, g, b = ConvertHSVToRGB(h, s, v);
	return AcquireColor(r, g, b, a or 1);
end

function TRP3.CreateColorFromHWBA(h, w, b, a)
	local r, g, b = ConvertHWBToRGB(h, w, b);  -- luacheck: no redefined
	return AcquireColor(r, g, b, a or 1);
end

function TRP3.GetChatTypeColor(chatType)
	local chatTypeInfo = ChatTypeInfo[chatType];
	return chatTypeInfo and TRP3.CreateColorFromTable(chatTypeInfo) or nil;
end

function TRP3.GetClassBaseColor(classToken)
	local classColor = RAID_CLASS_COLORS[classToken];
	return classColor and TRP3.CreateColorFromTable(classColor) or nil;
end

function TRP3.GetClassDisplayColor(classToken)
	local classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classToken] or RAID_CLASS_COLORS[classToken];
	return classColor and TRP3.CreateColorFromTable(classColor) or nil;
end

function TRP3.GetColorFromName(name)
	local key = string.upper(name);
	return TRP3.NamedColors[key];
end

function TRP3.GetColorFromHexString(str)
	str = string.gsub(str, "^#", "");

	local i, j = string.find(str, "^%x%x%x%x?%x?%x?%x?%x?");
	local len = i and (j - i) + 1 or 0;

	if len ~= 3 and len ~= 4 and len ~= 6 and len ~= 8 then
		return nil;  -- Invalid hex color string.
	end

	local a, r, g, b;

	if len == 3 then
		r, g, b = string.match(str, "^(%x)(%x)(%x)");
	elseif len == 4 then
		a, r, g, b = string.match(str, "^(%x)(%x)(%x)(%x)");
	elseif len == 6 then
		r, g, b = string.match(str, "^(%x%x)(%x%x)(%x%x)");
	else
		a, r, g, b = string.match(str, "^(%x%x)(%x%x)(%x%x)(%x%x)");
	end

	a = tonumber(a or "ff", 16);
	r = tonumber(r, 16);
	g = tonumber(g, 16);
	b = tonumber(b, 16);

	if len <= 4 then
		-- Shorthand notation; convert from 4-bit space to 8-bit.
		r = (r * 16) + r;
		g = (g * 16) + g;
		b = (b * 16) + b;
	end

	if len == 4 then
		a = (a * 16) + a;
	end

	return TRP3.CreateColorFromBytes(r, g, b, a);
end

function TRP3.GetColorFromHexMarkup(str)
	local a, r, g, b = string.match(str, "^|c(%x%x)(%x%x)(%x%x)(%x%x)");

	if not a then
		return nil;
	end

	a = tonumber(a, 16);
	r = tonumber(r, 16);
	g = tonumber(g, 16);
	b = tonumber(b, 16);

	return TRP3.CreateColorFromBytes(r, g, b, a);
end

function TRP3.GetColorFromString(str)
	return TRP3.GetColorFromName(str)
		or TRP3.GetColorFromHexString(str)
		or TRP3.GetColorFromHexMarkup(str);
end

function TRP3.GenerateBlendedColor(colorA, colorB)
	local r, g, b, a = colorA:GetRGBA();

	if a < 1 then
		local R, G, B = colorB:GetRGB();
		local A = 1 - a;

		r = Saturate((R * A) + (r * a));
		g = Saturate((G * A) + (g * a));
		b = Saturate((B * A) + (b * a));
		a = 1;
	end

	return TRP3.CreateColor(r, g, b, a);
end

function TRP3.GenerateInterpolatedColor(colorA, colorB, ratio)
	local h1, s1, l1, a1 = colorA:GetHSLA();
	local h2, s2, l2, a2 = colorB:GetHSLA();

	-- If we'd traverse > 180° of hue then go the other way instead.
	if (h2 - h1) > 0.5 then
		h2 = 1 - h2;
	end

	local ht = Lerp(h1, h2, ratio);
	local st = Lerp(s1, s2, ratio);
	local lt = Lerp(l1, l2, ratio);
	local at = Lerp(a1, a2, ratio);

	return TRP3.CreateColorFromHSLA(ht, st, lt, at);
end

function TRP3.GenerateContrastingColor(backgroundColor)
	local Ys = CalculateLuminance(backgroundColor:GetRGB());

	if Ys >= 0.38 then
		return TRP3.CreateColor(0, 0, 0);
	else
		return TRP3.CreateColor(1, 1, 1);
	end
end

function TRP3.GenerateReadableColor(foregroundColor, backgroundColor, targetContrast)
	local BgR, BgG, BgB = backgroundColor:GetRGB();
	local FgR, FgG, FgB = TRP3.GenerateBlendedColor(foregroundColor, backgroundColor):GetRGB();
	local FgH, FgS, FgL = foregroundColor:GetHSL();

	local BgYs = CalculateLuminance(BgR, BgG, BgB);
	local FgYs = CalculateLuminance(FgR, FgG, FgB);
	local FgLc = CalculateLightnessContrast(FgYs, BgYs);

	-- TODO: This should be user-configurable and not defaulted.
	targetContrast = targetContrast or 60;

	-- Perform incremental stepping of the foreground color lightness until we
	-- find a shade of the same hue that meets the required contrast level.

	if math.abs(FgLc) < targetContrast then
		local step = 0.5;
		local sign = (BgYs >= 0.38 and -1 or 1);
		local Lend = Saturate(sign);
		local Lcur = FgL;

		repeat
			local StL = Saturate(Lcur + (step * sign));
			local StYs = CalculateLuminance(ConvertHSLToRGB(FgH, FgS, StL));
			local StLc = CalculateLightnessContrast(StYs, BgYs);

			if math.abs(StLc) >= targetContrast then
				FgL = StL;
				step = step / 2;
			else
				Lcur = StL;
			end
		until step < 0.005 or Lcur == Lend;

		FgR, FgG, FgB = ConvertHSLToRGB(FgH, FgS, FgL);
		FgYs = CalculateLuminance(FgR, FgG, FgB);
		FgLc = CalculateLightnessContrast(FgYs, BgYs);
	end

	-- If the required contrast still hasn't been met use an appropriate
	-- contrasting color (pure white or black) based on background luminance.

	if math.abs(FgLc) < targetContrast then
		FgL = (BgYs >= 0.38 and 0 or 1);
	end

	return TRP3.CreateColorFromHSLA(FgH, FgS, FgL);
end

--
-- ColorMixin Methods
--

function TRP3.ColorMixin:IsEqualTo(other)
	return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a;
end

function TRP3.ColorMixin:GetRGB()
	return self.r, self.g, self.b;
end

function TRP3.ColorMixin:GetRGBA()
	return self.r, self.g, self.b, self.a;
end

function TRP3.ColorMixin:GetRGBAAsBytes()
	return self.r * 255, self.g * 255, self.b * 255, self.a * 255;
end

function TRP3.ColorMixin:GetRGBAAsTable()
	return { r = self.r, g = self.g, b = self.b, a = self.a };
end

function TRP3.ColorMixin:GetRGBAsBytes()
	return self.r * 255, self.g * 255, self.b * 255;
end

function TRP3.ColorMixin:GetRGBAsTable()
	return { r = self.r, g = self.g, b = self.b };
end

function TRP3.ColorMixin:GetHSL()
	return ConvertRGBToHSL(self:GetRGB());
end

function TRP3.ColorMixin:GetHSLA()
	local h, s, l = self:GetHSL();
	return h, s, l, self.a;
end

function TRP3.ColorMixin:GetHSV()
	return ConvertRGBToHSV(self:GetRGB());
end

function TRP3.ColorMixin:GetHSVA()
	local h, s, v = self:GetHSV();
	return h, s, v, self.a;
end

function TRP3.ColorMixin:GetHWB()
	return ConvertRGBToHWB(self:GetRGB());
end

function TRP3.ColorMixin:GetHWBA()
	local h, w, b = self:GetHWB();
	return h, w, b, self.a;
end

function TRP3.ColorMixin:GenerateHexColor()
	local r, g, b, a = self:GetRGBAAsBytes();
	return string.format("%02x%02x%02x%02x", a, r, g, b);
end

function TRP3.ColorMixin:GenerateHexColorOpaque()
	local r, g, b = self:GetRGBAsBytes();
	return string.format("%02x%02x%02x", r, g, b);
end

function TRP3.ColorMixin:GenerateHexColorMarkup()
	local r, g, b = self:GetRGBAsBytes();
	return string.format("|cff%02x%02x%02x", r, g, b);
end

local function IsShort(c)
	return (math.floor(c * 255) % 17 == 0);
end

function TRP3.ColorMixin:GenerateColorString()
	local r, g, b, a = self:GetRGBA();
	local mult = 255;
	local format;

	if IsShort(r) and IsShort(g) and IsShort(b) and IsShort(a) then
		mult = 15;

		if a ~= 1 then
			format = "#%4$x%1$x%2$x%3$x";
		else
			format = "#%x%x%x";
		end
	elseif a ~= 1 then
		format = "#%4$02x%1$02x%2$02x%3$02x";
	else
		format = "#%02x%02x%02x";
	end

	return string.format(format, r * mult, g * mult, b * mult, a * mult);
end

function TRP3.ColorMixin:WrapTextInColorCode(text)
	local r, g, b = self:GetRGBAsBytes();
	return string.format("|cff%02x%02x%02x%s|r", r, g, b, tostring(text));
end

function TRP3.ColorMixin:__call(text)
	return self:WrapTextInColorCode(text);
end

function TRP3.ColorMixin:__eq(other)
	return self:IsEqualTo(other);
end

function TRP3.ColorMixin:__tostring()
	return string.format("Color <%s>", self:GenerateColorString());
end

--
-- Color Conversion Utilities
--

function ConvertHSLToHSV(h, s, l)
	local H, S, V;

	l = l * 2;
	s = s * (l <= 1 and l or (2 - l));

	H = h;
	S = (2 * s) / (l + s);
	V = (l + s) / 2;

	return H, S, V;
end

local function ConvertHSLComponent(n, h, s, l)
	local k = (n + h * 12) % 12;
	local a = s * math.min(l, 1 - l);

	return l - a * math.max(-1, math.min(k - 3, 9 - k, 1));
end

function ConvertHSLToRGB(h, s, l)
	local r = ConvertHSLComponent(0, h, s, l);
	local g = ConvertHSLComponent(8, h, s, l);
	local b = ConvertHSLComponent(4, h, s, l);

	return r, g, b;
end

function ConvertHSVToHSL(h, s, v)
	local H, S, L;

	H = h;
	S = s * v;
	L = (2 - s) * v;

	S = S / (L <= 1 and L or (2 - L));
	L = L / 2;

	return H, S, L;
end

function ConvertHSVToRGB(h, s, v)
	return ConvertHSLToRGB(ConvertHSVToHSL(h, s, v));
end

function ConvertHWBToRGB(h, w, b)
	if w + b >= 1 then
		local g = w / (w + b);
		return g, g, g;
	else
		local R, G, B = ConvertHSLToRGB(h, 1, 0.5);
		R = (R * (1 - w - b)) + w;
		G = (G * (1 - w - b)) + w;
		B = (B * (1 - w - b)) + w;
		return R, G, B;
	end
end

function ConvertRGBToHSL(r, g, b)
	local cmax = math.max(r, g, b);
	local cmin = math.min(r, g, b);
	local c = cmax - cmin;

	local h = 0;
	local s = 0;
	local l = (cmin + cmax) / 2;

	if c ~= 0 then
		s = (l == 0 or l == 1) and 0 or ((cmax - l) / math.min(l, 1 - l));

		if cmax == r then
			h = (g - b) / c + (g < b and 6 or 0);
		elseif cmax == g then
			h = (b - r) / c + 2;
		else
			h = (r - g) / c + 4;
		end

		h = h / 6;
	end

	return h, s, l;
end

function ConvertRGBToHSV(r, g, b)
	return ConvertHSLToHSV(ConvertRGBToHSL(r, g, b));
end

function ConvertRGBToHWB(r, g, b)
	local h = ConvertRGBToHSL(r, g, b);
	local w = math.min(r, g, b);
	local b = 1 - math.max(r, g, b);  -- luacheck: no redefined

	return h, w, b;
end

--
-- Color Contrast and Lightness Utilities
--

function CalculateLuminance(r, g, b)
	-- Estimated Screen Luminance (Ys)
	-- <https://github.com/Myndex/SAPC-APCA/blob/master/documentation/regardingexponents.md>

	local EXP = 2.4;
	local RCO = 0.2126729;
	local GCO = 0.7151522;
	local BCO = 0.0721750;

	return ((r ^ EXP) * RCO) + ((g ^ EXP) * GCO) + ((b ^ EXP) * BCO);
end

function CalculateLightnessContrast(foregroundYs, backgroundYs)
	-- APCA-W3 Algorithm
	--
	-- Returns a lightness constrast (Lc) value within [-108, 106]. Positive
	-- values indicate dark text on a light background.
	--
	-- <https://github.com/Myndex/SAPC-APCA/blob/master/documentation/APCA-W3-LaTeX.md>

	local BLACK_THRESHOLD = 0.022;
	local BLACK_CLAMP = 1.414;
	local DELTA_YS_MIN = 0.0005;

	if foregroundYs <= BLACK_THRESHOLD then
		foregroundYs = foregroundYs + ((BLACK_THRESHOLD - foregroundYs) ^ BLACK_CLAMP);
	end

	if backgroundYs <= BLACK_THRESHOLD then
		backgroundYs = backgroundYs + ((BLACK_THRESHOLD - backgroundYs) ^ BLACK_CLAMP);
	end

	if math.abs(backgroundYs - foregroundYs) < DELTA_YS_MIN then
		return 0;
	end

	local BG_BOW = 0.56;
	local BG_WOB = 0.65;
	local FG_BOW = 0.57;
	local FG_WOB = 0.62;
	local LOW_CLIP = 0.1;
	local LOW_OFFSET = 0.027;
	local SCALE = 1.14;

	local Lc;

	if backgroundYs > foregroundYs then
		Lc = ((backgroundYs ^ BG_BOW) - (foregroundYs ^ FG_BOW)) * SCALE;
		Lc = (Lc < LOW_CLIP) and 0 or (Lc - LOW_OFFSET);
	else
		Lc = ((backgroundYs ^ BG_WOB) - (foregroundYs ^ FG_WOB)) * SCALE;
		Lc = (Lc > LOW_CLIP) and 0 or (Lc + LOW_OFFSET);
	end

	return Lc * 100;
end

