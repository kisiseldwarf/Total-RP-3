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

TRP3_AnalyticsEventContext = {};

function TRP3_AnalyticsEventContext:Init(data)
	if data ~= nil and type(data) ~= "table" then
		error("EventContext.Init: 'data' must be a table or nil");
	end

	self.data = data or {};
end

function TRP3_AnalyticsEventContext:Attach(data)
	if type(data) ~= "table" then
		error("EventContext.Attach: 'data' must be a table");
	end

	Mixin(self.data, data);
end

function TRP3_AnalyticsEventContext:Clone()
	local SHALLOW_COPY = true;

	local data = CopyTable(self.data, SHALLOW_COPY);
	local copy = CreateAndInitFromMixin(TRP3_AnalyticsEventContext, data);

	return copy;
end

function TRP3_AnalyticsEventContext:Extend(data)
	if type(data) ~= "table" then
		error("EventContext.Extend: 'data' must be a table");
	end

	local copy = self:Clone();
	copy:Attach(data);
	return copy;
end

function TRP3_AnalyticsEventContext:Record(event, message, data)
	if type(event) ~= "number" then
		error("EventContext.Record: 'event' must be a number");
	elseif type(message) ~= "string" then
		error("EventContext.Record: 'message' must be a string");
	elseif data ~= nil and type(data) ~= "table" then
		error("EventContext.Record: 'data' must be a table");
	end

	-- If this context has data attached _and_ this call was given additional
	-- data, a shallow merge into a new table is required. Otherwise we should
	-- pass through whichever data table isn't empty/missing.

	if data and next(self.data) then
		data = Mixin({}, self.data, data);
	elseif not data then
		data = self.data;
	end

	TRP3_AnalyticsEventRegistry:TriggerEvent("OnEventRecorded", event, message, data);
end

function TRP3_AnalyticsEventContext:RecordMessage(message, data)
	return self:Record(TRP3_AnalyticsEventType.Message, message, data);
end

function TRP3_AnalyticsEventContext:RecordError(message, data)
	return self:Record(TRP3_AnalyticsEventType.Error, message, data);
end
