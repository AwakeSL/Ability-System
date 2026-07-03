--!strict

local Priorities = {
	Early = 10,
	Normal = 25,
	Late = 50,
	Last = 100,
	-- not required, but helpful to have these constants for reference
}

export type AbilityPriority = typeof(Priorities[string])

return Priorities