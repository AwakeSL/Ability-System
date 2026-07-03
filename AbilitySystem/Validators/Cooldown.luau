local configFolder = script.Parent.Parent.Config
local Validators = require(configFolder.AbilityValidators)

local Cooldown = {}
Cooldown.type = Validators.Cooldown

local timescales = {}

function Cooldown.setTimescale(key, multiplier)
	timescales[key] = multiplier
end

function Cooldown.check(ability, context, params, state)
	if not state.readyAt then return true end
	return os.clock() >= state.readyAt
end

function Cooldown.commit(ability, context, params, state)
	local scale = timescales[params.Key] or 1
	state.readyAt = os.clock() + (params.Time / scale)
end

return Cooldown