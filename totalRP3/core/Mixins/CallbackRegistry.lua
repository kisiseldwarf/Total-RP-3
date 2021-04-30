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

local function GenerateCallbackClosure(f, ...)
	local count = select("#", ...);
	local generator = closureGeneration[count + 1];

	if generator then
		return generator(f, ...);
	end

	error("Closure generation does not support more than "..(#closureGeneration - 1).." parameters");
end

TRP3_CallbackRegistryMixin = {};

function TRP3_CallbackRegistryMixin:OnLoad()
	local RegisterName = "RegisterCallback_Inner";
	local UnregisterName = "UnregisterCallback_Inner";
	local UnregisterAllName = "UnregisterAllCallbacks_Inner";

	local OnUsed = function(registry, target, event)  -- luacheck: no unused
		self:OnCallbackUsed(event);
	end;

	local OnUnused = function(registry, target, event)  -- luacheck: no unused
		self:OnCallbackUnused(event);
	end;

	self.callbacks = CallbackHandler:New(self, RegisterName, UnregisterName, UnregisterAllName);
	self.callbacks.OnUsed = OnUsed;
	self.callbacks.OnUnused = OnUnused;
end

function TRP3_CallbackRegistryMixin:SetUndefinedEventsAllowed(allowed)
	self.isUndefinedEventAllowed = allowed;
end

function TRP3_CallbackRegistryMixin:RegisterCallback(event, func, owner, ...)
	if not self.isUndefinedEventAllowed and (not self.Event or not self.Event[event]) then
		error(string.format("event %s does not exist", tostring(event)));
	end

	if type(owner) ~= "string" and type(owner) ~= "table" then
		owner = tostring(owner);
	end

	self.RegisterCallback_Inner(owner, event, GenerateCallbackClosure(func, owner, ...));
end

function TRP3_CallbackRegistryMixin:UnregisterCallback(event, owner)
	if not self.isUndefinedEventAllowed and (not self.Event or not self.Event[event]) then
		error(string.format("event %s does not exist", tostring(event)));
	end

	if type(owner) ~= "string" and type(owner) ~= "table" then
		owner = tostring(owner);
	end

	self.UnregisterCallback_Inner(owner, event);
end

function TRP3_CallbackRegistryMixin:UnregisterAllCallbacks(owner)
	if type(owner) ~= "string" and type(owner) ~= "table" then
		owner = tostring(owner);
	end

    self.UnregisterAllCallbacks_Inner(owner);
end

function TRP3_CallbackRegistryMixin:TriggerEvent(event, ...)
	if not self.isUndefinedEventAllowed and (not self.Event or not self.Event[event]) then
		error(string.format("event %s does not exist", tostring(event)));
	end

	self.callbacks:Fire(event, ...);
end

function TRP3_CallbackRegistryMixin:GenerateCallbackEvents(events)
	if not self.Event then
		self.Event = {};
	else
		self.Event = Mixin({}, self.Event);
	end

	for _, event in ipairs(events) do
		if self.Event[event] then
			error(string.format("TRP3_CallbackRegistryMixin: event %s already exists.", tostring(event)));
		end

		self.Event[event] = event;
	end
end

function TRP3_CallbackRegistryMixin:OnCallbackUsed(event)  -- luacheck: no unused (prototype)
	-- Override in your mixin to receive notifications when an event is used.
end

function TRP3_CallbackRegistryMixin:OnCallbackUnused(event)  -- luacheck: no unused (prototype)
	-- Override in your mixin to receive notifications when an event is unused.
end
