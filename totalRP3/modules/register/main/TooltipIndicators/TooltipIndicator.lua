local Ellyb = Ellyb(...)

--- Tooltip indicator module
--- Create a new TooltipIndicator to automatically register a new indicator to be displayed a unit tooltip
---@class UnitTooltipIndicator : Object
local UnitTooltipIndicator, _private = Ellyb.Class("TooltipIndicator")

function UnitTooltipIndicator:initialize(allowedTargetTypes)
	_private[self].allowedTargetTypes = allowedTargetTypes

	AddOn_TotalRP3.UnitTooltipIndicatorsManager:Register(self)
end

---@return string Must return the configuration key for this tooltip indicator
--[[ Override ]] function UnitTooltipIndicator:GetConfigurationKey()
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:GetConfigurationLocaleText()", self)
end

---@return string Must return the localized text to display in the configuration panel
--[[ Override ]] function UnitTooltipIndicator:GetConfigurationLocaleText()
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:GetConfigurationLocaleText()", self)
end

---@return number Must provides a priority to display the indicator in the tooltip, the bigger the number, the lower in the tooltip it will be displayed
--[[ Override ]] function UnitTooltipIndicator:GetPriority()
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:GetConfigurationLocaleText()", self)
end

---@return boolean Must indicate if the tooltip indicator should be enabled by default or not
--[[ Override ]] function UnitTooltipIndicator:IsEnabledByDefault()
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:IsEnabledByDefault()", self)
end

---@return TRP3_TARGET_TYPES[] Must indicate a list of valid target types for the indicator
--[[ Override ]] function UnitTooltipIndicator:GetValidTargetTypes()
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:GetValidTargetTypes()", self)
end

---@param targetType TRP3_TARGET_TYPES
function UnitTooltipIndicator:IsValidTargetType(targetType)
	return tContains(self:GetValidTargetTypes(), targetType)
end

---@param tooltip GameTooltip
---@param target UnitID
--[[ Override ]] function UnitTooltipIndicator:DisplayInsideTooltipForTarget(tooltip, target, targetType)
	Ellyb.Assertions.notImplemented("UnitTooltipIndicator:DisplayInsideTooltipForTarget(tooltip, target)", self)
end

AddOn_TotalRP3.UnitTooltipIndicator = UnitTooltipIndicator

-- TODO: Move me to a separate file
local UnitTooltipIndicatorsManager = {}
AddOn_TotalRP3.UnitTooltipIndicatorsManager = UnitTooltipIndicatorsManager

---@type UnitTooltipIndicator[]
local registeredIndicators = {}

---@param tooltipIndicator UnitTooltipIndicator
function UnitTooltipIndicatorsManager:Register(tooltipIndicator)

	-- Add to the list of indicators
	table.insert(registeredIndicators, tooltipIndicator:GetPriority(), tooltipIndicator)

	-- Register configuration
	TRP3_API.Events.registerCallback(TRP3_API.Events.WORKFLOW_ON_LOADED, function()
		TRP3_API.configuration.registerConfigKey(tooltipIndicator:GetConfigurationKey(), tooltipIndicator:IsEnabledByDefault())

		-- Configuration UI
		table.insert(TRP3_API.ui.tooltip.CONFIG.elements,{
			inherit = "TRP3_ConfigCheck",
			title = tooltipIndicator:GetConfigurationLocaleText(),
			configKey = tooltipIndicator:GetConfigurationKey(),
		})
	end)
end

---@param targetType TRP3_TARGET_TYPES
---@return UnitTooltipIndicator[] A list of indicators valid for the given target type
function UnitTooltipIndicatorsManager:GetIndicatorsForTargetType(targetType)
	local indicators = {}
	for _, indicator in ipairs(registeredIndicators) do
		if indicator:IsValidTargetType(targetType) then
			table.insert(indicators, indicator)
		end
	end
	return indicators
end

--region Move to Ellyb
function Ellyb.Assertions.notImplemented(methodName, instance)
	error(("%s method not implemented by %s"):format(methodName, tostring(instance)), 3)
end
--endregion