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

local function GenerateStructuredMessage(message, ...)
	if select("#", ...) == 0 then
		return message;
	end

	local data = Mixin({}, ...);
	local chunks = { message };

	for key, value in pairs(data) do
		table.insert(chunks, string.format("%s=%s", tostring(key), tostring(value)));
	end

	return table.concat(chunks, " ");
end

TRP3_UntitledPlatform1Mixin = {};

function TRP3_UntitledPlatform1Mixin:Init()
	TRP3_AnalyticsEventRegistry:RegisterCallback("OnEventRecorded", self.OnEventRecorded, self);
	TRP3_AnalyticsEventRegistry:RegisterCallback("OnMetricChanged", self.OnMetricChanged, self);
end

function TRP3_UntitledPlatform1Mixin:OnEventRecorded(event, message, data)
	if event == TRP3_AnalyticsEventType.Error then
		TRP3_API.utils.log.log(string.format("Record error event: %s", GenerateStructuredMessage(message, data)));
	elseif event == TRP3_AnalyticsEventType.Message then
		TRP3_API.utils.log.log(string.format("Record message event: %s", GenerateStructuredMessage(message, data)));
	end
end

function TRP3_UntitledPlatform1Mixin:OnMetricChanged(type, name, ...)
	if type == TRP3_AnalyticsMetricType.Counter then
		local value = ...;
		TRP3_API.utils.log.log(string.format("Record counter change: %s = %s", tostringall(name, value)));
	elseif type == TRP3_AnalyticsMetricType.Boolean then
		local state = ...;
		TRP3_API.utils.log.log(string.format("Record boolean state: %s = %s", tostringall(name, state)));
	end
end
