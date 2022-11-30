-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local TRP3 = select(2, ...);

local function Identity(...)
	return ...;
end

--
-- Object cache utilities
--

function TRP3.CreateObjectCache(factoryFunc, keyFunc)
	if keyFunc == nil then
		keyFunc = Identity;
	end

	local cache = { objects = setmetatable({}, { __mode = "kv" }), Acquire = nil };

	function cache:Acquire(...)
		local key = keyFunc(...);
		local obj = self.objects[key];

		if not obj then
			obj = factoryFunc(...);
			self.objects[key] = obj;
		end

		return obj;
	end;

	return cache;
end

function TRP3.CreateObjectCacheFromMixin(mixin, keyFunc)
	local factoryFunc = GenerateClosure(CreateAndInitFromMixin, mixin);
	return TRP3.CreateObjectCache(factoryFunc, keyFunc);
end

function TRP3.CreateObjectCacheFromMetaMixin(mixin, keyFunc)
	local factoryFunc = GenerateClosure(TRP3.CreateAndInitFromMetaMixin, mixin);
	return TRP3.CreateObjectCache(factoryFunc, keyFunc);
end


--
-- Meta-mixin utilities
--
-- Meta-mixins are class-like mixins (such as ColorMixin) that are attached
-- to tables via setmetatable, with support for metamethods included.
--
-- As these are applied as metatables an object can only inherit methods from
-- a single meta-mixin at a time, and meta-mixins are not compatible with
-- frames.
--

function TRP3.CreateMetatableFromMixin(mixin)
	local meta = { __index = {} };
	local index = meta.__index;

	for k, v in pairs(mixin) do
		if type(k) == "string" and string.find(k, "^__") then
			meta[k] = v;
		else
			index[k] = v;
		end
	end

	if meta.__index ~= index and next(index) ~= nil then
		meta.__index = setmetatable(index, { __index = meta.__index });
	end

	return meta;
end

TRP3.MetaMixinCache = TRP3.CreateObjectCache(TRP3.CreateMetatableFromMixin);

function TRP3.ApplyMetaMixin(object, mixin)
	return setmetatable(object, TRP3.MetaMixinCache:Acquire(mixin));
end

function TRP3.CreateFromMetaMixin(mixin)
	return TRP3.ApplyMetaMixin({}, mixin);
end

function TRP3.CreateAndInitFromMetaMixin(mixin, ...)
	local object = TRP3.CreateFromMetaMixin(mixin);
	object:Init(...);
	return object;
end
