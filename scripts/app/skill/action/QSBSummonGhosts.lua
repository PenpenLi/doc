--[[
    Class name QSBSummonGhosts
    Create by julian 
--]]

local QSBAction = import(".QSBAction")
local QSBSummonGhosts = class("QSBSummonGhosts", QSBAction)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QBaseEffectView = import("...views.QBaseEffectView")

function QSBSummonGhosts:_execute(dt)
    local actor = self._attacker
    local ghost_id = self:getOptions().actor_id
    assert(type(ghost_id) == "number", "QSBSummonGhosts: wrong actor_id!")
    local life_span = self:getOptions().life_span
    life_span = life_span and life_span or 5.0

    local targets = actor:getMultipleTargetWithSkill(self._skill)

    local number = nil
    local skill = self._skill
    if skill and skill:isNeedComboPoints() then
        number = actor:getComboPointsConsumed()
    else
        number = #targets
    end

    if #targets == 0 then
        self:finished()
        return
    end

    local candidates = {}
    local index = 1
    for i = 1, math.ceil(number / #targets) do
        for j = 1, math.min(number, #targets) do
            if index <= number then
                local select_index = math.random(j, #targets)
                local tmp = targets[select_index]
                targets[select_index] = targets[j]
                targets[j] = tmp

                table.insert(candidates, tmp) 
                index = index + 1
            end
        end
    end

    local attack = actor:getAttack()
    local crit = actor:getCrit()
    local function getAttack(actor_self)
        return attack
    end
    local function getCrit(actor_self)
        return crit
    end

    for _, target in ipairs(candidates) do
        local ghost = app.battle:summonGhosts(ghost_id, actor, life_span, target:getPosition())
        local target_view = app.scene:getActorViewFromModel(ghost)
        local view = app.scene:getActorViewFromModel(ghost)

        local pos = clone(ghost:getPosition())
        local distance = (target:getRect().size.width + ghost:getRect().size.width) / 2
        pos.x = pos.x + (target_view:getDirection() == target_view.DIRECTION_LEFT and distance or -distance)
        app.grid:moveActorTo(ghost, pos, true, true, true)

        -- 使用render target最后进行染色
        -- local maskRect = CCRect(0, 0, 0, 0)
        -- view:setScissorEnabled(true)
        -- view:setScissorRects(
        --     maskRect,
        --     CCRect(0, 0, 0, 0),
        --     CCRect(0, 0, 0, 0),
        --     maskRect
        -- )
        -- view:getSkeletonActor():getRenderTextureSprite():setColor(self._options.tint_color or ccc3(147, 112, 219 * 0.9))
        -- makeNodeFromNormalToGrayLuminance(view:getSkeletonActor():getRenderTextureSprite())

        -- 直接对每一个骨骼进行染色
        view:getSkeletonActor():setColor(self._options.tint_color or ccc3(147, 112, 219 * 0.9))
        makeNodeFromNormalToGrayLuminance(view:getSkeletonActor())

        local frontEffect, backEffect = QBaseEffectView.createEffectByID("haunt_3")
        local effect = frontEffect or backEffect
        effect:setPosition(ghost:getPosition().x, ghost:getPosition().y)
        app.scene:addEffectViews(effect, {isFrontEffect = true})
        effect:playAnimation(EFFECT_ANIMATION, false)
        local arr = CCArray:create()
        effect:afterAnimationComplete(function()
            app.scene:removeEffectViews(effect)
        end)

        -- 鬼的攻击力
        ghost.getAttack = getAttack
        -- 鬼的暴击
        ghost.getCrit = getCrit
        -- 普攻的伤害
        local attack1 = ghost:getTalentSkill()
        if attack1 then
            attack1:set("damage_type", skill:get("damage_type"))
            attack1:set("damage_p", skill:get("damage_p"))
            attack1:set("physical_damage", skill:get("physical_damage"))
            attack1:set("magic_damage", skill:get("magic_damage"))
        end
        -- 普攻2的伤害
        local attack2 = ghost:getTalentSkill2()
        if attack2 then
            attack2:set("damage_type", skill:get("damage_type"))
            attack2:set("damage_p", skill:get("damage_p"))
            attack2:set("physical_damage", skill:get("physical_damage"))
            attack2:set("magic_damage", skill:get("magic_damage"))
        end
    end

    self:finished()
end

function QSBSummonGhosts:_onCancel()

end

return QSBSummonGhosts