-- Validators/Conditions.lua
local configFolder = script.Parent.Parent.Config
local Validators = require(configFolder.AbilityValidators)

local Conditions = {}
Conditions.type = Validators.Conditions

Conditions.checks = {
	Grounded = function(entity)
		return entity:GetAttribute("Grounded") == true
	end,
	Stunned = function(entity)
		return entity:HasTag("Stunned")
	end,
	-- add more here
}

function Conditions.register(name, checkFn)
	Conditions.checks[name] = checkFn
end

function Conditions.check(ability, context, params)
	for condition, expected in params do
		local checkFn = Conditions.checks[condition]
		if not checkFn then
			warn("Validators.Conditions: no check found for " .. tostring(condition))
			return false
		end
		if checkFn(context.entity) ~= expected then
			return false
		end
	end
	return true
end

return Conditions