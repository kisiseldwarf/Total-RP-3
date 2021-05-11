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

TRP3_AnalyticsMetricBaseMixin = {};

function TRP3_AnalyticsMetricBaseMixin:Init(type, name)
	self.type = type;
	self.name = name;
end

function TRP3_AnalyticsMetricBaseMixin:GetName()
	return self.name;
end

function TRP3_AnalyticsMetricBaseMixin:GetValue()
	-- Implement in your derived mixin to return something sensible.
end

function TRP3_AnalyticsMetricBaseMixin:NotifyMetricChanged()
	TRP3_AnalyticsEventRegistry:TriggerEvent("OnMetricChanged", self.type, self.name, self:GetValue());
end

TRP3_AnalyticsCounterMixin = CreateFromMixins(TRP3_AnalyticsMetricBaseMixin);

function TRP3_AnalyticsCounterMixin:Init(name)
	TRP3_AnalyticsMetricBaseMixin.Init(self, TRP3_AnalyticsMetricType.Counter, name);

	self.value = 0;
end

function TRP3_AnalyticsCounterMixin:GetValue()
	return self.value;
end

function TRP3_AnalyticsCounterMixin:Increment()
	self:AdjustBy(1);
end

function TRP3_AnalyticsCounterMixin:Decrement()
	self:AdjustBy(-1);
end

function TRP3_AnalyticsCounterMixin:AdjustBy(delta)
	if delta == 0 then
		return;
	end

	self.value = self.value + delta;
	self:NotifyMetricChanged();
end

TRP3_AnalyticsBooleanMixin = CreateFromMixins(TRP3_AnalyticsMetricBaseMixin);

function TRP3_AnalyticsBooleanMixin:Init(name)
	TRP3_AnalyticsMetricBaseMixin.Init(self, TRP3_AnalyticsMetricType.Boolean, name);

	self.state = false;
end

function TRP3_AnalyticsBooleanMixin:GetValue()
	return self.state;
end

function TRP3_AnalyticsBooleanMixin:Clear()
	self:Set(false);
end

function TRP3_AnalyticsBooleanMixin:Set(state)
	state = state == true or state == nil;

	if self.state == state then
		return;
	end

	self.state = state;
	self:NotifyMetricChanged();
end

function TRP3_AnalyticsBooleanMixin:Toggle()
	self:Set(not self.state);
end
