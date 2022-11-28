-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local TRP3 = select(2, ...);

function TRP3.Assert(value, message, level)
	if not value then
		error(message or "assertion failed!", level + 2);
	end

	return value;
end

function TRP3.SoftAssert(value, message, level)
	if not value then
		securecall(error, message or "assertion failed!", level + 4);
	end

	return value;
end

function TRP3.SoftError(message, level)
	securecall(error, message, level + 4);
end
