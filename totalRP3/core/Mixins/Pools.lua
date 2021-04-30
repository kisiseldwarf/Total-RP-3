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

--
-- The below is a copy of Blizzards' FramePoolCollectionMixin for use by
-- the backported ScrollBox system. This will be removed at a later date.
--

TRP3_Pools = {};

function TRP3_Pools.CreateFramePoolCollection()
	local poolCollection = CreateFromMixins(TRP3_FramePoolCollectionMixin);
	poolCollection:OnLoad();
	return poolCollection;
end

TRP3_FramePoolCollectionMixin = {};

function TRP3_FramePoolCollectionMixin:OnLoad()
	self.pools = {};
end

function TRP3_FramePoolCollectionMixin:GetNumActive()
	local numTotalActive = 0;
	for _, pool in pairs(self.pools) do
		numTotalActive = numTotalActive + pool:GetNumActive();
	end
	return numTotalActive;
end

function TRP3_FramePoolCollectionMixin:GetOrCreatePool(frameType, parent, template, resetterFunc, forbidden)
	local pool = self:GetPool(template);
	if not pool then
		pool = self:CreatePool(frameType, parent, template, resetterFunc, forbidden);
	end
	return pool;
end

function TRP3_FramePoolCollectionMixin:CreatePool(frameType, parent, template, resetterFunc, forbidden)
	assert(self:GetPool(template) == nil);
	local pool = CreateFramePool(frameType, parent, template, resetterFunc, forbidden);
	self.pools[template] = pool;
	return pool;
end

function TRP3_FramePoolCollectionMixin:CreatePoolIfNeeded(frameType, parent, template, resetterFunc, forbidden)
	if not self:GetPool(template) then
		self:CreatePool(frameType, parent, template, resetterFunc, forbidden);
	end
end

function TRP3_FramePoolCollectionMixin:GetPool(template)
	return self.pools[template];
end

function TRP3_FramePoolCollectionMixin:Acquire(template)
	local pool = self:GetPool(template);
	assert(pool);
	return pool:Acquire();
end

function TRP3_FramePoolCollectionMixin:Release(object)
	for _, pool in pairs(self.pools) do
		if pool:Release(object) then
			-- Found it! Just return
			return;
		end
	end

	-- Huh, we didn't find that object
	assert(false);
end

function TRP3_FramePoolCollectionMixin:ReleaseAllByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		pool:ReleaseAll();
	end
end

function TRP3_FramePoolCollectionMixin:ReleaseAll()
	for _, pool in pairs(self.pools) do
		pool:ReleaseAll();
	end
end

function TRP3_FramePoolCollectionMixin:EnumerateActiveByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		return pool:EnumerateActive();
	end

	return nop;
end

function TRP3_FramePoolCollectionMixin:EnumerateActive()
	local currentPoolKey, currentPool = next(self.pools, nil);
	local currentObject = nil;
	return function()
		if currentPool then
			currentObject = currentPool:GetNextActive(currentObject);
			while not currentObject do
				currentPoolKey, currentPool = next(self.pools, currentPoolKey);
				if currentPool then
					currentObject = currentPool:GetNextActive();
				else
					break;
				end
			end
		end

		return currentObject;
	end, nil;
end

function TRP3_FramePoolCollectionMixin:EnumerateInactiveByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		return pool:EnumerateInactive();
	end

	return nop;
end

function TRP3_FramePoolCollectionMixin:EnumerateInactive()
	local currentPoolKey, currentPool = next(self.pools, nil);
	local currentObject = nil;
	return function()
		if currentPool then
			currentObject = currentPool:GetNextInactive(currentObject);
			while not currentObject do
				currentPoolKey, currentPool = next(self.pools, currentPoolKey);
				if currentPool then
					currentObject = currentPool:GetNextInactive();
				else
					break;
				end
			end
		end

		return currentObject;
	end, nil;
end
