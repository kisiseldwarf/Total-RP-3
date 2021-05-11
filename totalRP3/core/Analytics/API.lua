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

local ROOT_CONTEXT = CreateAndInitFromMixin(TRP3_AnalyticsEventContext);

AddOn_TotalRP3.Analytics = {};

function AddOn_TotalRP3.Analytics.CreateCounter(name)
	if type(name) ~= "string" or #name == 0 then
		error("CreateCounter: 'name' must be a non-empty string");
	end

	return CreateAndInitFromMixin(TRP3_AnalyticsCounterMixin, name);
end

function AddOn_TotalRP3.Analytics.CreateBoolean(name)
	if type(name) ~= "string" or #name == 0 then
		error("CreateBoolean: 'name' must be a non-empty string");
	end

	return CreateAndInitFromMixin(TRP3_AnalyticsBooleanMixin, name);
end

function AddOn_TotalRP3.Analytics.CreateEventContext(data)
	return ROOT_CONTEXT:Extend(data);
end

function AddOn_TotalRP3.Analytics.RecordMessage(message, data)
	return ROOT_CONTEXT:RecordMessage(message, data);
end

function AddOn_TotalRP3.Analytics.RecordError(message, data)
	return ROOT_CONTEXT:RecordError(message, data);
end
