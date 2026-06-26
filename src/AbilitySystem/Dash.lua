local sss = game:GetService("ServerScriptService")
local Ability = require(sss.AbilitySystem.Ability)
local Tags = Ability.Tags
local Conditions = Ability.Conditions
local Binds = Ability.Binds

return function()
	local dash = Ability.new({
		name = "Dash",
		description = "Dash forward",
		tags = {
			[Tags.Movement] = true,
			[Tags.Dash] = true
		},
		blockedBy = { [Tags.Movement] = true },
		cancels   = { [Tags.Dash] = true },
		requires  = { [Conditions.Grounded] = true }
	})

	dash:addHook("start", {
		tags      = { [Tags.Dash] = true, [Tags.Movement] = false },
		binds     = { [Binds.Pressed] = true },
		priority  = 15,
		blockedBy = { [Tags.Movement] = true },
		cancels   = { [Tags.Dash] = true },
		requires  = { [Conditions.Grounded] = true },
		execute = function(ability, context)
			print("hi")
			context:finish()
		end,
		cancel = function(ability, context)
			-- stop dash early
		end,
	})

	dash:addHook("finish", {
		binds   = { [Binds.Released] = true },
		execute = function(ability, context)
			-- stop dash
			context:finish()
		end
	})

	dash:addHook("special", {
		binds     = { [Binds.Special] = true },
		blockedBy = { [Tags.Stun] = true },
		execute   = function(ability, context)
			-- mid dash thing
			context:finish()
		end
	})

	return dash
end