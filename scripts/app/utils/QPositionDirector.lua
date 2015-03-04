--[[
屏幕定位的grid，边长与战斗用grid不一样
每个人物停下来之后，都需要站在某个格子的中心，每个格子只能站一个人物
因此当有人物重叠的可能发生时，按照某个策略重新安排位置。

注意：所有对角色位置的修改过应该都通过这个类来实现，而不要直接调用QActor的函数，包括AI
--]]

local QPositionDirector = class("QPositionDirector", function()
    return display.newNode()
end)

local QSkeletonViewController = import("..controllers.QSkeletonViewController")
local QNotificationCenter = import("..controllers.QNotificationCenter")

local PERSPECTIVE_RATIO_VERTICAL = 0.6 -- 透视原因造成的垂直距离与水平距离的比例。比如用技能时，范围的判定在垂直方向上的比例，比如水平方向上1个单位认为是攻击范围，垂直方向上则为这里设定的值而不是1
local GRID_UNIT = {x = 24, y = 24 * PERSPECTIVE_RATIO_VERTICAL}  -- 每个网格单元的大小
local EDGE_WEIGHT = 30 -- 屏幕边缘的权重
local EDGE_WEIGHT_DECREASE = 15 -- 屏幕边缘权重往中心方向的递减量
local ACTOR_WEIGHT = 400 -- 角色权重
local ACTOR_WEIGHT_DECREASE = 80 -- 角色对周围权重每个格子的递减量
local MAX_WEIGHT = 10000000000 -- 最大权重，用于搜索的时候初始化
local WEIGHT_IMPACT_RADIUS = 3 -- actor权重最大影响范围，这个必须让处于同一边中间的伙伴包含在范围内，又不能让影响的范围过大
local BASE_OPACITY = 30 -- 调试圆点的基础透明度
local FOLLOW_TARGET_DELAY = 0.5 -- 目标位置发生变化后，自身位置进行相应调整的延迟时间，便于自身多发起1次攻击
local FRAME_BETWEEN_AUTO_ATTACK = 90

local DISTANCE_WEIGHT = 10 -- 目标距离标定点的距离每一格子的权重

local SEARCH_RADIUS_1 = 5 -- 当以某中心点为目标位置时使用的搜索半径，以多少个单元格为单位
local SEARCH_RADIUS_2 = 10 -- 当同时为2个人寻找目标位置时使用的搜索半径，以多少个单元格为单位

local REPOSITION_CHECK_RADIUS = -1 -- 检查周围一定范围内的英雄是否被影响到的，需要重新调整位置

local BEST_POSITION_BOTH_DIFF_TIME = 0.5 -- 当为两个人求解最佳位置时，限制双方到达该位置的时间差不得小于一个固定的值，否则产生长时间的等待看起来不合理

-- 检查是否需要根据目标位置调整位置的情形
local FOLLOW_TARGET_NOCHANGE = 1 -- 不需要调整自身位置
local FOLLOW_TARGET_CHANGE = 2 -- 跟踪对象发生了变化，需要调整自身位置
local FOLLOW_TARGET_BOTH = 3   -- 跟踪对象发生了变化，需要通过撮合的方式同时调整自身和攻击目标的位置

function QPositionDirector:ctor()

    self:setVisible(DISPLAY_PROPERTY_GRID)
    local nx = math.floor(BATTLE_AREA.width / GRID_UNIT.x) -- 这里必须用math.floor，否则可能导致actor到最边上格子时实际处于战场范围外，导致不能被攻击
    local ny = math.floor(BATTLE_AREA.height / GRID_UNIT.y)
    self._nx = nx
    self._ny = ny

    self:resetWeight()

    -- 创建一些显示符号，只是为了调试的时候显示使用
    self._sign = {}
    for x = 1, nx do
        local col = {}
        for y = 1, ny do
            local sign = CCSprite:create(global.ui_drag_line_circle)
            sign:setScale(0.3)
            sign:setOpacity(BASE_OPACITY)
            local pos = self:_toScreenPos({x = x, y = y})
            sign:setPosition(pos.x, pos.y)
            self:addChild(sign)
            col[y] = sign
        end
        self._sign[x] = col
    end

    -- 管理的actor
    self._actors = {}

    -- 设置该节点的事件
    self:setNodeEventEnabled(true)

    self._frameCount = 0

    self._pause = false
end

-- 重置actor的临时状态
function QPositionDirector:_resetActorStatus(actor)
    -- 清除actor的目标位置
    actor:clearTargetPosition()

    actor.gridPos = nil           -- actor的网格坐标
    actor.gridMidPos = nil        -- actor到目标位置的中转节点，由于直接到目标位置导致等待对手时间过长而设置的
    actor.gridOriginalPos = nil   -- actor由于站位拥挤调整前的位置，用来让follow该actor的对手判定是否需要调整位置
    actor.gridMoveSpeed = nil     -- actor计算目标位置时使用的速度，当速度发生变化，比如冲锋时，需要重新计算
    self:_resetActorFollowStatus(actor)
    
    -- printError("_resetActorStatus " .. actor:getDisplayName())
end

-- 重置actor的跟踪对象的临时状态
function QPositionDirector:_resetActorFollowStatus(actor)
    actor.gridTargetPos = nil     -- actor跟踪的目标的网格坐标，当这个位置和跟踪的对手的位置不一致时，可能需要调整位置
    actor.gridTargetTime = nil    -- actor跟踪的目标网格变化后的时间，当跟踪对手位置变化后，需要滞后一段时间
end

-- 初始化事件相关对象
function QPositionDirector:onEnter()
    -- 注册帧事件
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self._onFrame))
    self:scheduleUpdate_() -- 启用帧事件
    QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_START, self._onBulletTime, self)
    QNotificationCenter.sharedNotificationCenter():addEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_FINISH, self._onBulletTime, self)
end

function QPositionDirector:onExit()
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_START, self._onBulletTime, self)
    QNotificationCenter.sharedNotificationCenter():removeEventListener(QNotificationCenter.EVENT_BULLET_TIME_TURN_FINISH, self._onBulletTime, self)
end

-- 每帧循环需要处理的任务
function QPositionDirector:_onFrame(dt)
    if self._pause then
        return
    end

    dt = dt * app.battle:getTimeGear()

    if not self._resetWeightTime then
        self._resetWeightTime = 0
    end
    self._resetWeightTime = self._resetWeightTime + dt
    if self._resetWeightTime > 1 then
        self._resetWeightTime = 0
        self:resetWeight()
        for _, actor in pairs(self._actors) do
            self:_setWeight(actor)
        end
    end

    local actorsArrived = {}
    for _, actor in pairs(self._actors) do
        if actor:isDead() ~= true then
            -- 检查是否有需要移动的角色
            if self:_handleActorMove(actor, dt) then
                if self:_handleActorAttack(actor) then

                else
                    table.insert(actorsArrived, actor)
                end
            end
        end
    end

    self._frameCount = self._frameCount + 1
    -- 特殊的处理，为节约开销，每隔数帧运行一次对攻击目标切换和站位调整的计算
    if self._frameCount % 3 ~= 0 and #actorsArrived > 0 then
        return
    else

    end
    self._frameCount = 0

    local followChanges = {}
    local followChangeBoth = {}

    for _, actor in pairs(self._actors) do
        if actor:isDead() ~= true then
            -- 如果actor正在攻击中，则忽略此次攻击相关的计算
            -- 如果没有攻击目标或者攻击目标已经死亡，则忽略此次攻击相关的计算
            local target = actor:getTarget()
            if target ~= nil and not target:isDead() then
                if actor:isAttacking() ~= true then 
                    -- 检查看是否可以进行攻击
                    self:_handleActorAttack(actor)
                end

                -- 检查actor攻击对象是否在范围内并且是否需要移动
                local change = self:_checkActorTarget(actor)
                if change == FOLLOW_TARGET_CHANGE then
                    if actor._lastGridTargetChangeTime == nil then
                        actor._lastGridTargetChangeTime = 0
                    end
                    if q.time()  - actor._lastGridTargetChangeTime > 0.5 or actor.gridPos == nil then
                        table.insert(followChanges, actor)
                        actor._lastGridTargetChangeTime = q.time()
                    end
                elseif change == FOLLOW_TARGET_BOTH then
                    local actorOK = false
                    local targetOK = false
                    if actor._lastGridTargetChangeTime == nil then
                        actor._lastGridTargetChangeTime = 0
                    end
                    if q.time()  - actor._lastGridTargetChangeTime > 0.5 or actor.gridPos == nil then
                        actorOK = true
                    end

                    local target = actor:getTarget()
                    if target._lastGridTargetChangeTime == nil then
                        target._lastGridTargetChangeTime = 0
                    end
                    if q.time()  - target._lastGridTargetChangeTime > 0.5 or target.gridPos == nil then
                        targetOK = true
                    end

                    if actorOK and targetOK then
                        if table.indexof(followChangeBoth, actor:getTarget()) == false and actorOK and targetOK then -- 避免把一对对象都加入进去导致调整2次
                            table.insert(followChangeBoth, actor)
                            actor._lastGridTargetChangeTime = q.time()
                            target._lastGridTargetChangeTime = q.time()
                        end
                    end
                else
                    assert(change == FOLLOW_TARGET_NOCHANGE)
                end
            end
        end
    end

    -- 可能还有需要调整位置的actor，在_clearFollowOfEnemies中新增加的
    local newChanges = {}
    -- 将要调整的actor从屏幕站位grid中移除
    for _, actor in pairs(followChangeBoth) do
        -- 清理跟踪该actor和target的敌人的位置，因为他们可能需要重新调整站位
        table.mergeForArray(newChanges, self:_clearFollowOfEnemies(actor))
        self:_unsetWeight(actor)
        self:_resetActorStatus(actor)

        local target = actor:getTarget()
        if target ~= nil then
            table.mergeForArray(newChanges, self:_clearFollowOfEnemies(target))

            self:_unsetWeight(target)
            self:_resetActorStatus(target)
        end
    end

    for _, actor in pairs(followChanges) do
        table.mergeForArray(newChanges, self:_clearFollowOfEnemies(actor))
        self:_unsetWeight(actor)
        self:_resetActorStatus(actor)
    end

    -- 首先处理需要撮合的actor
    for _, actor in pairs(followChangeBoth) do
        local target = actor:getTarget()

        local actorPos, targetPos = self:_findBestPositionByBoth(actor, target)

        self:_setActorGridPos(actor, actorPos)
        self:_setActorGridPos(target, targetPos)

        -- 记录当前actor设定目标时使用的位置，下次如果目标位置发生了变化，则需要调整
        actor.gridTargetPos = target.gridPos
        target.gridTargetPos = actor.gridPos
        printInfo(q.time() .. " set both: " .. actor:getDisplayName() .. " " .. actor:getManualMode())
        printInfo(q.time() .. " set both: " .. target:getDisplayName() .. " " .. target:getManualMode())

        -- 避免站位的重复调整
        table.removebyvalue(followChanges, actor)
        table.removebyvalue(followChanges, target)
        table.removebyvalue(newChanges, actor)
        table.removebyvalue(newChanges, target)
    end

    -- 将新出现的合并到followChanges中
    for _, actor in pairs(newChanges) do
        if table.indexof(followChanges, actor) == false then
            table.insert(followChanges, actor)
        end
    end

    -- while #followChanges > 0 do
    --     local actors = {}
    --     -- 把所有攻击目标一致的合并起来
    --     for _, actor in pairs(followChanges) do
    --         if #actors == 0 or actors[1]:getTarget() == actor:getTarget() then
    --             table.insert(actors, actor)
    --         else
    --             break
    --         end

    --         if actors[1]:getTarget() == nil then break end
    --     end

    --     -- 删除已经处理过的actor
    --     for _, actor in pairs(actors) do
    --         table.removebyvalue(followChanges, actor)
    --     end

    --     -- 集中调整站位
    --     local target = actors[1]:getTarget()
    --     if target.gridPos ~= nil then
    --         -- target的位置有可能被前面的跟踪清除函数清理掉，因此等待下一帧循环
    --         local bestPositions = {}
    --         for k = 1, #actors do
    --             local actor = actors[k]

    --             local bestPos, midPos = self:_findBestPositionByTarget(actor, target)
    --             self:_setActorGridPos(actor, bestPos, midPos)
    --             bestPositions[k] = bestPos

    --             -- 记录当前actor设定目标时使用的位置，下次如果目标位置发生了变化，则需要调整
    --             actor.gridTargetPos = target.gridPos
    --             printInfo(q.time() .. " set one: " .. actor:getDisplayName() .. " " .. actor:getManualMode())
    --         end

    --         if #actors > 1 then
    --             -- 查看是否总体效率最高，否则需要重新调整目标路径
    --             -- 搜索最短总路径的方案
    --             local len, actors2 = self:_evalPossiblePath(actors, {}, bestPositions)
    --             -- 检查和当前方案是否一致
    --             for k = 1, #actors2 do
    --                 if actors[k] ~= actors2[k] then
    --                     -- 发现不一致的地方，使用新方案
    --                     for i = k, #actors2 do
    --                         self:_unsetWeight(actors2[i])
    --                         actors2[i].gridPos = nil
    --                     end

    --                     -- 由于每个actor体型不一样，因此需要为每个actor重新计算，这里通过重新调整计算的顺序，打到近似最优解的目的
    --                     for i = k, #actors2 do
    --                         local actor = actors2[i]
    --                         local bestPos, midPos = self:_findBestPositionByTarget(actor, target)
    --                         self:_setActorGridPos(actor, bestPos, midPos)
    --                         printInfo(q.time() .. " reset one: " .. actor:getDisplayName() .. " " .. actor:getManualMode())
    --                     end

    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- end

    for _, actor in pairs(followChanges) do
        local skill = nil
        skill = actor:getVaildActiveSkillForAutoLaunch()
        if not (actor:isWalking() and actor:getManualMode() == actor.STAY and skill and self:_isTargetInSkillRangeCurrent(skill, actor, actor:getTarget()) == true and (actor._grid_walking_attack_count == nil or actor._grid_walking_attack_count <= FRAME_BETWEEN_AUTO_ATTACK)) then 
            local bestPos, midPos = self:_findBestPositionByTarget(actor, actor:getTarget())
            self:_setActorGridPos(actor, bestPos, midPos)
        else
            local _, gridPos self:_toGridPos(actor:getPosition().x, actor:getPosition().y)
            self:_setActorGridPos(actor, gridPos, nil)
        end

        table.removebyvalue(actorsArrived, actor)
    end

    for _, actor in pairs(actorsArrived) do
        actor:stopMoving()
        if actor.gridMidPos == nil and actor.gridPos then
            -- 已到达最终点，检查是否需要reposition
           self:_handleRepositionCheck(actor, actor.gridPos)
        else
            -- 已到达中间点，等待下一次启动到最终点
            actor.gridMidPos = nil
        end
    end
end

-- 评估各种可能的连接方式生成的总的路径长度，寻找最短总路径，NP完全问题，由于总数不超过4，因此用简单递归查找解决
function QPositionDirector:_evalPossiblePath(actors, candidates, bestPositions)
    -- actors已经全部重新排布完成，计算当前路径
    local length = 0
    if #actors == 0 then
        for k = 1, #candidates do
            length = length + q.distOf2Points(candidates[k]:getPosition(), self:_toScreenPos(bestPositions[k]))
        end
        return length, candidates
    end

    -- 如果还有actors没有分配完，继续尝试分配
    local minLength = MAX_WEIGHT
    local minCandidates = nil

    for i = 1, #actors do
        local localCandidates = self:_copyArray(candidates)
        local localActors = self:_copyArray(actors)
        table.insert(localCandidates, actors[i])
        table.remove(localActors, i)
        local len, rc = self:_evalPossiblePath(localActors, localCandidates, bestPositions)
        if len < minLength then
            minLength = len
            minCandidates = rc
        end
    end

    return minLength, minCandidates
end

function QPositionDirector:_copyArray(objects)
    local r = {}
    for _, obj in pairs(objects) do
        if obj ~= nil then
            table.insert(r, obj)
        end
    end
    return r
end

-- 处理对象移动
function QPositionDirector:_handleActorMove(actor, dt)
    if actor.gridPos == nil then
        return
    end

    local currentSkill = actor:getCurrentSkill()
    if currentSkill ~= nil then
        -- 如果当前正在攻击，而且当前使用的技能需要暂时停止移动，则暂时不要移动
        if (currentSkill:isStopMoving() == true and actor:getManualMode() == actor.AUTO) or (currentSkill:isStopMoving() == true and currentSkill:isAllowMoving() == false) then
            return
        end
        if actor:getManualMode() == actor.ATTACK and currentSkill:isStopMoving() == true and currentSkill:isAllowMoving() == true and actor:getTarget() ~= nil and actor:getCurrentSkillTarget() == actor:getTarget() then
            return
        end
    end

    -- 计算目标位置
    local targetPos
    if actor.gridMidPos ~= nil then
        targetPos = self:_toScreenPos(actor.gridMidPos)
    else
        targetPos = self:_toScreenPos(actor.gridPos)
    end

    -- 检查是否需要移动到目标位置
    if q.is2PointsClose(actor:getPosition(), targetPos) then
        if actor:isWalking() then
            return true
        end
    else
        -- 检查当前速度跟预期的速度相比是否发生了变化
        if actor:getMoveSpeed() == actor.gridMoveSpeed or (actor:getManualMode() == actor.STAY) or true then
            -- 速度与原先计算位置时使用的速度一致，则继续移动
            -- 如果目标位置跟之前的设定保持一致，且正在向目标位置移动，则继续移动
            if actor:isWalking() and actor:getTargetPosition() ~= nil and q.is2PointsClose(actor:getTargetPosition(), targetPos) then
                self:_moveActorByFrame(actor, targetPos, dt)
            elseif actor:canMove() then
                -- -- 开始move，但是由于其他约束条件，比如buff，目标可能没法启动move
                -- -- 如果无法移动，则前面的判断isWalking会返回false，此刻actor将保持当前位置
                -- if actor:getManualMode() ~= actor.AUTO then
                --     -- 如果当前是人工指定目标位置模式，则立即移动。为什么不是判断是否等于actor.MOVE？因为冲锋等技能实施时候，这里的模式是actor.ATTACK
                --     actor:startMoving(targetPos)
                -- else
                --     -- 如果当前跟踪的对象还没移动到位，如果现在开始移动，会比目标早先到达预定位置，则暂时不移动
                --     local target = actor:getTarget()
                --     if target ~= nil and target.gridPos ~= nil and
                --         -- 目标的目标位置，如果actor有中间节点，则按中间节点来判定
                --         q.distOf2Points(target:getPosition(), self:_toScreenPos(target.gridMidPos or target.gridPos)) / target:getMoveSpeed() > q.distOf2Points(actor:getPosition(), targetPos) / actor:getMoveSpeed() then
                      
                --         -- 如果对方是中了不能动的buff，则还是要立即移动才行，不能等着对方不动
                --         local target_can_move = target:CanControlMove()
                --         if target_can_move == false then
                --             if actor:isWalking() then
                --                 -- 虽然应当移动，但是先应当停下来，让_checkActorTarget重新检查一下站位
                --                 actor:stopMoving()
                --                 self:_clearFollowOfEnemies(actor)
                --                 self:_unsetWeight(actor)
                --                 self:_resetActorStatus(actor)
                --             else
                --                 -- 等重新被赋予站位之后再继续移动
                --                 actor:startMoving(targetPos)
                --             end
                --         else  
                --             -- nzhang：现在的midPos已经取成拦截位置，应该不需要再停下来等了
                --             actor:startMoving(targetPos)

                --             -- 什么都不做，但是如果此刻actor正在走动，则应该停下来稍微等一会
                --         --    if actor:isWalking() then
                --         --        actor:stopMoving()
                --         --    end
                --         end
                --     else
                --         actor:startMoving(targetPos)
                --     end
                -- end

                actor:startMoving(targetPos)
                self:_moveActorByFrame(actor, targetPos, dt)
            end
        else
            -- 当前速度与原先计算位置时的速度不一致，重新计算目标位置
            self:_clearFollowOfEnemies(actor)
            self:_unsetWeight(actor)
            self:_resetActorStatus(actor)
        end
    end
end

-- 每帧移动一个对象一段距离
function QPositionDirector:_moveActorByFrame(actor, targetPos, deltaTime)
    if actor:isInTimeStop() then
        return
    end

    -- 获取当前位置和目标位置
    local pos = actor:getPosition()

    -- 计算需要行走的距离
    local dx = targetPos.x - pos.x
    local dy = targetPos.y - pos.y

    -- 计算actor走完全程需要消耗的时间
    local scale = QSkeletonViewController.sharedSkeletonViewController():getGlobalAnimationScale()
    local duration = math.sqrt(dx * dx + dy * dy) / (actor:getMoveSpeed() * scale)

    if deltaTime >= duration then
        -- 流逝时间已经超过全程所需时间，移动actor到目标位置，并停止移动
        actor:setActorPosition(targetPos)
    else
        -- 计算需要移动的距离
        local percent = deltaTime / duration
        local newPosition = {x = dx * percent + pos.x, y = dy * percent + pos.y}
        actor:setActorPosition(newPosition)
    end
end

-- 检查actor攻击对象是否在范围内并且是否需要移动
-- function QPositionDirector:_checkActorTarget(actor)
--     -- 如果当前处于手动干涉的模式，而且操作为停留在某地方
--     if actor:getManualMode() == actor.STAY then return FOLLOW_TARGET_NOCHANGE end

--     -- 没有攻击目标，则不需要处理
--     local target = actor:getTarget()
--     if target == nil or target:isDead() then return FOLLOW_TARGET_NOCHANGE end

--     local actorSkill = self:_getActorSkill(actor)

--     -- 如果自己是远程攻击类型，则不需要调整位置
--     if actorSkill:isRemoteSkill() == true then
--         return FOLLOW_TARGET_NOCHANGE
--     end

--     -- 如果跟踪目标失去方位，则同时调整
--     if target.gridPos == nil then return FOLLOW_TARGET_BOTH end

--     -- 如果自身此刻无目标位置
--     if actor.gridPos == nil then return FOLLOW_TARGET_CHANGE end

--     -- 如果actor不处于空闲状态，则某些情况下不需要调整位置
--     if not actor:isIdle() then
--         -- 如果actor正在移动，则考虑如果对手的位置已经和当初计划的位置发生了改变，比如已经被玩家设置了新的位置
--         if actor:isWalking() then
--             -- 如果正在跟踪对象，且目标的位置跟当初追踪的位置一致，则不需要重新调整位置
--             if actor.gridTargetPos ~= nil and q.is2PointsClose(actor.gridTargetPos, target.gridPos) then
--                 return FOLLOW_TARGET_NOCHANGE
--             end
--         end
--     end

--     -- 目标已经处于自己的攻击范围内，部分情况下不调整移动
--     if self:_isTargetInSkillRangeCurrent(actorSkill, actor, target) then
--         -- 检查actor跟踪的目标位置是否发生变化
--         if actor.gridTargetPos ~= nil then
--             -- 如果正在跟踪的对象位置发生了微调（由于周围有新的对象的影响），则不需要调整位置
--             if target.gridOriginalPos ~= nil and q.is2PointsClose(actor.gridTargetPos, target.gridOriginalPos) then
--                 return FOLLOW_TARGET_NOCHANGE
--             end
--             -- 如果正在跟踪对象，且目标的位置跟当初追踪的位置不一致，则需要更改位置
--             if not q.is2PointsClose(actor.gridTargetPos, target.gridPos) then
--                 -- 要更改位置，依然需要延迟FOLLOW_TARGET_DELAY时间，而不是立即更改，这样有足够的时间多发起1 ~ 2次攻击
--                 if actor.gridTargetTime == nil then
--                     actor.gridTargetTime = q.time()
--                     return FOLLOW_TARGET_NOCHANGE
--                 elseif q.time() - actor.gridTargetTime < FOLLOW_TARGET_DELAY then
--                     return FOLLOW_TARGET_NOCHANGE
--                 end
--             end
--         end
--         --已经过了等待时间，可以跟随目标了，重置目标等待时间为下一次跟随做准备
--         actor.gridTargetTime = nil
--     end

--     -- 目标不在自己的攻击范围内，寻找针对攻击目标的一个合适的位置
--     local targetSkill = self:_getActorSkill(target)
--     if target:getTarget() == actor then
--         -- 如果当前目标的攻击目标就是自己
--         if target:getManualMode() ~= target.STAY then
--             -- 如果target当前的模式是人工干扰的模式，则不要修改target的位置，否则可能需要修改对方目标位置
--             if not self:_isFollowStillValid(actor, target) or not self:_isFollowStillValid(target, actor) then
--                 -- 如果当前双方的位置跟踪部分失效，则需重新计算位置
--                 if not self:_isTargetInSkillRangeCurrent(targetSkill, target, actor) then
--                     -- 如果自己没有处于对方攻击范围内，比如对方是远程怪
--                     return FOLLOW_TARGET_BOTH
--                 end
--             end
--         end
--     end

--     if not self:_isFollowStillValid(actor, target) then
--         -- 如果原先跟踪的目标位置已经发生了变化
--         return FOLLOW_TARGET_CHANGE
--     end

--     if actor:isWalking() == false and self:_isTargetInSkillRangeCurrent(actorSkill, actor, target) == false then
--         if target:CanControlMove() == false then
--             return FOLLOW_TARGET_CHANGE
--         end
--     end

--     return FOLLOW_TARGET_NOCHANGE
-- end

function QPositionDirector:_checkActorTarget(actor)
    -- 如果当前处于不能普通攻击状态，则不需要处理
    if actor:isForbidNormalAttack()  then
        return FOLLOW_TARGET_NOCHANGE
    end

    -- 如果当前处于手动干涉的模式，而且操作为停留在某地方
    if actor:getManualMode() == actor.STAY then return FOLLOW_TARGET_NOCHANGE end

    if actor:isInTimeStop() then return FOLLOW_TARGET_NOCHANGE end

    -- 没有攻击目标，则不需要处理
    local target = actor:getTarget()
    if target == nil or target:isDead() then return FOLLOW_TARGET_NOCHANGE end

    -- 如果当前技能不允许走动，则不需要处理
    local currentSkill = actor:getCurrentSkill()
    if currentSkill and currentSkill:isStopMoving() and not currentSkill:isAllowMoving() then
        return FOLLOW_TARGET_NOCHANGE
    end

    local actorSkill = self:_getActorSkill(actor)

    -- 如果自己是远程攻击类型，则不需要调整位置
    if actorSkill:isRemoteSkill() == true then
        return FOLLOW_TARGET_NOCHANGE
    end

    -- 如果是找背职业，背向不对也需要调整位置
    if actor:isNeedComboPoints() and target and target:getTarget() ~= actor then
        local targetView = app.scene:getActorViewFromModel(target)
        local to_target_left = actor:getPosition().x < target:getPosition().x
        if math.xor(targetView:getDirection() == targetView.DIRECTION_LEFT, not to_target_left) then
            return FOLLOW_TARGET_CHANGE
        end
    end

    -- 如果跟踪目标失去方位，则同时调整
    if target.gridPos == nil then return FOLLOW_TARGET_BOTH end

    -- 如果自身此刻无目标位置
    if actor.gridPos == nil then return FOLLOW_TARGET_CHANGE end

    if actor:getCurrentSkill() == actorSkill then
        return FOLLOW_TARGET_NOCHANGE
    end

    -- 目标已经处于自己的攻击范围内，部分情况下不调整移动
    if self:_isTargetInSkillRangeCurrent(actorSkill, actor, target) then
        -- -- 检查actor跟踪的目标位置是否发生变化
        -- if actor.gridTargetPos ~= nil then
        --     -- 如果正在跟踪的对象位置发生了微调（由于周围有新的对象的影响），则不需要调整位置
        --     if target.gridOriginalPos ~= nil and q.is2PointsClose(actor.gridTargetPos, target.gridOriginalPos) then
        --         return FOLLOW_TARGET_NOCHANGE
        --     end
        --     -- 如果正在跟踪对象，且目标的位置跟当初追踪的位置不一致，则需要更改位置
        --     if not q.is2PointsClose(actor.gridTargetPos, target.gridPos) then
        --         -- 要更改位置，依然需要延迟FOLLOW_TARGET_DELAY时间，而不是立即更改，这样有足够的时间多发起1 ~ 2次攻击
        --         if actor.gridTargetTime == nil then
        --             actor.gridTargetTime = q.time()
        --             return FOLLOW_TARGET_NOCHANGE
        --         elseif q.time() - actor.gridTargetTime < FOLLOW_TARGET_DELAY then
        --             return FOLLOW_TARGET_NOCHANGE
        --         end
        --     end
        -- end
        -- --已经过了等待时间，可以跟随目标了，重置目标等待时间为下一次跟随做准备
        -- actor.gridTargetTime = nil
                
        if actor.gridTargetTime == nil then
            actor.gridTargetTime = q.time()
            return FOLLOW_TARGET_NOCHANGE
        elseif q.time() - actor.gridTargetTime < FOLLOW_TARGET_DELAY then
            return FOLLOW_TARGET_NOCHANGE
        end
    end

    local targetSkill = self:_getActorSkill(target)
    if target:getTarget() == actor and target:getManualMode() ~= target.STAY then
        if not self:_isTargetInSkillRangeCurrent(targetSkill, target, actor) then
            -- 如果自己没有处于对方攻击范围内，比如对方是远程怪
            return FOLLOW_TARGET_BOTH
        elseif (actor:isRanged() == false and target:isRanged() == false) then
            local inrange = self:_isTargetInSkillRangeCurrent(actorSkill, actor, target)
            local inposition = actor.gridPos and target.gridPos and math.abs(actor.gridPos.y - target.gridPos.y) <= 2
            if not inrange or not inposition then
                return FOLLOW_TARGET_BOTH
            else
                return FOLLOW_TARGET_NOCHANGE
            end
        end
    end
    return FOLLOW_TARGET_CHANGE 
end

-- 当actor位置需要调整时，重置所有以actor为目标的对象的位置信息，这样这些目标会在下一帧自动寻找到合适的新位置
function QPositionDirector:_clearFollowOfEnemies(actor)
    local enemies = {}
    for _, other in pairs(self._actors) do
        if other ~= actor and not other:isDead() and other:getTarget() == actor and not other:isRanged() and other:getManualMode() ~= other.STAY then
            self:_unsetWeight(other)
            self:_resetActorStatus(other)
            table.insert(enemies, other)
        end
    end

    return enemies
end

-- 检查actor对对象位置的跟踪是否依然有效
function QPositionDirector:_isFollowStillValid(actor, target)
    -- 如果没有跟踪任何目标，则判定跟踪无效
    if actor.gridTargetPos == nil then return false end
    
    -- 如果被跟踪目标当前等待重置位置，则判断跟踪有效
    if target.gridPos == nil then return true end

    -- 如果当前跟踪点与目标位置符合，则判定跟踪依然有效
    if q.is2PointsClose(actor.gridTargetPos, target.gridPos) then return true end

    -- 如果当前跟踪对象已经经过微调，但是原始位置与目标位置符合，则判定跟踪依然有效
    if target.gridOriginalPos ~= nil and q.is2PointsClose(actor.gridTargetPos, target.gridOriginalPos) then return true end

    return false
end

-- 获取actor的普攻技能
function QPositionDirector:_getActorSkill(actor)
    return actor:getTalentSkill()
end

-- 处理actor的攻击
function QPositionDirector:_handleActorAttack(actor)
    if app.battle:isPausedBetweenWave() then
        return
    end

    if actor:isForbidNormalAttack() then
        return
    end

    if actor:isAttacking() then
        return
    end

    local skill = nil
    skill = actor:getVaildActiveSkillForAutoLaunch()
    if skill == nil or skill:getSkillType() ~= skill.ACTIVE then
        return
    end

    if self:_isTargetInSkillRangeCurrent(skill, actor, actor:getTarget()) == true then
        if not (actor:isWalking() and actor:getManualMode() == actor.STAY) then
            if actor:isWalking() == false then
                actor:attack(skill)
                return true
            else
                if actor._grid_walking_attack_count == nil or actor._grid_walking_attack_count <= FRAME_BETWEEN_AUTO_ATTACK then
                    actor._grid_walking_attack_count = ((actor._grid_walking_attack_count == nil) and 1) or (actor._grid_walking_attack_count + 1)
                else
                    actor:attack(skill)
                    actor._grid_walking_attack_count = 0
                    return true
                end
            end
        end
    end
end

-- 判断actor是否处于攻击范围内
function QPositionDirector:_isTargetInSkillRangeFuture(skill, actor, target)
    if skill:isNeedATarget() == false then
        return true
    end

    local _, range = skill:getSkillRange(true)

    local actorWidth = actor:getRect().size.width / 2
    local targetWidth = target:getRect().size.width / 2

    local dx = math.abs((actor.gridPos.x - target.gridPos.x)) * GRID_UNIT.x
    local dy = math.abs((actor.gridPos.y - target.gridPos.y)) * GRID_UNIT.y

    return dx - actorWidth - targetWidth < range and dy < math.max(range, (global.melee_distance_y + 1) * GRID_UNIT.x * PERSPECTIVE_RATIO_VERTICAL)
end

-- 判断actor是否处于攻击范围内 - 依据对象当前位置进行判断
function QPositionDirector:_isTargetInSkillRangeCurrent(skill, actor, target)
    if skill:isNeedATarget() == false then
        return true
    end

    local _, range = skill:getSkillRange(true)

    local actorWidth = actor:getRect().size.width / 2
    local targetWidth = target:getRect().size.width / 2

    local dx = math.abs(actor:getPosition().x - target:getPosition().x)
    local dy = math.abs(actor:getPosition().y - target:getPosition().y)

    return dx - actorWidth - targetWidth < range and dy < math.max(range, (global.melee_distance_y + 1) * GRID_UNIT.x * PERSPECTIVE_RATIO_VERTICAL)
end

-- 为两个actor找一个合适的位置
function QPositionDirector:_findBestPositionByBoth(actor, target)
    -- 计算角色的宽度和攻击目标的宽度
    local actorWidth = actor:getRect().size.width / 2
    local targetWidth = target:getRect().size.width / 2

    -- 计算最短间距，需要考虑到双方技能是否能够击中
    local _, actorRange = self:_getActorSkill(actor):getSkillRange(false)
    local _, targetRange = self:_getActorSkill(target):getSkillRange(false)
    local skillRange = actorRange
    if skillRange > targetRange then skillRange = targetRange end

    -- 计算两个角色之间应该间隔的单元格的数量，需要保证双方的技能能够攻击到
    local dist = math.ceil((actorWidth + targetWidth) / GRID_UNIT.x) + 1
    while dist * GRID_UNIT.x - actorWidth - targetWidth > skillRange do
        dist = dist - 1
    end

    -- 得到当前目标位置
    local _, actorPos = self:_toGridPos(actor:getPosition().x, actor:getPosition().y)
    local _, targetPos = self:_toGridPos(target:getPosition().x, target:getPosition().y)
    
    -- 如果当前位置已经合乎要求，则返回
    if actorPos.y == targetPos.y and math.abs(actorPos.x - targetPos.x) == dist then
        return actorPos, targetPos
    end

    -- 计算最佳的中心点位置，需要与双方的移动速度加权
    local actorSpeed = actor:getMoveSpeed()
    local targetSpeed = target:getMoveSpeed()
    local center = {}
    if math.abs(actorSpeed) < EPSILON then
        center = clone(actorPos)
    elseif math.abs(targetSpeed) < EPSILON then
        center = clone(targetPos)
    else
        center = {
            x = math.round((actorPos.x / actorSpeed + targetPos.x / targetSpeed) / (1 / actorSpeed + 1 / targetSpeed)),
            y = math.round((actorPos.y / actorSpeed + targetPos.y / targetSpeed) / (1 / actorSpeed + 1 / targetSpeed)),
        }
    end
    -- 计算两个actor分别应该做的偏移
    local actorDist = 0
    local targetDist = 0

    -- 移动后继续保持actor和target的左右关系不变，以当前位置为准而不是目标位置
    if actor:getPosition().x < target:getPosition().x then
        actorDist = -math.floor(dist / 2) -- 中心点靠左偏移
        targetDist = dist + actorDist -- 中心点靠右偏移
    else
        actorDist = math.floor(dist / 2) -- 中心点靠右偏移
        targetDist = -dist + actorDist -- 中心点靠左偏移
    end

    -- 以最佳中心点为中心，SEARCH_RADIUS_2为半径，寻找最合适两个人站位的位置
    local minWeight = MAX_WEIGHT -- 搜索过程中记录最小权重
    local minPos = nil -- 最小权重点所在的位置
    for x = center.x - SEARCH_RADIUS_2, center.x + SEARCH_RADIUS_2 do
        for y = center.y - SEARCH_RADIUS_2, center.y + SEARCH_RADIUS_2 do
            actorPos = {x = x + actorDist, y = y}
            targetPos = {x = x + targetDist, y = y}
            if self:_isInRange(actorPos.x, actorPos.y) and self:_isInRange(targetPos.x, targetPos.y) then
                local actorDist = q.distOf2Points(actor:getPosition(), self:_toScreenPos(actorPos))
                local targetDist = q.distOf2Points(target:getPosition(), self:_toScreenPos(targetPos))
                -- 双方走到这个位置的时间差不能太长，否则不自然
                if math.abs(actorDist / actorSpeed - targetDist / targetSpeed) < BEST_POSITION_BOTH_DIFF_TIME then
                    -- 评估的权重：当前格子的权重 + 与中心点的距离的加权
                    local evalWeight = self._grid[actorPos.x][actorPos.y] + self._grid[targetPos.x][targetPos.y] + math.sqrt((center.x - x) * (center.x - x) + (center.y - y) * (center.y - y))
                    if evalWeight < minWeight then
                        local actorpos, targetpos
                        if math.abs(actorSpeed) < EPSILON then
                            actorpos = {x = x, y = y}
                            targetpos = {x = x + targetDist - actorDist, y = y}
                        elseif math.abs(targetSpeed) < EPSILON then
                            actorpos =  {x = x + actorDist - targetDist, y = y}
                            targetpos = {x = x, y = y}
                        else
                            actorpos = {x = x + actorDist, y = y}
                            targetpos = {x = x + targetDist, y = y}
                        end
                        local _actor = {}
                        local _target = {}
                        function _actor:getRect() return actor:getRect() end
                        function _actor:getPosition() return actorpos end
                        function _target:getRect() return target:getRect() end
                        function _target:getPosition() return targetpos end
                        if self:_isTargetInSkillRangeCurrent(self:_getActorSkill(actor), _actor, _target) and self:_isTargetInSkillRangeCurrent(self:_getActorSkill(target), _target, _actor) or true then
                            minWeight = evalWeight
                            minPos = {x = x, y = y}
                        end
                    end
                end
            end
        end
    end

    -- 这里应该不会发生的，但是还是有一定概率发生，暂时没有弄清楚为什么
    if minPos == nil then
        minPos = center
    end

    -- leftPos是actor的位置，rightPos是target的位置，请注意，不一定leftPos在rightPos左边！
    local leftPos, rightPos
    if math.abs(actorSpeed) < EPSILON then
        leftPos = {x = minPos.x, y = minPos.y}
        rightPos = {x = minPos.x + targetDist - actorDist, y = minPos.y}
    elseif math.abs(targetSpeed) < EPSILON then
        leftPos = {x = minPos.x + actorDist - targetDist, y = minPos.y}
        rightPos = {x = minPos.x, y = minPos.y}
    else
        leftPos = {x = minPos.x + actorDist, y = minPos.y}
        rightPos = {x = minPos.x + targetDist, y = minPos.y}
    end

    if leftPos.x <= rightPos.x then
        if leftPos.x < 1 then
            rightPos.x = rightPos.x + 1 - leftPos.x
            leftPos.x = 1
        elseif rightPos.x > self._nx then
            leftPos.x = leftPos.x + self._nx - rightPos.x
            rightPos.x = self._nx
        end
    else
        if rightPos.x < 1 then
            leftPos.x = leftPos.x + 1 - rightPos.x
            rightPos.x = 1
        elseif leftPos.x > self._nx then
            rightPos.x = rightPos.x + self._nx - leftPos.x
            leftPos.x = self._nx
        end
    end

    return leftPos, rightPos
end


-- 以攻击目标为中心寻找合适的攻击位置
-- function QPositionDirector:_findBestPositionByTarget(actor, target)
--     -- 计算角色的宽度和攻击目标的宽度
--     local actorWidth = actor:getRect().size.width / 2
--     local targetWidth = target:getRect().size.width / 2

--     -- 由于体型的大小不同需要考虑的间距
--     local bodySpace = math.round((actorWidth + targetWidth) / GRID_UNIT.x) 

--     -- 针对目标X，可以选择的位置，左边和右边分别3个位置
--     --[[
--         |-----|-----|-----|
--         |    1|     |4    |
--         |-----|-----|-----|
--         |  2  |  X  |  5  |
--         |-----|-----|-----|
--         |  3  |     |  6  |
--         |-----|-----|-----|
--     --]]

--     -- target的速度几乎静止时的特殊处理
--     if target:getMoveSpeed() < EPSILON then
--         local _, gridPos = self:_toGridPos(target:getPosition().x, target:getPosition().y)

--         local candidates = {
--             -- x, y, w: x坐标，y坐标，权重加成，上图中2、5两个位置优先选择，其他位置作为第二选择
--             {x = gridPos.x - bodySpace + 1, y = gridPos.y + 2, w = DISTANCE_WEIGHT * 2},
--             {x = gridPos.x - bodySpace - 1, y = gridPos.y,     w = 0},
--             {x = gridPos.x - bodySpace - 1, y = gridPos.y - 2, w = DISTANCE_WEIGHT * 4},

--             {x = gridPos.x + bodySpace - 1, y = gridPos.y + 2, w = DISTANCE_WEIGHT * 2},
--             {x = gridPos.x + bodySpace + 1, y = gridPos.y,     w = 0},
--             {x = gridPos.x + bodySpace + 1, y = gridPos.y - 2, w = DISTANCE_WEIGHT * 4},
--         }

--         -- 当前位置
--         local curPos = actor:getPosition()
--         _, curPos = self:_toGridPos(curPos.x, curPos.y)

--         -- 寻找一个权重最小的位置
--         local minWeight = MAX_WEIGHT -- 搜索过程中记录最小权重
--         local minPos = nil -- 最小权重点所在的位置  

--         -- 去掉actor和target在网格中的权重影响
--         -- 这里需要同时unset target对网格权重的影响，主要是需要单纯只考虑candidates中的权重，如果target的权重
--         -- 依然作用在整个网格中，则会与candidates中的权重影响叠加，失去只是考虑candidates中的权重的目的
--         self:_unsetWeight(actor)
--         self:_unsetWeight(target)

--         for _, gridPos in ipairs(candidates) do
--             if self:_isInRange(gridPos.x, gridPos.y) then
--                 -- 新位置评估的权重，当前权重 + 位置选择偏好权重
--                 local evalWeight = self._grid[gridPos.x][gridPos.y] + gridPos.w
--                 -- 计算距离带来的权重
--                 local dist = q.distOf2Points(gridPos, curPos)
--                 evalWeight = evalWeight + dist * DISTANCE_WEIGHT
--                 if evalWeight < minWeight then
--                     -- 选择权重最小的
--                     minWeight = evalWeight
--                     minPos = gridPos
--                 end
--             end
--         end
        
--         -- 恢复actor和target在网格中的权重
--         self:_setWeight(actor)
--         self:_setWeight(target)

--         return minPos, nil
--     end

--     local candidates = {
--         -- x, y, w: x坐标，y坐标，权重加成，上图中2、5两个位置优先选择，其他位置作为第二选择
--         {x = target.gridPos.x - bodySpace + 1, y = target.gridPos.y + 2, w = DISTANCE_WEIGHT * 2},
--         {x = target.gridPos.x - bodySpace - 1, y = target.gridPos.y,     w = 0},
--         {x = target.gridPos.x - bodySpace - 1, y = target.gridPos.y - 2, w = DISTANCE_WEIGHT * 4},

--         {x = target.gridPos.x + bodySpace - 1, y = target.gridPos.y + 2, w = DISTANCE_WEIGHT * 2},
--         {x = target.gridPos.x + bodySpace + 1, y = target.gridPos.y,     w = 0},
--         {x = target.gridPos.x + bodySpace + 1, y = target.gridPos.y - 2, w = DISTANCE_WEIGHT * 4},
--     }

--     -- 当前位置
--     local curPos = actor:getPosition()
--     _, curPos = self:_toGridPos(curPos.x, curPos.y)

--     -- 寻找一个权重最小的位置
--     local minWeight = MAX_WEIGHT -- 搜索过程中记录最小权重
--     local minPos = nil -- 最小权重点所在的位置  

--     -- 去掉actor和target在网格中的权重影响
--     -- 这里需要同时unset target对网格权重的影响，主要是需要单纯只考虑candidates中的权重，如果target的权重
--     -- 依然作用在整个网格中，则会与candidates中的权重影响叠加，失去只是考虑candidates中的权重的目的
--     self:_unsetWeight(actor)
--     self:_unsetWeight(target)

--     for _, gridPos in ipairs(candidates) do
--         if self:_isInRange(gridPos.x, gridPos.y) then
--             -- 新位置评估的权重，当前权重 + 位置选择偏好权重
--             local evalWeight = self._grid[gridPos.x][gridPos.y] + gridPos.w
--             -- 计算距离带来的权重
--             local dist = q.distOf2Points(gridPos, curPos)
--             evalWeight = evalWeight + dist * DISTANCE_WEIGHT
--             if evalWeight < minWeight then
--                 -- 选择权重最小的
--                 minWeight = evalWeight
--                 minPos = gridPos
--             end
--         end
--     end

--     -- 以防万一
--     if minPos == nil then minPos = clone(target.gridPos) end

--     -- 计算最佳的点位置，需要考虑双方移动速度，如果actor不能过早走过去等在那里
--     local actorSpeed = (math.abs(actor:getMoveSpeed()) < EPSILON) and EPSILON or actor:getMoveSpeed()
--     local targetSpeed = (math.abs(target:getMoveSpeed()) < EPSILON) and EPSILON or target:getMoveSpeed()

--     -- 计算target走到目标地点所需要的时间
--     local targetMoveTime = q.distOf2Points(target:getPosition(), self:_toScreenPos(target.gridPos)) / targetSpeed

--     -- 计算actor走到目标地点所需要的时间
--     local actorMoveTime = q.distOf2Points(actor:getPosition(), self:_toScreenPos(minPos)) / actorSpeed
--     local midPos = nil -- actor路径中的中间点

--     if targetMoveTime - actorMoveTime > BEST_POSITION_BOTH_DIFF_TIME then
--         -- target走到目标地点的时间远大于actor走到目标地点的时间，则需要在target走到目标地点的路径上找一个点先移动过去
--         -- 这里进行一个简化的计算，将target的路径上取1/3, 2/3路程的两个节点。判断到哪个节点两个actor的时间差最短。
--         local segments = 20
--         local percents = {}
--         for i = 1, segments do
--             percents[#percents + 1] = i / segments
--         end
--         local minTime = MAX_WEIGHT
--         for _, percent in ipairs(percents) do
--             local targetPos = self:_toScreenPos(target.gridPos)
--             local testPos = {
--                 x = (target:getPosition().x - targetPos.x) * percent + targetPos.x,
--                 y = (target:getPosition().y - targetPos.y) * percent + targetPos.y
--             }
--             local timeDiff = math.abs(q.distOf2Points(target:getPosition(), testPos) / targetSpeed - q.distOf2Points(actor:getPosition(), testPos) / actorSpeed)
--             if timeDiff < minTime then
--                 minTime = timeDiff
--                 _, midPos = self:_toGridPos(testPos.x, testPos.y)
--             end
--         end
--     end

--     if minPos then
--         -- 如果target已经在x轴方向朝actor走来，actor不应该后退
--         if math.xor((self:_toScreenPos(target.gridPos).x - target:getPosition().x > 0), (target:getPosition().x - actor:getPosition().x > 0)) then
--             if math.xor((self:_toScreenPos(minPos).x - actor:getPosition().x > 0), (target:getPosition().x - self:_toScreenPos(target.gridPos).x > 0)) then
--                 -- 把gridPos平移到actor position上方作为midPos
--                 _, midPos = self:_toGridPos(actor:getPosition().x, self:_toScreenPos(minPos).y)

--                 -- 计算线段"actor position --- midPos"与线段"target position --- target gridPos"之间的交汇点，假如有的话，作为midPos
--                 local actorPosition = actor:getPosition()
--                 local targetPosition = target:getPosition()
--                 local targetGridPosition = self:_toScreenPos(target.gridPos)
--                 if targetGridPosition.x - targetPosition.x ~= 0 then
--                     _, midPos = self:_toGridPos(actorPosition.x, (actorPosition.x - targetPosition.x) / (targetGridPosition.x - targetPosition.x) * (targetGridPosition.y - targetPosition.y) + targetPosition.y)
--                 end

--                 local segments = 100
--                 local percents = {}
--                 for i = 1, segments do
--                     percents[#percents + 1] = i / segments
--                 end
--                 local minTime = MAX_WEIGHT
--                 for _, percent in ipairs(percents) do
--                     local targetPos = self:_toScreenPos(target.gridPos)
--                     local testPos = {
--                         x = (target:getPosition().x - targetPos.x) * percent + targetPos.x,
--                         y = (target:getPosition().y - targetPos.y) * percent + targetPos.y
--                     }
--                     -- 防止倒走
--                     if math.xor(testPos.x - actorPosition.x >= 0, testPos.x - targetPosition.x >= 0) then
--                         local timeDiff = math.abs(q.distOf2Points(target:getPosition(), testPos) / targetSpeed - q.distOf2Points(actor:getPosition(), testPos) / actorSpeed)
--                         if timeDiff < minTime then
--                             minTime = timeDiff
--                             _, midPos = self:_toGridPos(testPos.x, testPos.y)
--                         end
--                     end
--                 end
--             end
--         end
--     end

--     -- 恢复actor和target在网格中的权重
--     self:_setWeight(actor)
--     self:_setWeight(target)

--     return minPos, midPos
-- end

-- 计算在当前位置当前速度下，并且知道target运动的方向与速度，actor是否能够追赶上target，
function QPositionDirector:_isCatchable(actor, target)
    
end

function QPositionDirector:_findBestPositionByTargetDirectline(actor, target)
    local skill = self:_getActorSkill(actor)
    local _, range = skill:getSkillRange(true)

    local actorWidth = actor:getRect().size.width / 2
    local targetWidth = target:getRect().size.width / 2

    local left = target:getPosition().x - actorWidth - targetWidth - range
    local right = target:getPosition().x + actorWidth + targetWidth + range
    local bottom = target:getPosition().y - range * PERSPECTIVE_RATIO_VERTICAL
    local top = target:getPosition().y + range * PERSPECTIVE_RATIO_VERTICAL

    local actorpos = clone(actor:getPosition())
    local targetpos = clone(target:getPosition())
    local tan = {y = targetpos.y - actorpos.y, x = targetpos.x - actorpos.x}
    if math.abs(tan.y) < EPSILON then
        if tan.y >= 0 then 
            tan.y = EPSILON
        else 
            tan.y = -EPSILON
        end
    end
    if math.abs(tan.x) < EPSILON then
        if tan.x >= 0 then
            tan.x = EPSILON
        else
            tan.x = -EPSILON
        end
    end

    if actorpos.x > right then
        actorpos.x = right
        actorpos.y = targetpos.y + (actorpos.x - targetpos.x) * tan.y / tan.x
    elseif actorpos.x < left then
        actorpos.x = left
        actorpos.y = targetpos.y + (actorpos.x - targetpos.x) * tan.y / tan.x
    end
    if actorpos.y > top then
        actorpos.y = top
        actorpos.x = targetpos.x + (actorpos.y - targetpos.y) * tan.x / tan.y
    elseif actorpos.y < bottom then
        actorpos.y = bottom
        actorpos.x = targetpos.x + (actorpos.y - targetpos.y) * tan.x / tan.y
    end

    actorpos.x = (actorpos.x - targetpos.x) * 0.9 + targetpos.x
    actorpos.y = (actorpos.y - targetpos.y) * 0.9 + targetpos.y

    local _, bestpos = self:_toGridPos(actorpos.x, actorpos.y)
    return bestpos, nil
end

function QPositionDirector:_findBestPositionByTarget(actor, target, directline)
    if directline == true then
        return self:_findBestPositionByTargetDirectline(actor, target)
    end

    -- 计算角色的宽度和攻击目标的宽度
    local actorWidth = actor:getRect().size.width / 2
    local targetWidth = target:getRect().size.width / 2

    -- 由于体型的大小不同需要考虑的间距
    local bodySpace = (actorWidth + targetWidth) / GRID_UNIT.x

    -- 计算攻击距离
    local _, actorRange = self:_getActorSkill(actor):getSkillRange(false)
    local actorRange = actorRange / GRID_UNIT.x
    local dx = 1
    dx = dx > actorRange and actorRange or dx
    local dy = global.melee_distance_y
    dy = dy > (math.max(actorRange, global.melee_distance_y + 1) * PERSPECTIVE_RATIO_VERTICAL) and (math.max(actorRange, global.melee_distance_y) * PERSPECTIVE_RATIO_VERTICAL) or dy

    -- 针对目标X，可以选择的位置，左边和右边分别3个位置
    --[[
        |-----|-----|-----|
        |    1|     |4    |
        |-----|-----|-----|
        |  2  |  X  |  5  |
        |-----|-----|-----|
        |  3  |     |  6  |
        |-----|-----|-----|
    --]]

    local _, gridPos = self:_toGridPos(target:getPosition().x, target:getPosition().y)

    local candidates = {
        -- x, y, w: x坐标，y坐标，权重加成，上图中2、5两个位置优先选择，其他位置作为第二选择
            {x = gridPos.x - bodySpace + dx, y = gridPos.y + dy, w = DISTANCE_WEIGHT * 4},
            {x = gridPos.x - bodySpace - dx, y = gridPos.y,     w = 0},
            {x = gridPos.x - bodySpace - dx, y = gridPos.y - dy, w = DISTANCE_WEIGHT * 8},

            {x = gridPos.x + bodySpace - dx, y = gridPos.y + dy, w = DISTANCE_WEIGHT * 4},
            {x = gridPos.x + bodySpace + dx, y = gridPos.y,     w = 0},
            {x = gridPos.x + bodySpace + dx, y = gridPos.y - dy, w = DISTANCE_WEIGHT * 8},
    }

    if actor:isNeedComboPoints() and not actor:isRanged() and actor:isNeedComboPoints() then
        local targetView = app.scene:getActorViewFromModel(target)
        if targetView:getDirection() == targetView.DIRECTION_LEFT then
            candidates[1] = candidates[4]
            candidates[2] = candidates[5]
            candidates[3] = candidates[6]
        end
        candidates[4] = nil
        candidates[5] = nil
        candidates[6] = nil
    end

    -- 根据target当前的速度预判几帧后的位置
    if target and target:isWalking() and target:getTargetPosition() and target:getMoveSpeed() > EPSILON then
        local tan = {x = target:getTargetPosition().x - target:getPosition().x, y = target:getTargetPosition().y - target:getPosition().y}
        local speed = target:getMoveSpeed()

        -- 计算actor走完全程需要消耗的时间
        local scale = QSkeletonViewController.sharedSkeletonViewController():getGlobalAnimationScale()
        local duration = math.sqrt(tan.x * tan.x + tan.y * tan.y) / (actor:getMoveSpeed() * scale)
        if duration > EPSILON then
            local divide = 3 * duration -- (duration > 1 and duration or 1)
            local estimateVect = {x = tan.x / divide, y = tan.y / divide}
            if speed < actor:getMoveSpeed() then
                estimateVect.x = estimateVect.x * speed / actor:getMoveSpeed()
                estimateVect.y = estimateVect.y * speed / actor:getMoveSpeed()
            end
            estimateVect.x = estimateVect.x / GRID_UNIT.x
            estimateVect.y = estimateVect.y / GRID_UNIT.y

            for _, pos in pairs(candidates) do
                pos.x = pos.x + estimateVect.x
                pos.y = pos.y + estimateVect.y
            end
        end
    end

    for _, pos in pairs(candidates) do
        if pos.x < gridPos.x then
            pos.x = math.ceil(pos.x)
        else
            pos.x = math.floor(pos.x)
        end
        if pos.y < gridPos.y then
            pos.y = math.ceil(pos.y)
        else
            pos.y = math.floor(pos.y)
        end
        if pos.x < 1 then
            pos.x = 1
        elseif pos.x > self._nx then
            pos.x = self._nx
        end
        if pos.y < 1 then
            pos.y = 1
        elseif pos.y > self._ny then
            pos.y = self._ny
        end
    end

    -- 当前位置
    local curPos = actor:getPosition()
    _, curPos = self:_toGridPos(curPos.x, curPos.y)

    -- 寻找一个权重最小的位置
    local minWeight = MAX_WEIGHT -- 搜索过程中记录最小权重
    local minPos = nil -- 最小权重点所在的位置  

    -- 去掉actor和target在网格中的权重影响
    -- 这里需要同时unset target对网格权重的影响，主要是需要单纯只考虑candidates中的权重，如果target的权重
    -- 依然作用在整个网格中，则会与candidates中的权重影响叠加，失去只是考虑candidates中的权重的目的
    self:_unsetWeight(actor)
    self:_unsetWeight(target)

    local force_move = false
    if actor:getType() == ACTOR_TYPES.HERO or true then
        local mates = app.battle:getMyTeammates(actor, false)
        for _, mate in ipairs(mates) do
            if not mate:isRanged() then
                if mate.gridPos then
                    if mate.gridPos.x == curPos.x and mate.gridPos.y == curPos.y then
                        force_move = true
                    end
                else
                    local _, mateCurPos = self:_toGridPos(mate:getPosition().x, mate:getPosition().y)
                    if math.abs(mateCurPos.x - curPos.x) <= 2 and math.abs(mateCurPos.y - curPos.y) <= 2 then
                        force_move = true
                    end
                end
            end
        end
    end

    for _, gridPos in ipairs(candidates) do
        if self:_isInRange(gridPos.x, gridPos.y) then
            if not force_move or not (gridPos.x == curPos.x and gridPos.y == curPos.y) then

                local already_taken = false
                if actor:getType() == ACTOR_TYPES.HERO or true then
                    local mates = app.battle:getMyTeammates(actor, false)
                    for _, mate in ipairs(mates) do
                        if not mate:isRanged() then
                            if mate.gridPos then
                                if math.abs(mate.gridPos.x - gridPos.x) <= 2 and math.abs(mate.gridPos.y - gridPos.y) <= 2 then
                                    already_taken = true
                                end
                            else
                                local _, mateCurPos = self:_toGridPos(mate:getPosition().x, mate:getPosition().y)
                                if mateCurPos.x == gridPos.x and mateCurPos.y == gridPos.y then
                                    already_taken = true
                                end
                            end
                        end
                    end
                end

                if not already_taken then
                    -- 新位置评估的权重，当前权重 + 位置选择偏好权重
                    local evalWeight = self._grid[gridPos.x][gridPos.y] + gridPos.w
                    -- 计算距离带来的权重
                    local dist = q.distOf2Points(gridPos, curPos)
                    evalWeight = evalWeight + dist * DISTANCE_WEIGHT
                    if evalWeight < minWeight then
                        -- 选择权重最小的
                        minWeight = evalWeight
                        minPos = gridPos
                    end
                end
            end
        end
    end
    
    -- 恢复actor和target在网格中的权重
    self:_setWeight(actor)
    self:_setWeight(target)

    if minPos == nil then
        minPos = candidates[math.random(1, #candidates)]
    end

    return minPos, nil
end

-- 寻找一个距离目标点最合适的位置，输入参数：目标点
function QPositionDirector:_findBestPositionByRadius(actor, pos)
    local minWeight = MAX_WEIGHT -- 搜索过程中记录最小权重
    local minPos = nil -- 最小权重点所在的位置

    -- 如果当前pos不在范围内，则不需要处理权重问题，直接返回当前位置
    if not self:_isInRange(pos.x, pos.y) then
        return pos
    end

    -- 去除actor自身在网格中的权重影响
    self:_unsetWeight(actor)

    -- 寻找目标位置半径为 SEARCH_RADIUS_1，由于此时是指定角色的目标位置，不宜偏离太远
    for x = pos.x - SEARCH_RADIUS_1, pos.x + SEARCH_RADIUS_1 do
        for y = pos.y - SEARCH_RADIUS_1, pos.y + SEARCH_RADIUS_1 do
            if self:_isInRange(x, y) then
                -- 评估的权重：当前格子的权重 + 与中心点的距离的加权
                local evalWeight = self._grid[x][y] + math.sqrt((pos.x - x) * (pos.x - x) + (pos.y - y) * (pos.y - y))
                if evalWeight < minWeight then
                    local skillOK = false

                    local target = actor:getTarget()
                    if target == nil or not target:isRanged() then
                        skillOK = true
                    else
                        -- 如果目标是远程的话，我要保证落地的位置能攻击到目标
                        local _actor = {}
                        local _target = {}
                        function _actor:getRect() return actor:getRect() end
                        function _actor:getPosition() return {x = x, y = y} end
                        if self:_isTargetInSkillRangeCurrent(self:_getActorSkill(actor), _actor, target) then
                            skillOK = true
                        end
                    end

                    if skillOK then
                        minWeight = evalWeight
                        minPos = {x = x, y = y}
                    end
                end
            end
        end
    end

    -- 恢复actor自身在网格中的权重影响
    self:_setWeight(actor)

    if minPos == nil then
        return pos
    end
    
    return minPos
end

-- 将屏幕坐标转换为网格坐标
function QPositionDirector:_toGridPos(x, y)
    local isOutOfRange = true
    x = math.round((x - BATTLE_AREA.left) / GRID_UNIT.x)
    y = math.round((y - BATTLE_AREA.bottom) / GRID_UNIT.y)
    if x < 1 or x > self._nx or y < 1 or y > self._ny then
        return isOutOfRange, {x = x, y = y}
    end

    isOutOfRange = false
    return isOutOfRange, {x = x, y = y}
end

-- 将网格坐标转换为屏幕坐标
function QPositionDirector:_toScreenPos(pos)
    if pos == nil then return nil end
    return {x = BATTLE_AREA.left + pos.x * GRID_UNIT.x, y = BATTLE_AREA.bottom + pos.y * GRID_UNIT.y}
end

-- 检查当前格子坐标是否在格子范围内
function QPositionDirector:_isInRange(x, y)
    return x >= 1 and x <= self._nx and y >= 1 and y <= self._ny
end

-- 返回格子范围
function QPositionDirector:getRangeArea()
    if self._rangeArea == nil then
        self._rangeArea = {left = BATTLE_AREA.left + 1 * GRID_UNIT.x, right = BATTLE_AREA.left + self._nx * GRID_UNIT.x, 
                           bottom = BATTLE_AREA.bottom + 1 * GRID_UNIT.y, top = BATTLE_AREA.bottom + self._ny * GRID_UNIT.y}
    end
    return self._rangeArea
end

-- 将角色加入到位置管理器
function QPositionDirector:addActor(actor)
    if self:hasActor(actor) == false then
        table.insert(self._actors, actor)
    else
        printError("actor已经被加入到位置管理器中了!")
    end

    self:_resetActorStatus(actor)

    local pos = actor:getPosition()
    _, pos = self:_toGridPos(pos.x, pos.y)
    self:_setActorGridPos(actor, pos)
end

function QPositionDirector:hasActor(actor)
    return table.indexof(self._actors, actor, 1) ~= false
end

-- 让角色走动到某个位置
function QPositionDirector:moveActorTo(actor, screenPos, nomove, inrange, noreposition)
    if self:hasActor(actor) == false then
        printError("actor还没有被被加入到位置管理器中!")
        return
    end

    local _, gridPos = self:_toGridPos(screenPos.x, screenPos.y)

    -- 在目标点附近寻找一个合适的位置
    local bestPos
    if noreposition then
        bestPos = gridPos
    else
        bestPos = self:_findBestPositionByRadius(actor, gridPos)
    end

    -- 如果bestPos不在范围内，则看是否需要移动过去，目标位置只是设置一个位置，
    -- 则可以直接设置过去，比如actor的初始位置可能在屏幕外，否则如果是需要
    -- 移动过去的位置，则需要调整到屏幕内。
    if (nomove ~= true or inrange == true) and not self:_isInRange(bestPos.x, bestPos.y) then
        if bestPos.x < 1 then bestPos.x = 1 end
        if bestPos.y < 1 then bestPos.y = 1 end

        if bestPos.x > self._nx then bestPos.x = self._nx end
        if bestPos.y > self._ny then bestPos.y = self._ny end
    end

    local oldGridPos = actor.gridPos
    self:_resetActorFollowStatus(actor) -- 由于人工或者AI指定了actor的新位置，在这里记录的所有状态都需要重置，等待下一帧重新判断
    self:_setActorGridPos(actor, bestPos, nil, nomove)
    if noreposition == true then
        if nomove then
            actor:setActorPosition(self:_toScreenPos(bestPos))
        else
            actor:setActorPosition(screenPos)
        end
    else
        if oldGridPos ~= nil then
            self:_handleRepositionCheck(actor, oldGridPos)
        end
    end

    return self:_toScreenPos(bestPos)
end

-- 让角色走动到某个target的位置
function QPositionDirector:moveActorToTarget(actor, target, nomove, directline)
    if self:hasActor(actor) == false then
        printError("actor还没有被被加入到位置管理器中!")
        return
    end
    if self:hasActor(target) == false then
        printError("target!")
        return
    end

    -- 在目标点附近寻找一个合适的位置
    local gridPos, midPos = self:_findBestPositionByTarget(actor, target, directline)

    local oldGridPos = actor.gridPos
    self:_resetActorFollowStatus(actor) -- 由于人工或者AI指定了actor的新位置，在这里记录的所有状态都需要重置，等待下一帧重新判断
    self:_setActorGridPos(actor, gridPos, midPos, nomove)
    if oldGridPos ~= nil then
        self:_handleRepositionCheck(actor, oldGridPos)
    end
end

-- 让角色闪现到某个位置
function QPositionDirector:setActorTo(actor, screenPos, inrange, noreposition)
    self:moveActorTo(actor, screenPos, true, inrange, noreposition)
end

-- 设置actor在网格中的目标位置
function QPositionDirector:_setActorGridPos(actor, pos, midPos, nomove)
    if actor.gridPos ~= nil then
        -- 目标位置与当前位置匹配，不调整
        if actor.gridPos.x == pos.x and actor.gridPos.y == pos.y then
            -- 张南：高频率点击一处时的闪现bug
            if nomove then actor:setActorPosition(self:_toScreenPos(pos)) end
            
            return
        end
        self:_unsetWeight(actor)
    end

    actor.gridPos = {x = pos.x, y = pos.y}
    actor.gridMidPos = midPos
    actor.gridOriginalPos = nil
    actor.gridMoveSpeed = actor:getMoveSpeed()
    self:_setWeight(actor)

    -- 设置gridPos后，由onFrame循环控制是否需要移动
    -- 如果不需要走动过去，则直接设置位置
    if nomove then
        if actor:isWalking() then
            actor:stopMoving()
        end
        actor:setActorPosition(self:_toScreenPos(pos))
    end
end

-- 将角色从位置管理器中移除
function QPositionDirector:removeActor(actor)
    if actor.gridPos ~= nil then
        self:_unsetWeight(actor)
        self:_handleRepositionCheck(actor, actor.gridPos, true)
    end

    self:_resetActorStatus(actor)
    
    table.removebyvalue(self._actors, actor)
end

-- 为某个格子增加权重，如果权重为负或者坐标在区域外，则返回false，否则返回true
function QPositionDirector:_increaseGridWeight(x, y, weight)
    if weight <= 0 then return false end

    if self:_isInRange(x, y) then
        self._grid[x][y] = self._grid[x][y] + weight
        local opacity = self._grid[x][y] + BASE_OPACITY
        if opacity > 255 then opacity = 255 end
        self._sign[x][y]:setOpacity(opacity)
        return true
    end
    return false
end

-- 为某个格子减少权重，如果权重为负或者坐标在区域外，则返回false，否则返回true
function QPositionDirector:_decreaseGridWeight(x, y, weight)
    if weight <= 0 then return false end

    if self:_isInRange(x, y) then
        self._grid[x][y] = self._grid[x][y] - weight
        self._sign[x][y]:setOpacity(self._grid[x][y] + BASE_OPACITY)
        return true
    end
    return false
end

-- 角色的出现和消失对全局权重表的修改
function QPositionDirector:_adjustWeight(actor, handler, increase)
    if self._weightRecord == nil then
        self._weightRecord = {}
    end
    local weightRecord = self._weightRecord
    if increase then
        if weightRecord[actor:getId()] then
            return
        else
            weightRecord[actor:getId()] = true
        end
    else
        if not weightRecord[actor:getId()] then
            return
        else
            weightRecord[actor:getId()] = nil
        end
    end

    local pos = actor.gridPos
    if pos == nil or not self:_isInRange(pos.x, pos.y) then
        return
    end

    local actorWidth = math.round(actor:getRect().size.width / 2 / GRID_UNIT.x)

    -- 角色在图上权重的递减到零的距离
    local radius = math.ceil(ACTOR_WEIGHT / ACTOR_WEIGHT_DECREASE)
    local radius_sqr = radius * radius

    if not self._sqrt_table then
        self._sqrt_table = {}
    end
    local sqrt_table = self._sqrt_table

    -- 从中心点到外围依次设定
    local radius_real = math.min(WEIGHT_IMPACT_RADIUS + actorWidth, radius)
    local xmin = math.max(1,        pos.x - radius_real)
    local xmax = math.min(self._nx, pos.x + radius_real)
    local ymin = math.max(1,        pos.y - radius_real)
    local ymax = math.min(self._ny, pos.y + radius_real)
    local imin = xmin - pos.x
    local jmin = ymin - pos.y

    local i = imin
    for x = xmin, xmax do
        local row_slot = self._grid[x]
        local i_sqr = i * i
        i = i + 1
        j = jmin
        for y = ymin, ymax do
            local col_value = row_slot[y]
            local dist = i_sqr + j * j
            j = j + 1
            if dist < radius_sqr then
                local sqrt = sqrt_table[dist]
                if not sqrt then
                    sqrt = ACTOR_WEIGHT - math.round(ACTOR_WEIGHT_DECREASE * math.sqrt(dist))
                    sqrt_table[dist] = sqrt
                end
                local weight = sqrt
                row_slot[y] = col_value + (increase and weight or -weight)
            end
        end
    end
end

-- 当一个actor到达某个位置以后，查看是否对周围的actor有影响，是否需要调整位置
function QPositionDirector:_handleRepositionCheck(actor, gridPos)
    local actorWidth = actor:getRect().size.width / 2 / GRID_UNIT.x

    for _, other in pairs(self._actors) do
        -- 如果另一个人还没走到位，则不需要调整位置，下次那个人走到位以后还会继续触发这个调整
        if other ~= actor and not other:isDead() and other.gridPos ~= nil and not other:isWalking() then
            local dx = other.gridPos.x - gridPos.x
            local dy = other.gridPos.y - gridPos.y
            -- 对潜在的影响对象的判断需要考虑自身和对象的体型大小
            local radius = REPOSITION_CHECK_RADIUS + math.round(actorWidth + other:getRect().size.width / 2 / GRID_UNIT.x)
            if dx * dx + dy * dy <= radius * radius then
                -- 如果两个人都在攻击同一目标，和同一目标平行的对象需要优先调整位置，这样可以更合理的安排站位
                if actor:getTarget() == other:getTarget() and actor:getTarget() ~= nil and
                    actor:getTarget().gridPos ~= nil and actor.gridPos.y == actor:getTarget().gridPos.y then
                    self:_reposition(actor)
                else
                    self:_reposition(other)
                end
            end
        end
    end
end

-- 由于周围别的actor的影响，需要重新微调位置
function QPositionDirector:_reposition(actor)
    local skill = self:_getActorSkill(actor)
    local target = actor:getTarget()

    if target and actor == target:getTarget() then
        return
    end

    local bestPos
    if skill:isRemoteSkill() or target == nil or target.gridPos == nil then
        -- actor被影响到后需要重新调整位置时的搜索半径，仅仅对于远程actor有效，近程actor依然需要follow近程站位原则
        -- 或者actor当前没有攻击目标，处于空闲状态
        bestPos = self:_findBestPositionByRadius(actor, actor.gridPos)
    else
        -- 寻找另外一个合适的位置
        bestPos = self:_findBestPositionByTarget(actor, target)
    end
    
    if q.is2PointsClose(actor.gridPos, bestPos) then
        return
    end

    printInfo(q.time() .. " reposition: " .. actor:getDisplayName() .. " " .. actor:getManualMode())

    local gridOriginalPos = actor.gridPos
    self:_setActorGridPos(actor, bestPos) -- 这里会重置gridOriginalPos
    actor.gridOriginalPos = gridOriginalPos
end

-- 角色显示出来以后，设置对全局权重表的修改
function QPositionDirector:_setWeight(actor)
    -- local weightCount = self._weightCount
    -- if weightCount[actor] == nil then
    --     weightCount[actor] = {actor = actor, count = 1}
    -- else
    --     weightCount[actor].count = weightCount[actor].count + 1
    -- end

    self:_adjustWeight(actor, nil, true)
end

-- 角色消失或者需要一定到别的网格点是，恢复对全局权重表的修改
function QPositionDirector:_unsetWeight(actor)
    -- local weightCount = self._weightCount
    -- if weightCount[actor] == nil then
    --     weightCount[actor] = {actor = actor, count = -1}
    -- else
    --     weightCount[actor].count = weightCount[actor].count - 1
    -- end

    self:_adjustWeight(actor, nil, false)
end

function QPositionDirector:pauseMoving()
    self._pause = true
end

function QPositionDirector:continueMoving()
    self._pause = false
end

function QPositionDirector:isPauseMoving()
    return self._pause
end

function QPositionDirector:_onBulletTime(event)
    if event.name == QNotificationCenter.EVENT_BULLET_TIME_TURN_START then
        self:pauseMoving()
    elseif event.name == QNotificationCenter.EVENT_BULLET_TIME_TURN_FINISH then
        self:continueMoving()
    end
end

function QPositionDirector:resetWeight()
    -- 初始化屏幕网格位置点的权重
    self._grid = {}
    for x = 1, self._nx do
        local col = {}
        for y = 1, self._ny do
            col[y] = 0
        end
        self._grid[x] = col
    end

    -- 屏幕两边设置较高权重，表示尽量不要过去
    local weight = EDGE_WEIGHT
    -- 首先设置左边的权重 （没有和之前的初始化放在一块，让代码逻辑看起来更清晰）
    for x = 1, self._nx do
        for y = 1, self._ny do
            self._grid[x][y] = weight
        end
        weight = weight - EDGE_WEIGHT_DECREASE
        if weight <= 0 then
            break
        end
    end

    -- 然后设置右边的权重
    weight = EDGE_WEIGHT
    for x = self._nx, 1, -1 do
        for y = 1, self._ny do
            self._grid[x][y] = weight
        end
        weight = weight - EDGE_WEIGHT_DECREASE
        if weight <= 0 then
            break
        end
    end

    self._weightCount = {}
    self._weightRecord = {}
end

return QPositionDirector