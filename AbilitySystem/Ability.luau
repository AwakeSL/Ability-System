local Ability = {}
Ability.__index = Ability

local configFolder = script.Parent.Config
local Tags = require(configFolder.AbilityTags)
local Binds = require(configFolder.AbilityBinds)
local Priorities = require(configFolder.AbilityPriorities)
local Validators = require(configFolder.AbilityValidators)
Ability.Tags = Tags
Ability.Binds = Binds
Ability.Priorities = Priorities
Ability.Validators = Validators

function Ability.new(config)
	local self = setmetatable({}, Ability)
	self.name        = config.name
	self.description = config.description
	self.tags        = config.tags or {}
	self.blockedBy   = config.blockedBy or {}
	self.cancels     = config.cancels or {}
	self.validators  = config.validators or {}
	self.hooks       = {}
	return self
end

function Ability:addHook(name, config)
	local mergedTags = {}
	for tag, val in pairs(self.tags) do
		mergedTags[tag] = val
	end
	for tag, val in pairs(config.tags or {}) do
		if val == false then
			mergedTags[tag] = nil
		else
			mergedTags[tag] = val
		end
	end
	self.hooks[name] = {
		name       = name,
		tags       = mergedTags,
		binds      = config.binds or {},
		priority   = config.priority or 0,
		blockedBy  = config.blockedBy or self.blockedBy,
		cancels    = config.cancels or self.cancels,
		validators = config.validators or self.validators,
		check      = config.check,
		execute    = config.execute,
		cancel     = config.cancel,
	}
end

return Ability