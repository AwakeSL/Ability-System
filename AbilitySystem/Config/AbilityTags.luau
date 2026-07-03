--!strict

local Tags = {
	Movement = "Movement",
	Dash     = "Dash",
	Jump     = "Jump",
	Slide    = "Slide",
	Crouch   = "Crouch",
	Crawl    = "Crawl",
	Ragdoll  = "Ragdoll",
	Stun     = "Stun",
	-- Add anymore you would like!
}

export type AbilityTag = typeof(Tags[string])

return Tags