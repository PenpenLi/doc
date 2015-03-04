require "socket"
local quickSort = import("....lib.quick_sort")

-- find the item with maximium value in specified field
function table.max(list, field)
    local max = 0
    local r = nil
    for i, item in pairs(list) do
        if item[field] > max then
            r = item
            max = item[field]
        end
    end

    return r
end

-- find the item with maximium value in specified field
function table.max_fun(list, fun)
    local max = 0
    local r = nil
    for i, item in pairs(list) do
        if fun(item) > max then
            r = item
            max = fun(item)
        end
    end

    return r
end

-- find is value in specified field
function table.find(list, value)
    if list ~= nil and value ~= nil then
        for _, item in pairs(list) do
            if item == value then
                return true
            end
        end
    end
    return false
end

--通过index查找item值
function table.itemOfIndex(t, index)
    local i = 1
    for k, v in pairs(t) do
        if i == index then
            return v
        end
        i = i + 1
    end
    return nil
end

--[[--

合并表格中的值，此处当作数组处理

~~~ lua

local dest = {1,2}
local src  = {3,4}
table.mergeForArray(dest, src)
-- dest = {1,2,3,4}

~~~

@param table dest 目标表格
@param table src 来源表格

]]
function table.mergeForArray(dest, src, filter_func)
    for _, v in ipairs(src) do
        if not filter_func or filter_func(v) then
            table.insert(dest, v)
        end
    end
end

--table转字符串
function table.join(t,sep)
    local str = ""
    local index = 0
    for k, v in pairs(t) do
        if type(v) == "number" or type(v) == "string" then
            if index > 0 then
                str = str..sep
            end
            str = str..v
            index = index + 1
        end
    end
    return str
end

--将table转换为sep1连接key和value，sep2连接数组格式的string
function table.formatString(t, sep1, sep2)
    local value = nil
    for k, v in pairs(t) do
      if value == nil then
        value = k..sep1..v 
      else
        value = value..sep2..k..sep1..v
      end
    end
    return value
end

--打印table
function print_lua_table (lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting..szValue..",")
        end
    end
end

_pesudo_id = 0
-- temporary uuid solution for demo
function uuid()
    _pesudo_id = _pesudo_id + 1
    return _pesudo_id
end

-- os.time返回只能精确到秒，不符合要求，os.clock返回CPU消耗的时间，不符合要求。
function q.time()
    return socket.gettime() -- 以秒为单位，精确到毫秒
end

-- 未通信时记录本地time，通信时小于500ms误差的以服务器时间为准
function q.serverTime()
    if remote == nil or remote.serverTime == nil or remote.serverResTime == nil then
        return q.time()
    end
    return remote.serverTime + q.time() - remote.serverResTime
end

-- 传入刷新时间点 计算刷新的时间毫秒数
function q.refreshTime(hour, min, sec)
    local currTime = os.date("*t", q.serverTime())
    local offsetTime = 0
    if tonumber(currTime.hour) < tonumber(hour) then
        offsetTime = 24*60*60
    end
    currTime.hour = hour or currTime.hour
    currTime.min = min or 0
    currTime.sec = sec or 0
    local freshTotalTime = os.time(currTime) - offsetTime
    return freshTotalTime
end

-- 传入时间点 计算指定的时间毫秒数
function q.getTimeForHMS(hour, min, sec)
    local currTime = os.date("*t", q.serverTime())
    currTime.hour = hour or currTime.hour
    currTime.min = min or currTime.min
    currTime.sec = sec or currTime.sec
    local freshTotalTime = os.time(currTime)
    return freshTotalTime
end

-- 传入秒数计算时间格式为 小时：分钟：秒
function q.timeToHourMinuteSecond(time)
    local hour = math.floor(time/(60*60))
    time = time % (60*60)
    local minute = math.floor(time/60)
    time = time%60
    local second = math.floor(time)
    -- if hour < 10 then
    --     hour = "0"..hour
    -- end
    -- if minute < 10 then
    --     minute = "0"..minute
    -- end
    -- if second < 10 then
    --     second = "0"..second
    -- end
    return string.format("%02d", hour)..":"..string.format("%02d", minute)..":"..string.format("%02d", second)
end

-- 判断两个点是否足够近
function q.is2PointsClose(pt1, pt2)
    local x = pt1.x - pt2.x
    local y = pt1.y - pt2.y
    return x * x + y * y < EPSILON * EPSILON
end

-- 计算两点距离
function q.distOf2Points(pt1, pt2)
    local dx = pt1.x - pt2.x
    local dy = pt1.y - pt2.y
    return math.sqrt(dx * dx + dy * dy)
end

--[[
/**
 *  计算距离添加换行符
 *  @param input 需要添加换行符的字符串
 *  @param skipSpace 是否忽略空格
 *  @return fullWidth 全角字符所占的宽度
 *  @return width 半角字符所占的宽度
 *  @return lineWidth 本行的宽度
 */
--]]
function q.autoWrap(input,fullWidth,width,lineWidth,skipSpace)
    local str = ""
    local num = ""
    if string.len(input) == 0 then return str end
    i = 1
    len = 0
    while true do 
        c = string.sub(input,i,i)
        b = string.byte(c)
        if b > 128 then
            str = str .. (string.sub(input,i,i+2))
            len = len + fullWidth
            i = i + 3
        else
            if b ~= 32 or skipSpace == false then
                str = str .. c
            end
            len = len + width
            i = i + 1
        end
        --检查数字中是否有换行符
        if (b >= 48 and b <= 57) or b == 46 then
            num = num..c
        elseif num ~= "" then
            num = ""
        end
        if i > #input then
            break
        end
        if b == 10 then
            len = 0
        elseif len >= lineWidth then
            if num ~= "" then
              str = q.replaceString(str, num, "\n")
              str = str..num 
              len = 0
            else
              str = str .. "\n"
              len = 0
            end
        end
     end
     return str
end

--替换源字符串中最后一个字符
function q.replaceString(s, pattern, reps)
  local i = string.len(s)
  local a = string.len(pattern)
  local str = ""
  local c = ""
  local isReplace = false
  while true do 
      if i < a then
        c = string.sub(s,1,i)
      else
        c = string.sub(s,i - a + 1, i)
      end
      if c == pattern and isReplace == false then
        str = reps..str
        i = i - a
        isReplace = true
      else
        str = c..str
        i = i - a
      end
      if i <= 0 then
        break
      end
  end
  return str
end

--[[
 /**
  *计算文字的长度
  * @param input 需要计算的文字
  * @param fullWidth 全角宽度
  * @param width 半角宽度
  */
--]]

function q.wordLen(input, fullWidth, width)
    local i = 1
    local len = 0
    if string.len(input) == 0 then return len end
    while true do 
        c = string.sub(input,i,i)
        b = string.byte(c)
        if b > 128 then
            len = len + fullWidth
            i = i + 3
        else
            len = len + width
            i = i + 1
        end
        if i > string.len(input) then
            break
        end
     end
     return len
end

--[[
 /**
  * 划分数字的千分制
  * @param num 需要转换的数字
  * @return str 返回的字符串
  */ 
]]
function q.micrometer(num)
    local str = ""
    while true do
        if num > 0 then
            str = tostring(num%1000) .. str 
        end
        num = math.floor(num/1000)
        if num > 0 then
            str =  "," .. str
        else
            break
        end
    end
    return str
end

--[[
    转换阿拉伯数字为中文数字
--]]
function q.numToWord(i)
    if i == 0 then
        return "零"
    elseif i == 1 then
        return "一"
    elseif i == 2 then
        return "二"
    elseif i == 3 then
        return "三"
    elseif i == 4 then
        return "四"
    elseif i == 5 then
        return "五"
    elseif i == 6 then
        return "六"
    elseif i == 7 then
        return "七"
    elseif i == 8 then
        return "八"
    elseif i == 9 then
        return "九"
    elseif i == 10 then
        return "十"
    end
end

--[[
    convert num address to ip address
]]
function q.convertNumToIP(num)
    local ip1 = math.floor(num/2^24)
    num = num%2^24
    local ip2 = math.floor(num/2^16)
    num = num%2^16
    local ip3 = math.floor(num/2^8)
    num = num%2^8
    local ip4 = math.floor(num)
    return string.format("%d.%d.%d.%d", ip1,ip2,ip3,ip4)
end

--[[
    convert ip address to num address
]]
function q.convertIPToNum(address)
    local ip1,ip2,ip3,ip4 = string.match(address, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
    return ip1*2^24 + ip2*2^16 + ip3*2^8 + ip4
end

-- sort node based on their y position from large to small when reverse is false
function q.sortNodeZOrder(nodes, reverse)
    if nodes == nil or table.nums(nodes) == 0 then
        return {}
    end
    local parent = nodes[1]:getParent()
    for k, node in ipairs(nodes) do
        if node:getParent() ~= parent then
            return nodes
        end
    end

    table.sort(nodes, function(node1, node2)
        local y1 = node1:getPositionY()
        local y2 = node2:getPositionY()

        if (y1 < y2) and (y2 - y1) > 1e-6 then
            return true
        end

        return false
    end)

    if reverse == false then
        local reverseNodes = {}
        local count = table.nums(nodes)
        count = count + 1
        for i, node in ipairs(nodes) do
            reverseNodes[(count - i)] = node
        end
        return reverseNodes
    else
        return nodes
    end

end

QBattle = {}

function QBattle.getTouchingActor(actorViews, x, y)
    if actorViews == nil then return nil end

    local touchedViews = {}
    for i, actorView in ipairs(actorViews) do
        if actorView.getModel and actorView:getModel():isDead() == false 
            and actorView:isTouchMoveOnMe(x, y) == true then
            if table.nums(touchedViews) == 0 
                and actorView:isTouchMoveOnMeDeeply(x, y) == true 
                and (not app.scene._showActorView or app.scene._showActorView == actorView) then
                return actorView
            else
                table.insert(touchedViews, actorView)
            end
        end
    end

    local touchedCount = table.nums(touchedViews)
    local selectView = nil
    if touchedCount == 1 then
        selectView = touchedViews[1]
    elseif touchedCount > 1 then
        local touchWeight = 0
        local coefficient = 0.8
        for i, touchedView in ipairs(touchedViews) do
            if app.scene._showActorView then
                if touchedView == app.scene._showActorView then
                    selectView = touchedView
                end
            else
                local newTouchWeight = touchedView:getTouchWeight(x, y, coefficient)
                if newTouchWeight > touchWeight then
                    selectView = touchedView
                    touchWeight = newTouchWeight
                    coefficient = coefficient - 0.2
                    if coefficient < 0.2 then
                        coefficient = 0.2
                    end
                end
            end
        end
    end

    return selectView
end

function math.xor(value1, value2)
    return (not not value1) == (not value2)
end

function math.sampler(value1, value2, percent)
    if type(percent) ~= "number" then
        return nil
    end

    if type(value1) == "number" and type(value2) == "number" then
        return value1 * (1 - percent) + value2 * percent 
    elseif type(value1) == "table" and type(value2) == "table" then
        local result = {}
        for k,v1 in pairs(value1) do
            if value2[k] ~= nil then
                local v2 = value2[k]
                if type(v1) == "number" and type(v2) == "number" then
                    result[k] = v1 * (1 - percent) + v2 * percent 
                end
            end
        end
        return result
    else
        return nil
    end
end

-- C (n, k) = n! / (k! * (n-k)!)
-- return the index array
-- n, k is a number
-- n should large or equal than k
function math.combine(n, k)
    local t = {}

    if n == nil then
        return t
    end

    if k == nil then
        k = 1
    end

    if type(n) ~= "number" or type(k) ~= "number" then
        return t
    end

    if n < k then
        return t
    end

    if n == k then
        local m = {}
        for i = n, 1, -1 do
            table.insert(m, i)
        end
        table.insert(t, m)
        return t
    end

    if k == 1 then
        for i = n, 1, -1 do
            local m = {}
            table.insert(m, i)
            table.insert(t, m)
        end
        return t
    end

    for i = n, k, -1 do
        local _t = math.combine(i - 1, k - 1)
        for _, m in ipairs(_t) do
            table.insert(m, 1, i)
        end
        for _, m in ipairs(_t) do
            table.insert(t, m)
        end
    end

    return t

end
