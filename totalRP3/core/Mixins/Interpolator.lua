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

	This file is largely a verbatim copy of the Interpolator infrastructure
	implemented in retail patch 9.1 and TBC patch 2.5.1 for compatibility
	with Classic. When Classic receives this support, these will be removed.
]]--

TRP3_InterpolatorMixin = {};

local function InterpolateEaseOut(v1, v2, t)
	local y = math.sin(t * (math.pi * .5));
	return (v1 * (1 - y)) + (v2 * y);
end

function TRP3_InterpolatorMixin:Interpolate(v1, v2, time, setter)
	if self.interpolateTo and TRP3_MathUtil.ApproximatelyEqual(v1, v2) then
		return;
	end
	self.interpolateTo = v2;

	if self.timer then
		self.timer:Cancel();
		self.timer = nil;
	end

	local elapsed = 0;
	local interpolate = function()
		elapsed = elapsed + GetTickTime();
		local u = Saturate(elapsed / time);
		setter(InterpolateEaseOut(v1, v2, u));
		if u >= 1 then
			self.interpolateTo = nil;
			if self.timer then
				self.timer:Cancel();
				self.timer = nil;
			end
			return false;
		end

		return true;
	end;

	local continue = interpolate();
	if continue then
		self.timer = C_Timer.NewTicker(0, interpolate);
	end
end

function TRP3_InterpolatorMixin:GetInterpolateTo()
	return self.interpolateTo;
end
