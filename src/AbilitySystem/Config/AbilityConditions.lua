--!strict

local Conditions = {
	Grounded = "Grounded",
	Airborne = "Airborne",
	
	-- add any extras here
}

export type AbilityCondition = typeof(Conditions[string])

Conditions.checks = {
	[Conditions.Grounded] = function(ctx)
		return ctx.character.isGrounded
	end,
	[Conditions.Airborne] = function(ctx)
		return not ctx.character.isGrounded
	end,
	
	-- then create the function here
}

return Conditions