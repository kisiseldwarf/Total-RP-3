---@type Ellyb
local Ellyb = Ellyb(...);

if Ellyb.Maths then
	return
end

local Maths = {}
Ellyb.Maths = Maths

--- Round the given number to the given decimal
---@param value number
---@param decimals number Optional, defaults to 0 decimals
---@return number
---@overload fun(value:number):number
function Maths.round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult) / mult;
end
