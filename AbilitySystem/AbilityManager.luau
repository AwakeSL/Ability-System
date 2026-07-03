local AbilityManager = {}
AbilityManager.__index = AbilityManager

local configFolder = script.Parent.Config
local Tags = require(configFolder.AbilityTags)
local Binds = require(configFolder.AbilityBinds)
local Priorities = require(configFolder.AbilityPriorities)
local Validators = require(configFolder.AbilityValidators)

local https = game:GetService("HttpService")

AbilityManager.Tags = Tags
AbilityManager.Binds = Binds
AbilityManager.Priorities = Priorities
AbilityManager.Validators = Validators

local validators = {}

function AbilityManager.registerValidator(validatorType, impl)
	validators[validatorType] = impl
end

function AbilityManager.new(entity)
	local self = setmetatable({}, AbilityManager)
	self.entity          = entity
	self.abilities       = {}
	self.active          = {}
	return self
end

function AbilityManager:give(ability)	
	assert(ability, "AbilityManager: ability is nil in give()")
	assert(ability.name, "AbilityManager: ability must have a name")
	assert(not self.abilities[ability.name], "AbilityManager: ability already given: " .. ability.name)
	self.abilities[ability.name] = ability
end

function AbilityManager:take(abilityName)
	self.abilities[abilityName] = nil
end

function AbilityManager:get(abilityName)
	return self.abilities[abilityName]
end

function AbilityManager:triggerHook(abilityName, hookName, context)
	local ability = self.abilities[abilityName]
	if not ability then
		warn("AbilityManager: ability not found: " .. tostring(abilityName))
		return
	end

	local hook = ability.hooks[hookName]
	if not hook then
		warn("AbilityManager: hook not found: " .. tostring(hookName) .. " on " .. tostring(abilityName))
		return
	end

	if not self:_checkBlockedBy(hook) then return end
	if not self:_runValidators(hook, ability, context) then return end
	if hook.check and not hook.check(ability, context) then return end

	self:_executeCancels(hook)

	local activeId = https:GenerateGUID(false)
	self.active[activeId] = {
		hook    = hook,
		ability = ability,
	}

	local ctx = {
		entity    = self.entity,
		ability   = ability,
		hook      = hook,
		_finished = false,
		_spent    = false,
		manager   = self,

		finish = function(c)
			c._finished = true
			self.active[activeId] = nil
		end,
	}

	if hook.execute then
		local ok, err = pcall(hook.execute, ability, ctx)
		if not ok then
			self.active[activeId] = nil
			warn("AbilityManager: hook execute errored: " .. tostring(err))
		end
	end
end

function AbilityManager:trigger(abilityName, bind, context)
	context = context or {}
	context.manager = self 
	
	local ability = self.abilities[abilityName]
	if not ability then return end

	local hooks = {}
	for hookName, hook in pairs(ability.hooks) do
		if hook.binds[bind] then
			table.insert(hooks, { name = hookName, hook = hook })
		end
	end

	table.sort(hooks, function(a, b)
		return a.hook.priority > b.hook.priority
	end)

	for _, entry in ipairs(hooks) do
		self:triggerHook(abilityName, entry.name, context)
	end
end

function AbilityManager:_checkBlockedBy(hook)
	for _, entry in pairs(self.active) do
		for tag, _ in pairs(entry.hook.tags) do
			if hook.blockedBy[tag] then
				return false
			end
		end
	end
	return true
end

function AbilityManager:_executeCancels(hook)
	for activeId, entry in pairs(self.active) do
		for tag, _ in pairs(entry.hook.tags) do
			if hook.cancels[tag] then
				if entry.hook.cancel then
					entry.hook.cancel(entry.ability, {
						entity = self.entity,
					})
				end
				self.active[activeId] = nil
				break
			end
		end
	end
end

function AbilityManager:_runValidators(hook, ability, context)
	hook._validatorState = hook._validatorState or {}
	local states = hook._validatorState
	
	

	for key, params in pairs(hook.validators or {}) do
		local validatorModule = validators[key]
		if not validatorModule then
			warn("AbilityManager: no validator registered for " .. tostring(key))
			return false
		end
		states[key] = states[key] or {}
		if not validatorModule.check(ability, context, params, states[key]) then
			return false
		end
	end

	for key, params in pairs(hook.validators or {}) do
		local validatorModule = validators[key]
		if validatorModule.commit then
			validatorModule.commit(ability, context, params, states[key])
		end
	end

	return true
end

-- Auto registration for Validator ModuleScripts
for _, validatorModule in script.Parent.Validators:GetChildren() do
	if validatorModule:IsA("ModuleScript") then
		local validator = require(validatorModule)
		if validator.type then
			AbilityManager.registerValidator(validator.type, validator)
		end
	end
end

return AbilityManager