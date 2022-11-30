-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local function GetUnderlyingMethod(object, methodName)
	return getmetatable(object).__index[methodName];
end

local function CallUnderlyingMethod(object, methodName, ...)
	return GetUnderlyingMethod(object, methodName)(object, ...);
end

TRP3_GradientTextureMixin = {};

function TRP3_GradientTextureMixin:SetGradient(orientation, startColor, endColor)
	if not GetUnderlyingMethod(self, "SetGradientAlpha") then
		CallUnderlyingMethod(self, "SetGradient", orientation, startColor, endColor);
	else
		-- TODO: Remove this when Classic Era gets updated. Eventually.
		local fr, fg, fb, fa = startColor:GetRGBA();
		local tr, tg, tb, ta = endColor:GetRGBA();
		CallUnderlyingMethod(self, "SetGradientAlpha", orientation, fr, fg, fb, fa, tr, tg, tb, ta);
	end
end
