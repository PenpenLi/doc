
--[[--

Timer 实现了一个计时器容器，用于跟踪应用中所有需要计时的事件。
该文件是从framework中的Timer改造过来适合Qidea的需求。

-- ]]
local QTimer = {}

--[[--

创建一个计时器。

**Returns:**

-   Timer 对象

]]
function QTimer.new()
    local timer = {}
    require(cc.PACKAGE_NAME .. ".api.EventProtocol").extend(timer)

    ----

    local countdowns = {}
    local timecount  = 0
    local isPause = false

    ----

    --[[--
    @ignore
    ]]
    local function onTimer(dt)
        if isPause == true then
            return
        end
        
        timecount = timecount + dt
        for eventName, cd in pairs(countdowns) do
            cd.countdown = cd.countdown - dt
            cd.nextstep  = cd.nextstep - dt

            if cd.countdown <= 0 then
                -- print(string.format("[finish] %s", eventName))
                timer:dispatchEvent({name = eventName, countdown = 0, dt = dt})
                timer:removeCountdown(eventName)
            elseif cd.nextstep <= 0 then
                -- print(string.format("[step] %s", eventName))
                cd.nextstep = cd.nextstep + cd.interval
                timer:dispatchEvent({name = eventName, countdown = cd.countdown, dt = dt})
            end
        end
    end
    
    timer.onTimer = onTimer
    ----

    --[[--
    **Parameters:**

    -   eventName: 计时器事件的名称
    -   countdown: 倒计时（秒）
    -   interval（可选）: 检查倒计时的时间间隔，最小为 0 秒，最长为 120 秒，如果未指定则默认为 30 秒

    ]]
    function timer:addCountdown(eventName, countdown, interval)
        eventName = tostring(eventName)
        assert(not countdowns[eventName], "eventName '" .. eventName .. "' exists")
        assert(type(countdown) == "number", "invalid countdown")

        if type(interval) ~= "number" then
            interval = 30
        else
            interval = math.floor(interval)
            if interval < 0 then
                interval = 0
            elseif interval > 120 then
                interval = 120
            end
        end

        countdowns[eventName] = {
            countdown = countdown,
            interval  = interval,
            nextstep  = interval,
        }
    end

    --[[--

    删除指定事件名称对应的计时器，并取消这个计时器的所有事件处理函数。

    **Parameters:**

    -   eventName: 计时器事件的名称

    ]]
    function timer:removeCountdown(eventName)
        eventName = tostring(eventName)
        countdowns[eventName] = nil
        self:removeAllEventListenersForEvent(eventName)
    end

    --[[--

    启动计时器容器。

    在开始游戏时调用这个方法，确保所有的计时器事件都正确触发。

    ]]
    function timer:start()
        if not self.handle then
            self.handle = scheduler.scheduleGlobal(onTimer, 1/30, false)
        end
    end

    --[[--

    停止计时器容器。

    ]]
    function timer:stop()
        if self.handle then
            scheduler.unscheduleGlobal(self.handle)
            self.handle = nil
        end
        isPause = false
    end

    --[[
        暂停计时器    
    --]]
    function timer:pause()
        isPause = true
    end

    --[[
        恢复计时器    
    --]]
    function timer:resume()
        isPause = false
    end

    function timer:isPause()
        return isPause
    end

    return timer
end

return QTimer
