-- 用于记录被攻击的详细情况。
-- 但是后来功能被改造过一下：一旦开始攻击，则将攻击方也放入hitlog，用于保持战斗的持续性。因此现在HitLog的功能变成一个仇恨列表而不是攻击记录。

local QHitLog = class("QHitLog")

QHitLog.NO_DAMAGE = 0 -- 由于HitLog也保存了攻击对象，因此可能出现治疗误认为自己被攻击了，所以需要在治疗的AI里面单独处理这种情况

function QHitLog:ctor()
    self:clearAll()
end

function QHitLog:clearAll()
    self._hits = {}
end

function QHitLog:addNewHit(by, damage, skill, hatred)
    if app.battle:isGhost(by) then
        return 
    end

    local cur = app.battle:getTime()
    for i, hit in ipairs(self._hits) do
        if hit.by == by then
            -- 如果这一次的damage为QHitLog.NO_DAMAGE，则维持上一次的damage，因为此次有可能未命中，设置为0可能导致后续的getEnemiesInPeriod判断错误
            if damage == QHitLog.NO_DAMAGE then
                damage = hit.damage
            end
   
            table.remove(self._hits, i)
            break
        end
    end

    -- add a new record at the head of the table
    table.insert(self._hits, 1, {
        time = app.battle:getTime(),
        by = by,
        damage = damage,
        skill = skill,
        hatred = hatred,
    })
end

function QHitLog:isEmpty()
    local cur = app.battle:getTime()
    local result = true
    for i, hit in ipairs(self._hits) do
        if cur - hit.time < global.hatred_period and hit.by:isDead() == false then
            result = false
            break
        end
    end
    return result
end

-- 返回在一定时间内攻击过自己的敌人
function QHitLog:getEnemiesInPeriod(seconds)
    local enemies = {}
    local cur = app.battle:getTime()
    for i, hit in ipairs(self._hits) do
        -- 由于攻击对象也加入了HitLog保持战斗的持续性，因此这里要判断哪些是真正的被击
        if hit.damage ~= QHitLog.NO_DAMAGE and cur - hit.time < seconds then
            table.insert(enemies, hit.by)
        end
    end
    return enemies
end

function QHitLog:getLatestHit()
    return self._hits[1]
end

function QHitLog:getMaxHatred()
    local cur = app.battle:getTime()
    local actorHatred = {}

    -- calculate accumurated hatred in the limited period
    for i, hit in ipairs(self._hits) do
        if cur - hit.time < global.hatred_period and hit.by:isDead() == false then
            -- local found = false

            -- -- look for the actor from the statistics result
            -- for i, h in ipairs(actorHatred) do
            --     if h.by:isDead() then
            --         found = true -- not really found, but skip next step
            --         break
            --     end

            --     if h.by == hit.by then
            --         -- add the hatred to the actor
            --         h.hatred = h.hatred + hit.hatred
            --         found = true
            --         break
            --     end
            -- end

            -- if found == false then
                -- add a new record
                table.insert(actorHatred, {
                    by = hit.by,
                    hatred = hit.hatred,
                })
            -- end
        end
    end

    -- find the live actor with maximium hatred
    local max = table.max(actorHatred, "hatred")
    if max ~= nil then
        return max.by
    end

    return nil
end

function QHitLog:hasStoredHits()
    return self._stored_hits ~= nil
end

-- 储存当前的仇恨列表
function QHitLog:store()
    self._stored_hits = clone(self._hits)
    self._stored_time = app.battle:getTime()
end

-- 恢复之前保存的仇恨列表
function QHitLog:restore()
    if self._stored_hits == nil then
        return
    end

    -- nzhang: 恢复仇恨列表的必要操作，要把时间差也考虑进去。不然的话因为10秒最大仇恨追溯期的存在，会使得恢复仇恨列表毫无意义。
    for _, hit in ipairs(self._stored_hits) do
        hit.time = hit.time + (app.battle:getTime() - self._stored_time)
    end

    self._stored_hits = nil
end

return QHitLog