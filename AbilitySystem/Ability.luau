local Ability = {}
Ability.__index = Ability

local configFolder = script.Parent.Config
local Tags = require(configFolder.AbilityTags)
local Binds = require(configFolder.AbilityBinds)
local Conditions = require(configFolder.AbilityConditions)

Ability.Tags = Tags
Ability.Binds = Binds
Ability.Conditions = Conditions

function Ability.new(config)
	local self = setmetatable({}, Ability)
	self.name        = config.name
	self.description = config.description
	self.tags        = config.tags or {}
	self.blockedBy   = config.blockedBy or {}
	self.cancels     = config.cancels or {}
	self.requires    = config.requires or {}
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
		name      = name,
		tags      = mergedTags,
		binds     = config.binds or {},
		priority  = config.priority or 0,
		blockedBy = config.blockedBy or self.blockedBy,
		cancels   = config.cancels or self.cancels,
		requires  = config.requires or self.requires,
		check     = config.check,
		execute   = config.execute,
		cancel    = config.cancel,
	}
end

return Ability