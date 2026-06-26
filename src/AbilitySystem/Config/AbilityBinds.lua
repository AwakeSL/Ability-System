--!strict

local Binds = {
	Pressed  = "Pressed",
	Released = "Released",
	Special  = "Special",
	-- Add anymore you would like!
}

export type AbilityBind = typeof(Binds[string])

return Binds