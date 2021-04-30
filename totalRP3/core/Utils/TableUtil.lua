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

TRP3_TableUtil = {};

function TRP3_TableUtil.CopyTable(settings, shallow)
	local copy = {};

	for k, v in pairs(settings) do
		if type(v) == "table" and not shallow then
			copy[k] = TRP3_TableUtil.CopyTable(v);
		else
			copy[k] = v;
		end
	end

	return copy;
end

function TRP3_TableUtil.CopyValuesAsKeys(tbl)
	local output = {};

	for _, v in ipairs(tbl) do
		output[v] = v;
	end

	return output;
end

function TRP3_TableUtil.MergeTable(destination, source)
	for k, v in pairs(source) do
		destination[k] = v;
	end
end
