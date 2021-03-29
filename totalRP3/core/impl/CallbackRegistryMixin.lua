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

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0");

local closureGeneration = {
	function(f) return function(_, ...) return f(...); end end,
	function(f, a) return function(_, ...) return f(a, ...); end end,
	function(f, a, b) return function(_, ...) return f(a, b, ...); end end,
	function(f, a, b, c) return function(_, ...) return f(a, b, c, ...); end end,
	function(f, a, b, c, d) return function(_, ...) return f(a, b, c, d, ...); end end,
};

local function GenerateClosure(func, ...)
	local count = select("#", ...);
	local generator = closureGeneration[count + 1];

    if not generator then
		error(string.format("Closure generation does not support more than %d parameters", #closureGeneration - 1));
	end

	return generator(func, ...);
end

TRP3_CallbackRegistryMixin = {};

function TRP3_CallbackRegistryMixin:Init()
	self.callbackHandle = {};
	self.callbackRegistry = CallbackHandler:New(self.callbackHandle);
	self.isUndefinedEventAllowed = false;

	self.callbackRegistry.OnUsed = function() self.callbackRegistry:Fire("OnCallbackRegistryUsed"); end
	self.callbackRegistry.OnUnused = function() self.callbackRegistry:Fire("OnCallbackRegistryUnused"); end
end

function TRP3_CallbackRegistryMixin:RegisterCallback(event, func, owner, ...)
	if not self.isUndefinedEventAllowed and (not self.Event or not self.Event[event]) then
		error(string.format("CallbackRegistryMixin: event %s does not exist", tostring(event)));
	end

	self.callbackHandle.RegisterCallback(owner, event, GenerateClosure(func, owner, ...));
end

function TRP3_CallbackRegistryMixin:UnregisterCallback(event, owner)
	self.callbackHandle.UnregisterCallback(owner, event);
end

function TRP3_CallbackRegistryMixin:UnregisterAllCallbacks(owner)
	self.callbackHandle.UnregisterAllCallbacks(owner);
end

function TRP3_CallbackRegistryMixin:TriggerEvent(event, ...)
	if not self.isUndefinedEventAllowed and (not self.Event or not self.Event[event]) then
		error(string.format("CallbackRegistryMixin: event %s does not exist", tostring(event)));
	end

	self.callbackRegistry:Fire(event, ...);
end

function TRP3_CallbackRegistryMixin:GenerateCallbackEvents(events)
	self.Event = CreateFromMixins(self.Event or {});

	for _, event in ipairs(events) do
		if self.Event[event] then
			error(string.format("CallbackRegistryMixin: event %s already exists", tostring(event)));
		end

		self.Event[event] = event;
	end
end

function TRP3_CallbackRegistryMixin:SetUndefinedEventsAllowed(allowed)
	self.isUndefinedEventAllowed = allowed;
end
