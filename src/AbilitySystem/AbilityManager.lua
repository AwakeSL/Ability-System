local AbilityManager = {}
AbilityManager.__index = AbilityManager

local configFolder = script.Parent.Config
local Tags = require(configFolder.AbilityTags)
local Binds = require(configFolder.AbilityBinds)
local Conditions = require(configFolder.AbilityConditions)

AbilityManager.Tags = Tags
AbilityManager.Binds = Binds
AbilityManager.Conditions = Conditions

function AbilityManager.new(entity, resourceManager)
	local self = setmetatable({}, AbilityManager)
	self.entity          = entity
	self.resourceManager = resourceManager
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
	if not self:_checkRequires(hook) then return end
	if hook.check and not hook.check(ability, context) then return end

	-- check resource before committing
	local resource = hook.resource or ability.resource
	if self.resourceManager and resource then
		if not self.resourceManager:canAfford(resource) then return end
	end

	self:_executeCancels(hook)

	local activeId = abilityName .. "." .. hookName
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
		spendResource = function(c)
			if c._spent then return end
			c._spent = true
			if self.resourceManager and resource then
				self.resourceManager:spend(resource)
			end
		end,
		finish = function(c)
			c._finished = true
			c:spendResource()
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

function AbilityManager:triggerBind(abilityName, bind, context)
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

function AbilityManager:_checkRequires(hook)
	for condition, expected in pairs(hook.requires) do
		local check = Conditions.checks[condition]
		if not check then
			warn("AbilityManager: no check found for condition: " .. tostring(condition))
			return false
		end
		if check(self.entity) ~= expected then
			return false
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

return AbilityManager