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

TRP3_FunctionUtil = {};

local closureGeneration = {
	function(f) return function(...) return f(...); end end,
	function(f, a) return function(...) return f(a, ...); end end,
	function(f, a, b) return function(...) return f(a, b, ...); end end,
	function(f, a, b, c) return function(...) return f(a, b, c, ...); end end,
	function(f, a, b, c, d) return function(...) return f(a, b, c, d, ...); end end,
};

function TRP3_FunctionUtil.GenerateClosure(f, ...)
    local count = select("#", ...);
    local generator = closureGeneration[count + 1];

    if generator then
		return generator(f, ...);
    end

    error("Closure generation does not support more than "..(#closureGeneration - 1).." parameters");
 end
