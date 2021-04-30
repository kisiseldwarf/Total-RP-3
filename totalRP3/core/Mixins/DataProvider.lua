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

	------------------------------------------------------------------------

	This file is largely a verbatim copy of the DataProvider infrastructure
	implemented in retail patch 9.1 and TBC patch 2.5.1 for compatibility
	with Classic. When Classic receives this support, these will be removed.
]]--

TRP3_DataProviderMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_DataProviderMixin:GenerateCallbackEvents(
	{
		"OnSizeChanged",
		"OnInsert",
		"OnRemove",
		"OnSort",
	}
);

function TRP3_DataProviderMixin:Init(tbl)
	TRP3_CallbackRegistryMixin.OnLoad(self);

	self.collection = {};

	if tbl then
		self:InsertTable(tbl);
	end
end

function TRP3_DataProviderMixin:Enumerate()
	return ipairs(self.collection);
end

function TRP3_DataProviderMixin:GetSize()
	return #self.collection;
end

local function InsertInternal(dataProvider, elementData, hasSortComparator)
	table.insert(dataProvider.collection, elementData);
	local insertIndex = #dataProvider.collection;
	dataProvider:TriggerEvent(TRP3_DataProviderMixin.Event.OnInsert, insertIndex, elementData, hasSortComparator);
end

function TRP3_DataProviderMixin:Insert(...)
	local hasSortComparator = self:HasSortComparator();
	local count = select("#", ...);
	for index = 1, count do
		InsertInternal(self, select(index, ...), hasSortComparator);
	end

	if count > 0 then
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSizeChanged, hasSortComparator);
	end

	self:Sort();
end

function TRP3_DataProviderMixin:InsertTable(tbl)
	self:InsertTableRange(tbl, 1, #tbl);
end

function TRP3_DataProviderMixin:InsertTableRange(tbl, indexBegin, indexEnd)
	if indexEnd - indexBegin < 0 then
		return;
	end

	local hasSortComparator = self:HasSortComparator();
	for index = indexBegin, indexEnd do
		InsertInternal(self, tbl[index], hasSortComparator);
	end

	self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSizeChanged, hasSortComparator);

	self:Sort();
end

function TRP3_DataProviderMixin:Remove(...)
	local removedIndex = nil;
	local originalSize = self:GetSize();
	local count = select("#", ...);
	while count >= 1 do
		local elementData = select(count, ...);
		local index = tIndexOf(self.collection, elementData);
		if index then
			table.remove(self.collection, index);
			self:TriggerEvent(TRP3_DataProviderMixin.Event.OnRemove, elementData, index);
			removedIndex = index;
		end
		count = count - 1;
	end

	if self:GetSize() ~= originalSize then
		local sorting = false;
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSizeChanged, sorting);
	end

	return removedIndex;
end

function TRP3_DataProviderMixin:RemoveIndex(index)
	self:RemoveIndexRange(index, index);
end

function TRP3_DataProviderMixin:RemoveIndexRange(indexBegin, indexEnd)
	local originalSize = self:GetSize();

	indexBegin = math.max(1, indexBegin);
	indexEnd = math.min(self:GetSize(), indexEnd);
	while indexEnd >= indexBegin do
		local elementData = self.collection[indexEnd];
		tremove(self.collection, indexEnd);
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnRemove, elementData, indexEnd);
		indexEnd = indexEnd - 1;
	end

	if self:GetSize() ~= originalSize then
		local sorting = false;
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSizeChanged, sorting);
	end
end


function TRP3_DataProviderMixin:SetSortComparator(sortComparator, skipSort)
	self.sortComparator = sortComparator;
	if not skipSort then
		self:Sort();
	end
end

function TRP3_DataProviderMixin:HasSortComparator()
	return self.sortComparator ~= nil;
end

function TRP3_DataProviderMixin:Sort()
	if self.sortComparator then
		table.sort(self.collection, self.sortComparator);
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSort);
	end
end

function TRP3_DataProviderMixin:Find(index)
	return self.collection[index];
end

function TRP3_DataProviderMixin:FindIndex(elementData)
	for index, elementDataIter in self:Enumerate() do
		if elementDataIter == elementData then
			return index, elementDataIter;
		end
	end
	return nil, nil;
end

function TRP3_DataProviderMixin:FindByPredicate(predicate)
	for index, elementData in self:Enumerate() do
		if predicate(elementData) then
			return index, elementData;
		end
	end
	return nil, nil;
end

function TRP3_DataProviderMixin:FindElementDataByPredicate(predicate)
	local _, elementData = self:FindByPredicate(predicate);
	return elementData;
end

function TRP3_DataProviderMixin:FindIndexByPredicate(predicate)
	local index = self:FindByPredicate(predicate);
	return index;
end

function TRP3_DataProviderMixin:ContainsByPredicate(predicate)
	local index = self:FindByPredicate(predicate);
	return index ~= nil;
end

function TRP3_DataProviderMixin:ForEach(func)
	for _, elementData in self:Enumerate() do
		func(elementData);
	end
end

function TRP3_DataProviderMixin:Flush()
	local oldCollection = self.collection;
	self.collection = {};
	for index, elementData in ipairs(oldCollection) do
		self:TriggerEvent(TRP3_DataProviderMixin.Event.OnRemove, elementData, index);
	end
	local sorting = false;
	self:TriggerEvent(TRP3_DataProviderMixin.Event.OnSizeChanged, sorting);
end

local function RegisterListener(dataProvider, event, handler, listener)
	if handler then
		dataProvider:RegisterCallback(event, handler, listener);
	end
end

function TRP3_DataProviderMixin:AddListener(listener)
	RegisterListener(self, TRP3_DataProviderMixin.Event.OnSizeChanged, listener.OnDataProviderSizeChanged, listener);
	RegisterListener(self, TRP3_DataProviderMixin.Event.OnInsert, listener.OnDataProviderInsert, listener);
	RegisterListener(self, TRP3_DataProviderMixin.Event.OnRemove, listener.OnDataProviderRemove, listener);
	RegisterListener(self, TRP3_DataProviderMixin.Event.OnSort, listener.OnDataProviderSort, listener);
end

function TRP3_DataProviderMixin:RemoveListener(listener)
	self:UnregisterCallback(TRP3_DataProviderMixin.Event.OnSizeChanged, listener);
	self:UnregisterCallback(TRP3_DataProviderMixin.Event.OnInsert, listener);
	self:UnregisterCallback(TRP3_DataProviderMixin.Event.OnRemove, listener);
	self:UnregisterCallback(TRP3_DataProviderMixin.Event.OnSort, listener);
end

-- TRP3_DataProviderIndexRangeMixin is only intended for use with ScrollBox in scenarios where
-- extremely large index ranges would need to be stored (i.e. 20,000 equipment set icons).
TRP3_DataProviderIndexRangeMixin = CreateFromMixins(TRP3_CallbackRegistryMixin);

TRP3_DataProviderIndexRangeMixin:GenerateCallbackEvents(
	{
		"OnSizeChanged",
	}
);

function TRP3_DataProviderIndexRangeMixin:Init(size)
	TRP3_CallbackRegistryMixin.OnLoad(self);

	self:SetSize(size);
end

function TRP3_DataProviderIndexRangeMixin:GetSize()
	return self.size;
end

function TRP3_DataProviderIndexRangeMixin:SetSize(size)
	self.size = math.max(0, size);
end

function TRP3_DataProviderIndexRangeMixin:Find(index)
	return index <= self:GetSize() and index or nil;
end

function TRP3_DataProviderIndexRangeMixin:FindByPredicate(predicate)
	for index = 1, self:GetSize() do
		if predicate(index) then
			return index;
		end
	end
	return nil;
end

function TRP3_DataProviderIndexRangeMixin:ContainsByPredicate(predicate)
	return self:FindByPredicate(predicate) ~= nil;
end

function TRP3_DataProviderIndexRangeMixin:ForEach(func)
	for index = 1, self:GetSize() do
		func(index);
	end
end

function TRP3_DataProviderIndexRangeMixin:Flush()
	self:SetSize(0);
	local pendingSort = false;
	self:TriggerEvent(TRP3_DataProviderIndexRangeMixin.Event.OnSizeChanged, pendingSort);
end

local function IndexRangeRegisterListener(dataProvider, event, handler, listener)
	if handler then
		dataProvider:RegisterCallback(event, handler, listener);
	end
end

function TRP3_DataProviderIndexRangeMixin:AddListener(listener)
	IndexRangeRegisterListener(self, TRP3_DataProviderIndexRangeMixin.Event.OnSizeChanged, listener.OnDataProviderSizeChanged, listener);
end

function TRP3_DataProviderIndexRangeMixin:RemoveListener(listener)
	self:UnregisterCallback(TRP3_DataProviderIndexRangeMixin.Event.OnSizeChanged, listener);
end

TRP3_DataProvider = {};

function TRP3_DataProvider.Create(tbl)
	local dataProvider = CreateFromMixins(TRP3_DataProviderMixin);
	dataProvider:Init(tbl);
	return dataProvider;

end

local function CreateDefaultIndicesTable(indexCount)
	local tbl = {};
	for index = 1, indexCount do
		table.insert(tbl, {index = index});
	end
	return tbl;
end

function TRP3_DataProvider.CreateByIndexCount(indexCount)
	return TRP3_DataProvider.Create(CreateDefaultIndicesTable(indexCount));
end

function TRP3_DataProvider.CreateWithAssignedKey(tbl, key)
	local dataProvider = TRP3_DataProvider.Create();

	for _, value in ipairs(tbl) do
		dataProvider:Insert({[key]=value});
	end

	return dataProvider;
end

function TRP3_DataProvider.CreateIndexRange(size)
	return TRP3_MixinUtil.CreateAndInitFromMixin(TRP3_DataProviderIndexRangeMixin, size or 0);
end
