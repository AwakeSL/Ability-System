# AbilitySystem

An entity-based ability system built around **hooks**, **tags**, and pluggable **validators**. Abilities are defined declaratively; the manager handles triggering, priority ordering, blocking, and canceling based on tags.

Created by AwakeSL.

Two core pieces:

1. **`Ability`** — defines an ability and its hooks.
2. **`AbilityManager`** — owns an entity's abilities, and resolves triggers against them.

---

## Core Concepts

- **Ability**: a named unit of behavior (e.g. `Dash`) made up of one or more hooks.
- **Hook**: a specific input-bound piece of an ability's behavior (e.g. `start`, `finish`, `special`). Each hook has its own binds, priority, tags, and lifecycle callbacks.
- **Tag**: a label on a hook (e.g. `Dash`, `Movement`, `Stun`) used to block or cancel other hooks while this one is active.
- **Bind**: the input event a hook listens for (`Pressed`, `Released`, `Special`, ...).
- **Priority**: when multiple hooks across abilities match the same bind, higher priority resolves first.
- **Validator**: a reusable, stateful gate (e.g. `Cooldown`, `Conditions`) that a hook must pass before it executes.

---

## Defining an Ability

```lua
local rs = game:GetService("ReplicatedStorage")
local Ability = require(rs.AbilitySystem.Ability)
local Tags, Binds, Priorities, Validators = Ability.Tags, Ability.Binds, Ability.Priorities, Ability.Validators

return function()
    local dash = Ability.new({
        name = "Dash",
        description = "Dash forward",
        tags = { [Tags.Movement] = true, [Tags.Dash] = true },
        blockedBy = { [Tags.Movement] = true }, -- can't dash while another Movement hook is active
        cancels   = { [Tags.Dash] = true },      -- re-pressing cancels an existing dash
    })

    dash:addHook("start", {
        binds    = { [Binds.Pressed] = true },
        priority = Priorities.Early,
        validators = {
            [Validators.Cooldown] = { Time = 5, Key = "Dash" },
        },
        execute = function(ability, context)
            task.spawn(function()
                task.wait(1)
                context:finish()
            end)
        end,
        cancel = function(ability, context)
            -- stop the dash early
        end,
    })

    dash:addHook("finish", {
        binds = { [Binds.Released] = true },
        execute = function(ability, context)
            context:finish()
        end,
    })

    return dash
end
```

- `blockedBy` / `cancels` / `validators` set at the ability level are defaults; a hook can override any of them individually.
- `tags` set on a hook are merged with the ability's tags. Set a tag to `false` in a hook's config to remove it from that hook specifically.

---

## Using the Manager

```lua
local AbilityManager = require(rs.AbilitySystem.AbilityManager)
local Dash = require(sss.Abilities.Dash)

local manager = AbilityManager.new(entity)
manager:give(Dash())

manager:trigger("Dash", manager.Binds.Pressed, {})
```

`trigger` looks up every hook on the ability bound to that input, sorts them by priority (high to low), and runs each through `triggerHook`, which:

1. Checks the hook isn't blocked by any currently active hook's tags.
2. Runs the hook's validators (all must pass).
3. Runs the hook's `check`, if any.
4. Cancels any active hooks whose tags match this hook's `cancels`.
5. Registers the hook as active and calls `execute`.

---

## Hook Config Reference

| Field | Type | Description |
| --- | --- | --- |
| `binds` | `{[bind]: true}` | Inputs that trigger this hook. |
| `priority` | `number` | Resolution order among matching hooks (default `0`). |
| `tags` | `{[tag]: bool}` | Tags this hook carries while active. Merged with ability tags. |
| `blockedBy` | `{[tag]: true}` | Hook won't fire while any active hook carries one of these tags. |
| `cancels` | `{[tag]: true}` | Active hooks carrying one of these tags are canceled when this hook fires. |
| `validators` | `{[validatorType]: params}` | Gates that must pass before `check`/`execute`. |
| `check(ability, context)` | `function` | Optional final gate; returning falsy blocks the hook. |
| `execute(ability, context)` | `function` | Runs when the hook fires. Call `context:finish()` when done. |
| `cancel(ability, context)` | `function` | Runs if another hook cancels this one while active. |

`context` also exposes `context.manager` and `context.entity`.

---

## Built-in Validators

| Validator | Params | Behavior |
| --- | --- | --- |
| `Cooldown` | `Time`, `Key` | Blocks until `Time` seconds have passed since last use. `Cooldown.setTimescale(key, multiplier)` lets you speed up/slow down a specific cooldown key at runtime. |
| `Conditions` | `{[conditionName]: bool}` | Blocks unless each named condition function returns the expected value. Register new conditions with `Conditions.register(name, fn)`; `fn` receives the entity. |

### Adding a custom validator

Drop a `ModuleScript` in the `Validators` folder that returns a table with:

- `type` — a string matching an entry in `AbilityValidators`.
- `check(ability, context, params, state)` — return `false` to block.
- `commit(ability, context, params, state)` *(optional)* — runs after all validators on the hook pass.

It's picked up automatically on startup — no manual registration needed.

---

## `Ability` API

- **`Ability.new(config): Ability`** — `config` may include `name`, `description`, `tags`, `blockedBy`, `cancels`, `validators`.
- **`Ability:addHook(name: string, config: table)`** — adds a hook; see the field reference above.

## `AbilityManager` API

- **`AbilityManager.new(entity): AbilityManager`**
- **`AbilityManager.registerValidator(validatorType: string, impl: table)`** — manually register a validator module (auto-registration handles anything placed in the `Validators` folder).
- **`:give(ability: Ability)`** — adds an ability instance to the entity. Errors if one with the same name already exists.
- **`:take(abilityName: string)`** — removes an ability.
- **`:get(abilityName: string): Ability?`**
- **`:trigger(abilityName: string, bind: string, context: table?)`** — resolves and fires all matching hooks for that bind, in priority order.
- **`:triggerHook(abilityName: string, hookName: string, context: table)`** — fires a single hook directly, bypassing bind matching.

---

## Config Modules

- **`AbilityTags`** — string enum of tag names.
- **`AbilityBinds`** — string enum of input bind names.
- **`AbilityPriorities`** — suggested priority constants (`Early`, `Normal`, `Late`, `Last`); not enforced, just convenient reference points.
- **`AbilityValidators`** — string enum of validator type names.