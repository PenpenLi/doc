
local QClient = class("QClient")

local QWebSocket = import(".QWebSocket")
local QTcpSocket = import(".QTcpSocket")
local QErrorInfo = import("..utils.QErrorInfo")

local retry = 0 -- 缺省情况下不重试

function QClient:ctor(host, port)
    self.websocket = nil

    self._isReady = false
    self._tcpsocket = QTcpSocket.new(host, port)

    self._sendList = {}
end

function QClient:open(success, fail)
    self._tcpProxy = cc.EventProxy.new(self._tcpsocket)
    self._tcpProxy:addEventListener(QTcpSocket.EVENT_START_CONNECT, handler(self, self._onStartConnect))
    self._tcpProxy:addEventListener(QTcpSocket.EVENT_CONNECT_SUCCESS, handler(self, self._onConnectSuccess))
    self._tcpProxy:addEventListener(QTcpSocket.EVENT_CONNECT_FAILED, handler(self, self._onConnectFailed))
    self._tcpProxy:addEventListener(QTcpSocket.EVENT_CONNECT_CLOSE, handler(self, self._onConnectClose))

    self._connectSuccessCallback = success
    self._connectFaildCallback = fail
    self._tcpsocket:connect()
end

function QClient:reopen(host, port, success, fail)
    if self._tcpProxy ~= nil then
        self:close()
    end

    if host ~= nil then self._tcpsocket:setHost(host) end
    if port ~= nil then self._tcpsocket:setPort(port) end
    self:open(success, fail)
    app:showLoading()
end

function QClient:close()
    self._tcpsocket:disConnect()

    if self._tcpProxy ~= nil then
        self._tcpProxy:removeAllEventListeners()
        self._tcpProxy = nil
    end
end

--[[
服务器连接当前是否可用
--]]
function QClient:isReady()
    return self._isReady
end

function QClient:_onStartConnect()
    
end

function QClient:_onConnectSuccess()
    app:hideLoading()
    self._isReady = true
    if self._connectSuccessCallback ~= nil then
        self._connectSuccessCallback()
        self._connectSuccessCallback = nil
    end
    if self._alert ~= nil then
        self._alert:close()
        self._alert = nil
    end
end

function QClient:_onConnectFailed()
    if remote.user.isLoginFrist == true then
        self:userAuthRequest(remote.user.session)
    end
    if self._connectFaildCallback ~= nil then
        self._connectFaildCallback()
    end
    app:hideLoading()
    self._alert = app:alert({content="连接服务器失败！点击确定重试", title="系统提示", comfirmBack=function()
            self._tcpsocket:connect()
            app:showLoading()
            self._alert = nil
        end}, false, true)
end

function QClient:_onConnectClose()
    self._isReady = false
    if remote.user.isLoginFrist == true then
        self:userAuthRequest(remote.user.session)
    end
end

--[[
/**
 * 用户认证
 * ＃param avatar, 用户从头像组里选择一个
 * ＃return
 *      返回 avatar
 */
--]]
function QClient:userAuthRequest(session)
    local name = "USER_AUTH"
    if self._sendList[name] == nil then
        self._sendList[name] = {api = name, sendTime = q.time(), isShow = false}
    else
        printInfo("the API is sended and in waiting!")
        return
    end
    local userAuthRequest = {session = session}
    local request = {api = name, userAuthRequest = userAuthRequest}
    local buffer = app:getProtocol():encodeMessageToBuffer("cc.qidea.wow.protocol.Request", request)
    self._tcpsocket:addRequestToResend(name, buffer, function (data)
        local response = app:getProtocol():decodeBufferToMessage("cc.qidea.wow.protocol.Response", data)
        for name,value in pairs(self._sendList) do
            if name == response.api then
                self._sendList[name] = nil
            end
        end
    end)
end

function QClient:_handleErrorCode(error)
    QErrorInfo:handle(error)
end

--[[
  convert package table to bytearray and send to server
  @param1 api name
  @param2 {api = "CT_USER_CREATE", struct name = struct body}
  @param3 success call back function
  @param4 fail call back function
  @param5 show loading for ui
  @param6 can duplicate send
]]
function QClient:requestPackageHandler(name, package, success, fail, isShow, isDuplicate)

    if self._tcpsocket:getState() ~= QTcpSocket.State_Connected then
        printInfo("server not connected, can not send data!")
        return
    end

    printInfo("request:")
    printTable(package)

    if isShow == nil then 
        isShow = true 
    end

    -- check the API is not sending
    if isDuplicate ~= true then
        if self._sendList[name] == nil then
            self._sendList[name] = {api = name, sendTime = q.time(), isShow = isShow}
        else
            printInfo("the API is sended and in waiting!")
            return
        end
    end

    if isShow == true then
        app:showLoading()
    end

    -- encode message
    local buffer = app:getProtocol():encodeMessageToBuffer("cc.qidea.wow.protocol.Request", package)

    -- send message
    self._tcpsocket:send(name, buffer, function(data)
        assert(data ~= nil, name.." receive empty data")
        local response = app:getProtocol():decodeBufferToMessage("cc.qidea.wow.protocol.Response", data)
        print("response:")
        printTable(response)

        local sendData = nil
        local isHide = true
        for name,value in pairs(self._sendList) do
            if name == response.api then
                sendData = value
                self._sendList[name] = nil
            elseif value.isShow == true then
                isHide = false
            end
        end
        if isHide == true then
            app:hideLoading()
        end

        if response.serverTime ~= nil then
            response.serverTime = response.serverTime/1000
            local currTime = q.time()
            if remote.serverTime == nil then
                remote.serverTime = response.serverTime
                remote.serverResTime = currTime
            elseif sendData ~= nil then
                if (currTime - sendData.sendTime) < 0.5 and remote.serverTime ~= nil then
                    remote.serverTime = response.serverTime
                    remote.serverResTime = currTime
                else
                    remote.serverTime = response.serverTime
                    remote.serverResTime = currTime
                end
            end
        end

        if response.error == "NO_ERROR" then
            remote:updateData(response)
            if success ~= nil then
                success(response)
            end
        else
            self:_handleErrorCode(response.error)
            if fail ~= nil then
                fail(response)
            end
        end
    end)
end

--[[
估计的与服务器的时间差，做与服务器时间相关的倒计时需要加上改数值
当前时钟滞后服务器时间，该值为正，当前时钟快于服务器时间，改值为负
--]]
function QClient:timeAlign()
    return self.websocket:timeAlign()
end

------------------------------------<<<<<<<<<<<<protocol content>>>>>>>>>>>>--------------------------------
--[[
/**
 * 创建新用户
 * @param uname 新用户的用户名
 * @param password 新用户的密码
 * @param success 回调函数参数包含：data.ctUser datra.serverInfos
 * @param fail
 * @param status
 */
--]]
function QClient:ctUserCreate(uname, password, success, fail, status)
    if password == nil then
        printInfo("Password is nil");
        if fail then fail() end
        return
    end

    if app ~= nil then
        app:resetRemote()
    end

    local ctUserCreateRequest = {name = uname, password = crypto.md5(password), deviceId = INFO_APP_UDID, deviceType = INFO_PLATFORM, channel = CHANNEL_NAME}
    local request = {api = "CT_USER_CREATE", ctUserCreateRequest = ctUserCreateRequest}
    self:requestPackageHandler("CT_USER_CREATE", request, success, fail)
end

--[[
/**
 * 使用激活码创建新用户
 * @param uname 新用户的用户名
 * @param password 新用户的密码
 * @param activationCode 激活码
 * @param success 回调函数
 */
--]]
function QClient:ctUserCreateWithActivationCode(uname, password, activationCode, success, fail)
    if password == nil then
        printInfo("Password is nil");
        if fail then fail() end
        return
    end

    if app ~= nil then
        app:resetRemote()
    end

    local ctUserCreateRequest = {name = uname, password = crypto.md5(password), activationCode = activationCode, deviceId = INFO_APP_UDID, deviceType = INFO_PLATFORM, channel = CHANNEL_NAME}
    local request = {api = "CT_USER_CREATE", ctUserCreateRequest = ctUserCreateRequest}
    self:requestPackageHandler("CT_USER_CREATE", request, success, fail)
end

--[[
/**
 * 中心服登陆
 * @param uname
 * @param password
 * @param success 回调函数参数包含：data.ctUser
 * @param fail
 * @param status
 */
 --]]
function QClient:ctUserLogin(uname, password, deliveryName, success, fail, status)
    if password == nil then
        printInfo("Password is nil");
        if fail then fail() end
        return
    end

    local ctUserLoginRequest = {name = uname, password = tostring(password), deviceId = INFO_APP_UDID, deviceType = INFO_PLATFORM, channel = CHANNEL_NAME}
    local request = {api = "CT_USER_LOGIN", ctUserLoginRequest = ctUserLoginRequest}
    self:requestPackageHandler("CT_USER_LOGIN", request, success, fail)
end


--[[
/**
 * 创建测试用户，用一个随机名字
 * @param success 回调函数参数包含：data.user
 * @param fail
 * @param status
 */
--]]
function QClient:userCreateForTest(success, fail, status)
    if app ~= nil then
        app:resetRemote()
    end

    self:ctUserCreate("" .. q.time(), "123456", success, fail)
end


--[[
/**
 *  用户区服登陆
 *  @param ctUserId 中心服中用户ID
 *  @param ctToken 中心服 用户登陆toke
 *  @return data.user
 */
--]]
function QClient:userLogin(ctUserId, ctSessionId, success, fail, status)
    local userLoginRequest = {ctUserId = ctUserId, ctSessionId = ctSessionId, deviceId = INFO_APP_UDID, deviceType = INFO_PLATFORM, channel = CHANNEL_NAME}
    local request = {api = "USER_LOGIN", userLoginRequest = userLoginRequest}
    self:requestPackageHandler("USER_LOGIN", request, success, fail)
end

--[[
/**
 * 修改用户昵称
 * ＃param nickname, 用户可以自己给顶一个昵称，或者空，我们会随机一个昵称出来
 * ＃return
 *      返回 nickname
 *           token
 */
--]]
function QClient:changeNickName(name, success, fail, status)
    local changeNicknameRequest = {nickname = name}
    local request = {api = "USER_NICKNAME", changeNicknameRequest = changeNicknameRequest}
    self:requestPackageHandler("USER_NICKNAME", request, success, fail)
end

--[[
/**
 * 修改用户头像
 * ＃param avatar, 用户从头像组里选择一个
 * ＃return
 *      返回 avatar
 */
--]]
function QClient:changeAvatar(newAvatar, success, fail, status)
    local changeAvatarRequest = {avatar = newAvatar}
    local request = {api = "USER_AVATAR", changeAvatarRequest = changeAvatarRequest}
    self:requestPackageHandler("USER_AVATAR", request, success, fail)
end

--[[
/**
 *  代币购买物品
 *  @param productId, 产品ID，
 *  @return 购买信息会在data.user中
 */
--]]
function QClient:buyProduct(productId, success, fail, status)
    local buyProductRequest = {productId = productId}
    local request = {api = "BUY_PRODUCT", buyProductRequest = buyProductRequest}
    self:requestPackageHandler("BUY_PRODUCT", request, success, fail)
end

--[[
/**
 * 购买体力
 * @param success 回调函数参数包含：data.user
 * @param fail
 * @param status
 */
--]]
function QClient:buyEnergy(success, fail, status)
    local request = {api = "BUY_ENERGY"}
    self:requestPackageHandler("BUY_ENERGY", request, success, fail)
end

--[[
/**
 * 购买金币
 * @return 返回购买信息在data.user中
 */
--]]
function QClient:buyMoney(success, fail, status)
    local request = {api = "BUY_MONEY"}
    self:requestPackageHandler("BUY_MONEY", request, success, fail, true, true)
end

--[[
/**
 * 获取指定商店信息
 * #param shopId, 商店ID
 * ＃return
 *      返回 stores
 */
--]]
function QClient:getStores(shopId, success, fail, status)
    local shopGetRequest = {shopId = shopId}
    local request = {api = "SHOP_GET", shopGetRequest = shopGetRequest}
    self:requestPackageHandler("SHOP_GET", request, success, fail, true, true)
end

--[[
/**
 * 购买一个物品
 * #param shopId, 商店ID
 * #param pos, 要购买的物品位置， 以 0 开始
 * #param itemId, 要购买的物品ID
 * #param count, 要购买的物品数量
 * ＃return
 */
--]]
function QClient:buyShopItme(shopId, pos, itemId, count, success, fail, status)
    local shopBuyRequest = {shopId = shopId, pos = pos, itemId = itemId, count = count}
    local request = {api = "SHOP_BUY", shopBuyRequest = shopBuyRequest}
    self:requestPackageHandler("SHOP_BUY", request, success, fail)
end

--[[
/**
 * 刷新一个商店
 *  #param shopId, 商店Id
 *  #return
 *      stores, 对应的store更新
 *      token，扣完代币后台的代币数量
 */
--]]
function QClient:refreshShop(shopId, success, fail, status)
    local shopRefreshRequest = {shopId = shopId}
    local request = {api = "SHOP_REFRESH", shopRefreshRequest = shopRefreshRequest}
    self:requestPackageHandler("SHOP_REFRESH", request, success, fail)
end

--[[
/**
 * 设置自定义标识位
 * @return 参照 data.payloads
 */
--]]
function QClient:putFlag(key, value, success, fail, status)
    local payloadPutRequest = { key = key, value = value}
    local request = {api = "PAYLOAD_PUT", payloadPutRequest = payloadPutRequest}
    self:requestPackageHandler("PAYLOAD_PUT", request, success, fail)
end

--[[
/**
 * 获取自定义标识位
 * @return 参照 data.payloads
 */
--]]
function QClient:getFlag(key, success, fail, status)
    local payloadReadRequest = { key = key}
    local request = {api = "PAYLOAD_READ", payloadReadRequest = payloadReadRequest}
    self:requestPackageHandler("PAYLOAD_READ", request, success, fail)
end

--[[
/**
 * 开始打副本
 * required string dungeonId = 1;                                              // 开始
 * repeated string heros = 2;                                                  // 参与战斗的英雄
 * @param fail
 * @param status
 */
--]]
function QClient:dungeonFightStart(dungeonId, actorIds, success, fail, status)
    local fightStartRequest = {dungeonId = dungeonId, heros = actorIds}
    local request = {api = "FIGHT_DUNGEON_START", fightStartRequest = fightStartRequest}
    self:requestPackageHandler("FIGHT_DUNGEON_START", request, success, fail)
end

--[[
/**
 * 成功打过一个副本
    optional int64 start_at = 1 [default = 0];                                  // 打斗开始时间
    optional int64 end_at = 2 [default = 0];                                    // 打斗结束时间
    optional string dungeon_id = 3 [default = ""];                              // 打斗的关卡ID
    repeated MonsterStatus monsters = 4;                                        // 打斗中的怪物状态
    repeated HeroStatus heros = 5;                                              // 英雄状态
    repeated FightTime fight_times = 6;                                         // 战斗时间片段
 */
--]]
function QClient:dungeonFightSucceed(battleLog, star, success, fail, status)
    local fightSuccessRequest = {start_at = battleLog.startTime, end_at = battleLog.endTime, dungeon_id = battleLog.dungeonId, star = star, monsters = {}, heros = {}, fight_times = {}}

    for _, state in pairs(battleLog.monsterState) do
        local monster = {}
        monster.monster_id = state.actor_id
        monster.showed_at = state.create_time
        monster.died_at = state.dead_time
        monster.index = state.monsterIndex
        table.insert(fightSuccessRequest.monsters, monster)
    end

    for _, state in pairs(battleLog.heroState) do
        local hero = {}
        hero.actor_id = state.actor_id
        hero.showed_at = state.create_time
        hero.died_at = state.dead_time
        table.insert(fightSuccessRequest.heros, hero)
    end

    for _, timeFragment in ipairs(battleLog.timeFragment) do
        local fight_time = {}
        if timeFragment.start_at ~= nil and timeFragment.end_at ~= nil then
            fight_time.start_at = timeFragment.start_at
            fight_time.end_at = timeFragment.end_at
            table.insert(fightSuccessRequest.fight_times, fight_time)
        end
    end
    local request = {api = "FIGHT_DUNGEON_SUCCEED", fightSuccessRequest = fightSuccessRequest}
    self:requestPackageHandler("FIGHT_DUNGEON_SUCCEED", request, success, fail, false)
end

--[[
/**
 * 成功扫荡一个副本
 * required string dungeonId = 1;                                              // 关卡ID
 * required int32  count = 2;                                                  // 扫荡次数
 * @param fail
 * @param status
 */
--]]
function QClient:dungeonFightQuick(dungeonId, count, success, fail, status)
    local fightQuickRequest = {dungeonId = dungeonId, count = count}
    local request = {api = "FIGHT_DUNGEON_QUICK", fightQuickRequest = fightQuickRequest}
    self:requestPackageHandler("FIGHT_DUNGEON_QUICK", request, success, fail)
end

--[[
/**
 * 今日关卡次数重置
 * required string dungeonId = 1;                                              // 关卡ID
 */
--]]
function QClient:buyDungeonTicket(dungeonId, success, fail, status)
    local fightDungeonResetRequest = {dungeonId = dungeonId}
    local request = {api = "FIGHT_DUNGEON_RESET", fightDungeonResetRequest = fightDungeonResetRequest}
    self:requestPackageHandler("FIGHT_DUNGEON_RESET", request, success, fail)
end

--[[
/**
 * 英雄突破
 *  required string actorId = 1;                                                // 要突破的英雄actorId
 *  @success 成功回调 包含 data.heros 突破过的英雄
 */
--]]
function QClient:breakthrough(actorId, success, fail, status)
    local heroBreakthroughRequest = {actorId = actorId}
    local request = {api = "HERO_BREAKTHROUGH", heroBreakthroughRequest = heroBreakthroughRequest}
    self:requestPackageHandler("HERO_BREAKTHROUGH", request, success, fail)
end

--[[
/**
 * 英雄进阶
 *  required string actorId = 1;                                                // 要进阶的英雄actorId
 *  @success 成功回调 包含 data.heros 进阶后的英雄 和 data.items 消耗物品后的状态
 */
--]]
function QClient:grade(actorId, success, fail, status)
    local heroGradeRequest = {actorId = actorId}
    local request = {api = "HERO_GRADE", heroGradeRequest = heroGradeRequest}
    self:requestPackageHandler("HERO_GRADE", request, success, fail)
end

--[[
/**
 *  英雄升级
 *  required string actorId = 1;                                                // 要强化的英雄actorId
    required int32 itemId = 2;                                                  // 强化物品
    required int32 count = 3;                                                   // 物品数量
 *  @return 成功返回 英雄信息 data.heros ,被删除的英雄在 data.remoteHeros 中
 */
--]]
function QClient:intensify(actorId, itemId, count, success, fail, status)
    local heroIntensifyRequest = { actorId = actorId, itemId = tostring(itemId), count = count }
    local request = {api = "HERO_INTENSIFY", heroIntensifyRequest = heroIntensifyRequest}
    self:requestPackageHandler("HERO_INTENSIFY", request, success, fail, false, true)
end

--[[
/**
 * 召唤英雄
 * @return 参照 data.payloads
 */
--]]
function QClient:summonHero(actorId, success, fail, status)
    local heroSummonRequest = {actorId = actorId}
    local request = {api = "HERO_SUMMON", heroSummonRequest = heroSummonRequest}
    self:requestPackageHandler("HERO_SUMMON", request, success, fail)
end

--[[
/**
 * 英雄技能强化
 * 
    required string actorId = 1;                                                // 要技能升级的英雄actorID
    required string skillId = 2;                                                // 要升级的技能ID
 */
--]]
function QClient:improveSkill(actorId, skillTypeId, success, fail, status)
    local heroSkillImproveRequest = { actorId = actorId, skillId = skillTypeId }
    local request = {api = "HERO_SKILL_IMPROVE", heroSkillImproveRequest = heroSkillImproveRequest}
    self:requestPackageHandler("HERO_SKILL_IMPROVE", request, success, fail, false, true)
end

--[[
/**
 * 购买技能点数
 * @return 返回购买信息在data.user中
 */
--]]
function QClient:buySkillTicket(success, fail, status)
    local request = {api = "HERO_SKILL_TICKET_BUY"}
    self:requestPackageHandler("HERO_SKILL_TICKET_BUY", request, success, fail)
end

--[[
    给英雄使用道具
    required string actorId = 1;
    required int32 itemId = 2;
]] 
function QClient:useItemForHero(itemId, actorId, success, fail, status)
    local itemUse4HeroRequest = { actorId = actorId, itemId = itemId}
    local request = {api = "ITEM_USE_FOR_HERO", itemUse4HeroRequest = itemUse4HeroRequest}
    self:requestPackageHandler("ITEM_USE_FOR_HERO", request, success, fail, false, true)
end

--[[
/**
 *  装备合成
 *  required int32 itemId = 1;                                                  // 要合成的装备ID
 *  @return data.user 更新后的用户数据 data.items 更新后的物品数据
 */
--]]
function QClient:itemMerge(itemId, success, fail)
    local itemMergeRequest = {itemId = itemId}
    local request = {api = "ITEM_MERGE", itemMergeRequest = itemMergeRequest}
    self:requestPackageHandler("ITEM_MERGE", request, success, fail)
end

--[[
/**
 * 卖物品
 repeated Item items = 1;                                                    // 要出售的物品，包含要多少出售
 * @return 参照 data.items
 */
--]]
function QClient:sellItem(items, success, fail, status)
    local itemSellRequest = {items = items}
    local request = {api = "ITEM_SELL", itemSellRequest = itemSellRequest}
    self:requestPackageHandler("ITEM_SELL", request, success, fail)
end

--[[
/**
 *  阅读一个邮件
    required string mailId = 1;                                                   // 邮件ID
 *  @return 返回这个邮件的更新后的状态 在 data.updatedMails
 */
--]]
function QClient:mailRead(mailId, success, fail, status)
    local mailReadRequest = {mailId = mailId}
    local request = {api = "MAIL_READ", mailReadRequest = mailReadRequest}
    self:requestPackageHandler("MAIL_READ", request, success, fail, false, true)
end

--[[
  /**
   * 领取邮件中得奖励
   required string mailId = 1;                                                   // 邮件ID
   */
--]]
function QClient:mailRecvAward(mailId, success, fail, status)
    local mailReceiveAwardRequest = {mailId = mailId}
    local request = {api = "MAIL_RECEIVE_AWARD", mailReceiveAwardRequest = mailReceiveAwardRequest}
    self:requestPackageHandler("MAIL_RECEIVE_AWARD", request, success, fail)
end

-------------------------------<< old api>>--------------------------------

--[[
/**
 * 列举用户邮箱中的邮件
 *  @return 返回邮件列表 在 data.mails
 */
--]]
function QClient:mailList(success, fail, status, isShow)
  --self.websocket:send("mail.list", {}, retry, success, fail, status, isShow)
end

--[[
  /**
   * 普通宝箱抽奖
    required bool isAdvance = 1;                                                // 是否是高级抽奖
    required int32 count = 2;                                                   // 抽奖次数, 必须为1或是10
   */
--]]
function QClient:luckyDraw(count, success, fail, status)
    local luckyDrawRequest = {isAdvance = false, count = count}
    local request = {api = "LUCKY_DRAW", luckyDrawRequest = luckyDrawRequest}
    self:requestPackageHandler("LUCKY_DRAW", request, success, fail)
end

--[[
  /**
   *  黄金宝箱抽奖
    required bool isAdvance = 1;                                                // 是否是高级抽奖
    required int32 count = 2;                                                   // 抽奖次数, 必须为1或是10
   */
--]]
function QClient:luckyDrawAdvance(count, success, fail, status)
    local luckyDrawRequest = {isAdvance = true, count = count}
    local request = {api = "LUCKY_DRAW", luckyDrawRequest = luckyDrawRequest}
    self:requestPackageHandler("LUCKY_DRAW", request, success, fail)
end

--[[
  /**
   * 章节星星抽奖
   *  required int32 index = 1;                                                   // 第几个心心抽奖
    required string mapId = 2;                                                  // 第几章节
   */
--]]
function QClient:luckyDrawMap(mapId, index, success, fail, status)
    local luckyDrawMapRequest = { mapId = mapId, index = index}
    local request = {api = "LUCKY_DRAW_MAP", luckyDrawMapRequest = luckyDrawMapRequest}
    self:requestPackageHandler("LUCKY_DRAW_MAP", request, success, fail)
end

--[[
  /**
     * 每日任务完成
     required string task = 1;                                                   // 任务编号
     *
     */
--]]
function QClient:dailyTaskComplete(task, success, fail, status)
    local dailyTaskCompleteRequest = { task = task}
    local request = {api = "DAILY_TASK_COMPLETE", dailyTaskCompleteRequest = dailyTaskCompleteRequest}
    self:requestPackageHandler("DAILY_TASK_COMPLETE", request, success, fail)
end

--[[
  /**
     * 成就完成
     required string achievementId = 1;                                          // 量表中的成就ID
     *
     */
--]]
function QClient:achieveComplete(achieve, success, fail, status)
    local achievementCompleteRequest = { achievementId = achieve}
    local request = {api = "ACHIEVEMENT_COMPLETE", achievementCompleteRequest = achievementCompleteRequest}
    self:requestPackageHandler("ACHIEVEMENT_COMPLETE", request, success, fail)
end

--[[
/**  
* 使用cdkey兑换码, 使用完成后检查邮箱  
*  #param cdkey, 要使用的cdkey  
*  
*  #return  
*      "{}"  
*  
*/ 
--]]
function QClient:sendCdKey(cdKey, success, fail, status)
    local userRequest = {key = cdKey}
    local request = {api = "CDKEY_USE", cdkeyUseRequest = userRequest}
    self:requestPackageHandler("CDKEY_USE", request, success, fail)
end

--[[
/**
 * 签到
 required int32 index = 1;                                                   // 签到的次数
 */
 --]]
function QClient:dailySignIn(index, success, fail, status)
    local checkInRequest = {index = index}
    local request = {api = "CHECK_IN", checkInRequest = checkInRequest}
    self:requestPackageHandler("CHECK_IN", request, success, fail)
end

--[[
/**
 * 累积签到
 required int32 index = 1;                                                   // 累计签到奖励次数
 */
 --]]
function QClient:addUpSignIn(index, success, fail, status)
    local checkInAwardRequest = {index = index}
    local request = {api = "CHECK_IN_AWARD", checkInAwardRequest = checkInAwardRequest}
    self:requestPackageHandler("CHECK_IN_AWARD", request, success, fail)
end

--[[
/**
 * 刷新竞技场信息
repeated string actorIds = 1;                                               // 换防的英雄actor IDs
 */
 --]]
function QClient:arenaRefresh(actorIds, success, fail, status)
    local arenaRefreshRequest = {actorIds = actorIds}
    local request = {api = "ARENA_REFRESH", arenaRefreshRequest = arenaRefreshRequest}
    self:requestPackageHandler("ARENA_REFRESH", request, success, fail)
end

--[[
/**
 * 设置战队
repeated string actorIds = 1;                                               // 换防的英雄actor IDs
 */
 --]]
function QClient:setDefenseHero(actorIds, success, fail, status)
    local arenaChangeDefenseHeroRequest = {actorIds = actorIds}
    local request = {api = "ARENA_CHANGE_DEFENSE_HEROS", arenaChangeDefenseHeroRequest = arenaChangeDefenseHeroRequest}
    self:requestPackageHandler("ARENA_CHANGE_DEFENSE_HEROS", request, success, fail)
end

--[[
/**
 * 开始竞技场
    required string rivalUserId = 1;                                            // 对手UserID
 */
 --]]
function QClient:arenaFightStartRequest(rivalUserId, success, fail, status)
    local arenaFightStartRequest = {rivalUserId = rivalUserId}
    local request = {api = "ARENA_FIGHT_START", arenaFightStartRequest = arenaFightStartRequest}
    self:requestPackageHandler("ARENA_FIGHT_START", request, success, fail)
end

--[[
/**
 * 结束竞技场
    required string rivalUserId = 1;                                            // 对手UserID
    required ArenaFightResult fightResult = 2;                                  // 挑战结果
 */
 --]]
function QClient:arenaFightEndRequest(rivalUserId, pos, fightResult, success, fail, status)
    local arenaFightEndRequest = {rivalUserId = rivalUserId, pos = pos, fightResult = fightResult}
    local request = {api = "ARENA_FIGHT_END", arenaFightEndRequest = arenaFightEndRequest}
    self:requestPackageHandler("ARENA_FIGHT_END", request, success, fail, false)
end

--[[
/**
 * 购买竞技场次数
 */
 --]]
function QClient:buyFightCountRequest(success, fail, status)
    local request = {api = "ARENA_BUY_FIGHT_COUNT"}
    self:requestPackageHandler("ARENA_BUY_FIGHT_COUNT", request, success, fail)
end

--[[
/**
 * 竞技场查询用户信息
 */
 --]]
function QClient:arenaQueryFighterRequest(user_Id, success, fail, status)
    local request = {api = "ARENA_QUERY_FIGHTER", arenaQueryFighterRequest = {userId = user_Id}}
    self:requestPackageHandler("ARENA_QUERY_FIGHTER", request, success, fail)
end

--[[
/**
 * 20次对战记录
 */
 --]]
function QClient:arenaAgainstRecordRequest(success, fail, status)
    local request = {api = "ARENA_FIGHT_HISTORY"}
    self:requestPackageHandler("ARENA_FIGHT_HISTORY", request, success, fail)
end

--[[
/**
 * 竞技场 TOP 50 排行榜
 */
 --]]
function QClient:arenaTop50RankRequest(success, fail, status)
    local request = {api = "ARENA_TOP_50"}
    self:requestPackageHandler("ARENA_TOP_50", request, success, fail)
end

--[[
/**
 * 排行榜
 */
 --]]
function QClient:top50RankRequest(type, userId, success, fail, status)
    local request = {api = "RANKINGS", rankingsRequest = {kind = type, userId = userId}}
    self:requestPackageHandler("RANKINGS", request, success, fail)
end

--[[
    请求太阳井关卡
]]
function QClient:sunwellQueryRequest(startIndex, endIndex, success, fail, status, isShow)
    if isShow == nil then isShow = false end
    local indexs = {}
    for i=startIndex,endIndex,1 do
        indexs[#indexs + 1] = i
    end
    local sunwellQueryRequest = {index = indexs}
    local request = {api = "SUNWELL_QUERY", sunwellQueryRequest = sunwellQueryRequest}
    self:requestPackageHandler("SUNWELL_QUERY", request, success, fail, isShow)
end

--[[
    请求太阳井战斗开始
]]
function QClient:sunwellFightStartRequest(index, pos, actorIds, success, fail, status)
    local sunwellFightStartRequest = {index = index, pos = pos, actorIds = actorIds} 
    local request = {api = "SUNWELL_FIGHT_START", sunwellFightStartRequest = sunwellFightStartRequest}
    self:requestPackageHandler("SUNWELL_FIGHT_START", request, success, fail)
end

--[[
    请求太阳井重置
]]
function QClient:sunwellResetRequest(success, fail, status)
    local request = {api = "SUNWELL_RESET"}
    self:requestPackageHandler("SUNWELL_RESET", request, success, fail)
end

--[[
    请求太阳井战斗结束
]]
function QClient:sunwellFightEndRequest(index, pos, selfHeros, enemyHeros, success, fail, status)
    local sunwellFightEndRequest = {index = index, pos = pos, selfHeros = selfHeros, enemyHeros = enemyHeros} 
    local request = {api = "SUNWELL_FIGHT_END", sunwellFightEndRequest = sunwellFightEndRequest}
    self:requestPackageHandler("SUNWELL_FIGHT_END", request, success, fail)
end

--[[
    请求领取宝箱
]]
function QClient:sunwellLuckyDrawRequest(index, success, fail, status)
    local sunwellLuckyDrawRequest = {index = index} 
    local request = {api = "SUNWELL_LUCKYDRAW", sunwellLuckyDrawRequest = sunwellLuckyDrawRequest}
    self:requestPackageHandler("SUNWELL_LUCKYDRAW", request, success, fail)
end

return QClient
