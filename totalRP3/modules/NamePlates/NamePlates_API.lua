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

local TRP3 = AddOn_TotalRP3;

local callbackRegistry = TRP3_ObjectUtil.CreateAndInitFromMixin(TRP3_CallbackRegistryMixin);
callbackRegistry:GenerateCallbackEvents({
	"OnCallbackRegistryUsed",
	"OnUnitDisplayInfoUpdated",
});

local unitDisplayInfo = {};

TRP3.NamePlates = {};
TRP3.NamePlates.callbackRegistry = callbackRegistry;
TRP3.NamePlates.unitDisplayInfo = unitDisplayInfo;

function TRP3.NamePlates.RegisterCallback(event, callback, owner, ...)
	return callbackRegistry:RegisterCallback(event, callback, owner, ...);
end

function TRP3.NamePlates.UnregisterCallback(event, owner)
	return callbackRegistry:UnregisterCallback(event, owner);
end

function TRP3.NamePlates.UnregisterAllCallbacks(owner)
	return callbackRegistry:UnregisterAllCallbacks(owner);
end

function TRP3.NamePlates.GetUnitDisplayInfo(unitToken)
	return unitDisplayInfo[unitToken];
end

function TRP3.NamePlates.SetUnitDisplayInfo(unitToken, displayInfo)
	unitDisplayInfo[unitToken] = displayInfo;
	callbackRegistry:TriggerEvent("OnUnitDisplayInfoUpdated", unitToken, displayInfo);
end
