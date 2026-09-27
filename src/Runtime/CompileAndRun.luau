local CompileStatusEnum = require("../Enums/CompileStatusEnum")
local CompileStatusTypes = require("../Types/CompileStatusTypes")

local YIELD_TIMEOUT = 5 -- seconds before considering the require hung

local function requireWithYieldGuard(file: ModuleScript): (boolean, boolean, any)
	local co = coroutine.create(function()
		return require(file)
	end)

	local startTime = os.clock()
	local success, result

	while true do
		success, result = coroutine.resume(co)
		if coroutine.status(co) == "dead" then
			return success, false, result
		end

		if os.clock() - startTime > YIELD_TIMEOUT then
			-- The coroutine is left suspended forever (a controlled leak);
			-- we'd rather abandon it than block the compiler indefinitely.
			return false, true, "Module did not resolve the require in time (possible infinite yield or circular dependency)"
		end
		task.wait()
	end
end

return function(file: ModuleScript): (boolean, CompileStatusTypes.CompileStatus, any)
	local success, timedOut, resultOrError = requireWithYieldGuard(file)
	if timedOut then
		return false, CompileStatusEnum.DEPENDENCY_ERROR, resultOrError
	end

	if not success then
		local errorMessage = tostring(resultOrError)
		if string.find(errorMessage, "Requested module") then
			return false, CompileStatusEnum.DEPENDENCY_ERROR, errorMessage
		end
		return false, CompileStatusEnum.COMPILE_ERROR, errorMessage
	end

	return true, CompileStatusEnum.OK, resultOrError
end