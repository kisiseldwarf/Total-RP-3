local Ellyb = Ellyb(...)
local loc = TRP3_API.loc
local RED, ORANGE = Ellyb.ColorManager.RED, Ellyb.ColorManager.ORANGE

local HealthTooltipIndicator = AddOn_TotalRP3.UnitTooltipIndicator()

function HealthTooltipIndicator:GetConfigurationKey()
	return "SHOW_HEALTH_PERCENTAGE_IN_TOOLTIP"
end

function HealthTooltipIndicator:GetConfigurationLocaleText()
	return loc.CO_TOOLTIP_HEALTH_INDICATOR
end

function HealthTooltipIndicator:GetPriority()
	return 50
end

function HealthTooltipIndicator:GetValidTargetTypes()
	return {
		AddOn_TotalRP3.Enums.TARGET_TYPES.CHARACTER,
		AddOn_TotalRP3.Enums.TARGET_TYPES.PET
	}
end

---@param tooltip GameTooltip
---@param target UnitID
function HealthTooltipIndicator:_DisplayInsideTooltipForTarget(tooltip, target)
	if not tooltip then
		tooltip = TRP3_CharacterTooltip
	end
	if not target then
		target = "mouseover"
	end
	local targetHealth, targetMaxHealth = UnitHealth(target), UnitHealthMax(target)
	if targetHealth and targetMaxHealth then
		local healthValue
		if targetHealth == 0 then
			RED(DEAD) -- Redemption
		else
			local healthPercentage = targetHealth / targetMaxHealth
			local healthColor
			if healthPercentage > 0.5 then
				healthColor = Ellyb.Color.CreateFromRGBA((1 - healthPercentage) * 2, 1, 0)
			else
				healthColor = Ellyb.Color.CreateFromRGBA(1, healthPercentage * 2, 0)
			end
			healthValue = healthColor(healthPercentage .. "%")
		end
		tooltip:AddLine(ORANGE(loc.REG_TT_HEALTH) .. " " .. healthValue, 1, 1, 1, TRP3_API.ui.tooltip.getSubLineFontSize())
	end
end