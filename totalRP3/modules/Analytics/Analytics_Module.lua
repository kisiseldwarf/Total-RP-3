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

local TRP3_API = select(2, ...);
local L = TRP3_API.loc;

TRP3_AnalyticsModule = {};

-- TODO: Settings
-- TODO: Implementing analytics in useful places
-- TODO: Analytics are registered on their first value change, this has issues.
-- TODO: Analytics consent, or do we allow the platform to handle that for us?

function TRP3_AnalyticsModule:OnInitialize()
end

function TRP3_AnalyticsModule:OnEnable()
	self.todo = CreateAndInitFromMixin(TRP3_UntitledPlatform1Mixin);
end

TRP3_API.module.registerModule(
	{
		id = "trp3_analytics",
		name = L.ANALYTICS_MODULE_NAME,
		description = L.ANALYTICS_MODULE_DESCRIPTION,
		version = 1,
		minVersion = 98,
		onInit = function() return TRP3_AnalyticsModule:OnInitialize(); end,
		onStart = function() return TRP3_AnalyticsModule:OnEnable(); end,
	}
);
