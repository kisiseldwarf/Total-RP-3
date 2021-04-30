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

TRP3_RegionUtil = {};

function TRP3_RegionUtil.AdjustPointsOffset(region, offsetX, offsetY)
	if region.AdjustPointsOffset then
		region:AdjustPointsOffset(offsetX, offsetY);
	else
		for i = 1, region:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = region:GetPoint(i);

			x = x + offsetX;
			y = y + offsetY;

			region:SetPoint(point, relativeTo, relativePoint, x, y);
		end
	end
end
