
local QUIDialog = import(".QUIDialog")
local QUIDialogAdjust = class("QUIDialogAdjust", QUIDialog)

local QUIViewController = import("..QUIViewController")
local QNavigationController = import("...controllers.QNavigationController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QStaticDatabase = import("...controllers.QStaticDatabase")

function QUIDialogAdjust:ctor(options)
    local ccbFile = "ccb/Dialog_Adjust.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerBack", callback = handler(self, QUIDialogAdjust._onTriggerBack)},
        {ccbCallbackName = "onAdjustCrew", callback = handler(self, QUIDialogAdjust._onAdjustCrew)},
        {ccbCallbackName = "onChallenge", callback = handler(self, QUIDialogAdjust._onChallenge)}
    }
    QUIDialogAdjust.super.ctor(self, ccbFile, callBacks, options)
    
    self._midPoint = self._ccbOwner["node_root"]:convertToWorldSpace(self._ccbOwner["sprite_3"]:getPositionInCCPoint())
    --最小块格子的宽高
    self._spriteWidth = self._ccbOwner["sprite_3"]:getContentSize().width /2
    self._spriteHeight = self._ccbOwner["sprite_3"]:getContentSize().height /2

    --左下角方块左下点的位置
    self._beginPoint = { x = self._midPoint.x - self._spriteWidth * 3, y = self._midPoint.y - self._spriteHeight * 3}
    --右上角方块右上点的位置
    self._endPoint = { x = self._beginPoint.x + self._spriteWidth * 10, y = self._beginPoint.y + self._spriteHeight * 6}
    -- 跟随人物头像摆放位置的小格layer
    self._smallLayer = CCLayerColor:create(ccc4(255, 255, 255, 155), self._spriteWidth, self._spriteHeight)
    self:getView():addChild(self._smallLayer)
    --设置隐藏 移动时才出现
    self._smallLayer:setVisible(false)
    --初始化每个小格子 用于标志是否上面存在头像
    self._mt = {}          
    for i = 1, 10 do
        self._mt[i] = {}   
        for j = 1, 6 do
            self._mt[i][j] = 0
        end
    end
    -- 我方英雄
    self._battle = options
    -- 总共4个英雄
    self.heroNum = 4
    -- 每个英雄头像的touch事件，都一样
    self._onTouchs = {QUIDialogAdjust._onTouch1, QUIDialogAdjust._onTouch2, QUIDialogAdjust._onTouch3, QUIDialogAdjust._onTouch4}
    self._small = {false, false, false, false}
    self.heroFrame = {}
    for i = 1, 4 do
        self.heroFrame[i] = CCNode:create()
        --英雄头像所在网格i,j位置,和是否在中心的center标志 还有该英雄的id
        self.heroFrame[i].center = false
        self.heroFrame[i].i = -1
        self.heroFrame[i].j = -1
        self.heroFrame[i].id = ""
        self:getView():addChild(self.heroFrame[i])
    end
    --添加hero头像到sprite上
    self:addHeroSprite()
 

end

function QUIDialogAdjust:viewDidAppear()
    QUIDialogAdjust.super.viewDidAppear(self)
    self._remoteProxy = cc.EventProxy.new(remote)

  
    if self.heroNum > 4 then
        self.heroNum = 4
    end
    for i = 1, self.heroNum  do
        
        local point = self._ccbOwner["node_adjustslot"]:convertToWorldSpace(self._ccbOwner["node_hero"..i]:getPositionInCCPoint())
        local w = 156
        local h = 156
        self.heroFrame[i]:setPositionX(point.x - w/2)
        self.heroFrame[i]:setPositionY(point.y)

        self.heroFrame[i]:setTouchEnabled(true)
        self.heroFrame[i]:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
        self.heroFrame[i]:setTouchSwallowEnabled(false)
        self.heroFrame[i]:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self._onTouchs[i]))
    end
    --获取原来英雄阵容
    if remote.user.arenaAttackFormation and #remote.user.arenaAttackFormation ~= 0  then
        --阵容在服务端以json形式存储
        self._formation = json.decode(remote.user.arenaAttackFormation)
        for _, vf in pairs(self._formation) do
            for i = 1, self.heroNum do
                --还原对应英雄id 所在的格子位置
                if vf.id == self.heroFrame[i].id then
                    self.heroFrame[i].i = vf.i
                    self.heroFrame[i].j = vf.j
                    self.heroFrame[i].center = vf.c
                    self:setSpritePosition(self.heroFrame[i], self.heroFrame[i].i,
                     self.heroFrame[i].j, self.heroFrame[i].center)
                    
                    --如果是在正中间 center == true，i,j为4个小格组成的正方形大格子的右上角i,j
                    local ti,tj = self:makeQuadTopRightIJ(vf.i, vf.j)
                    if ti == vf.i and tj == vf.j and vf.c == true then
                        --把4个小格子都设置成被占用状态
                        self:setBigBox(ti, tj, true)
                    else
                        self._mt[vf.i][vf.j] = 1
                    end

                end 
                
            end
        end
        --如果原阵容不满4个，现在上场的英雄多余原阵容,或者是英雄id不同导致 把新英雄默认放一个位置从右上角开始
        local si = 9
        for i = 1, self.heroNum do
            if self.heroFrame[i].i == -1 then
                self.heroFrame[i].i = si
                self.heroFrame[i].j = 5
                self.heroFrame[i].center = false
                self:setSpritePosition(self.heroFrame[i], self.heroFrame[i].i,
                     self.heroFrame[i].j, self.heroFrame[i].center)
                self._mt[si][5] = 1
                si = si - 2
            end
        end
        return
    end
    --优先摆放的策略, 分别为,格子i,j,主要是治疗的位置要放后面
    local strategy_i = {4, 4, 4, 2}
    local strategy_j = {4, 6, 2, 4}
    for i = 1, self.heroNum  do
                
        self.heroFrame[i].center = true
        if self.heroFrame[i].func then
            if self.heroFrame[i].func == "health" then
                local ti = strategy_i[i]
                local tj = strategy_j[i]
                strategy_i[i] = strategy_i[4]
                strategy_j[i] = strategy_j[4]

                strategy_i[4] = ti
                strategy_j[4] = tj
            end
        else
                local ti = strategy_i[i]
                local tj = strategy_j[i]
                strategy_i[i] = strategy_i[4]
                strategy_j[i] = strategy_j[4]

                strategy_i[4] = ti
                strategy_j[4] = tj
                
        end

        self:setBigBox(strategy_i[i], strategy_j[i], 1)
        self:setSpritePosition(self.heroFrame[i], strategy_i[i], strategy_j[i], true)
    end

end

function QUIDialogAdjust:viewWillDisappear()
    QUIDialogAdjust.super.viewWillDisappear(self)
    self._remoteProxy:removeAllEventListeners()

    for i = 1, self.heroNum do
        self.heroFrame[i]:setTouchEnabled(false)
        self.heroFrame[i]:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
    end
end

function QUIDialogAdjust:makeQuadTopRightIJ(i, j)
    --传入的ij为1个大格子中某小格的ij,返回的i,j为4个小格组成的正方形大格子的右上角i,j
    if i % 2 == 1 then
        i = i + 1
    end
    if j % 2 == 1 then
        j = j + 1
    end
    return i, j
end

function QUIDialogAdjust:setBigBox(i, j, value)
    i, j = self:makeQuadTopRightIJ(i, j)
    self._mt[i][j] = value
    self._mt[i-1][j] = value
    self._mt[i][j-1] = value
    self._mt[i-1][j-1] = value
end

function QUIDialogAdjust:adjustFramePos(num, ini, inj)
    --当一个英雄头像摆放在一个大格子上时，再放入另一个英雄头像时，这两个头像放在4小格子其中2个的策略
    for k = 1, self.heroNum do
        local time = 1
        local strategy_i = {-1, -1, 0}
        local strategy_j = {-1, 0, -1}
        if num ~= k then
            local i = self.heroFrame[k].i
            local j = self.heroFrame[k].j
            i,j = self:makeQuadTopRightIJ(i, j)
            if ini == i and inj == j and self.heroFrame[k].center == true then
                self._mt[i][j] = 0
                self._mt[i-1][j] = 0
                self._mt[i][j-1] = 0
                self._mt[i-1][j-1] = 0
                self.heroFrame[k].center = false
                self.heroFrame[k].i = i + strategy_i[time]
                self.heroFrame[k].j = j + strategy_j[time]

                self:setSpritePosition(self.heroFrame[k], i + strategy_i[time], j + strategy_j[time], false)
                self._mt[i + strategy_i[time]][j + strategy_j[time]] = 1
                self:setSpritePosition(self.heroFrame[num], i, j, false)
                self._mt[i][j] = 1
                time = time + 1
            end
        end
    end
end

function QUIDialogAdjust:afterMoveAdjust(num, oi, oj, ni, nj)
    --大格中有2个位置(或以上)被占时，其中一个移走时的调整
    local time = 0
    local id = 0
    for k = 1, self.heroNum do
        if k ~= num then
            local i = 0
            local j = 0
            i,j = self:makeQuadTopRightIJ(self.heroFrame[k].i, self.heroFrame[k].j)
            if i == oi and j == oj then
                if ni ~= oi or nj ~= oj then
                    time = time + 1
                    id = k
                end
            end
        end
    end
    if time == 1 then
        self:setSpritePosition(self.heroFrame[id], oi, oj, true)
        self.heroFrame[id].i = oi
        self.heroFrame[id].j = oj
        self.heroFrame[id].center = true
    end
end

function QUIDialogAdjust:_onTouch1(event)
    local id = 1
    if event.name == "began" then
        self._clone = clone(self.heroFrame[id])
        --记录移动时，原位置信息
        self._oi = self.heroFrame[id].i
        self._oj = self.heroFrame[id].j
        self._ocenter = self.heroFrame[id].center
        --如果是中心位置的 先把4个所占位标志清空 ,否则只把原位置标志清空
        if self.heroFrame[id].center == true then
            self:setBigBox(self.heroFrame[id].i, self.heroFrame[id].j, 0)
            self.heroFrame[id].center = false
        else
            self._mt[self.heroFrame[id].i][self.heroFrame[id].j] = 0
        end
        return true

    elseif event.name == "moved" then
        
        self._clone:setPositionX(event.x)
        self._clone:setPositionY(event.y)
        local pt = {x = event.x, y = event.y}
        --通过坐标计算出i,j位置
        local i, j = self:calcuPoint(pt)
        --在边界内移动时 把底层layer显示 出来 并且在相应位置显示
        if i >= 1 and i <= 10 and j >= 1 and j <= 6 then
            self._smallLayer:setVisible(true)
            self:setSpritePosition(self._smallLayer, i, j, true) --锚点 0，0 center true false设置相反
        end
    
    elseif event.name == "ended" or event.name == "cancelled" then
        self._smallLayer:setVisible(false)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        --松开时 如果不再边界内 ，还原移动 直接返回
        if i < 1 or j < 1 then
            self:setSpritePosition(self.heroFrame[id], self._oi, self._oj, self._ocenter)
            self._mt[self._oi][self._oj] = 1
            self.heroFrame[id].center = self._ocenter
            return 
        end
        --处理离开前所在大格的其他英雄头像位置
        local ai, aj = self:makeQuadTopRightIJ(self._oi, self._oj)
        local ni, nj = self:makeQuadTopRightIJ(i, j)
        self:afterMoveAdjust(id, ai, aj, ni, nj)

        --如果在新位置能放在中心位置
        if self:canPosCenter(i, j) then
            i,j = self:makeQuadTopRightIJ(i, j)
            self:setSpritePosition(self._clone, i, j, true)
            self.heroFrame[id].center = true
            self.heroFrame[id].i = i
            self.heroFrame[id].j = j
        else
            --如果不能在新位置能放在中心位置
            local ti ,tj = self:makeQuadTopRightIJ(i, j)
            local should = 0
            for k = 1, self.heroNum do
                --如果所放位置原有占在中心位置的英雄头像
                if self.heroFrame[k].center == true and ti == self.heroFrame[k].i and tj == self.heroFrame[k].j then
                    should = should + 1
                end
            end
            if should > 0 then
                 --如果所放位置原有占在中心位置的英雄头像 调整放下之后2个头像位置
                self:adjustFramePos(id, ti, tj)
            else
                --如果放下后原来位置有头像，则替换两头像位置
                if self._mt[i][j] == 1 then
                    for k = 1, self.heroNum do
                        if k ~= id then
                            if self.heroFrame[k].center == false and i == self.heroFrame[k].i and j == self.heroFrame[k].j then
                                self:setSpritePosition(self.heroFrame[k], self._oi, self._oj, self._ocenter)
                                self.heroFrame[k].center = self._ocenter
                                self.heroFrame[k].i = self._oi
                                self.heroFrame[k].j = self._oj
                                if self._ocenter then 
                                    self:setBigBox(self._oi, self._oj, true)
                                else
                                    self._mt[self._oi][self._oj] = 1
                                end
                            end
                        end
                    end
                else
                end
                --更新放下后frame信息
                self:setSpritePosition(self._clone, i, j, false)
                self.heroFrame[id].center = false
                self.heroFrame[id].i = i
                self.heroFrame[id].j = j
                self._mt[i][j] = 1
            end
        end
    end
end
--同touch1
function QUIDialogAdjust:_onTouch2(event)
    local id = 2
    if event.name == "began" then
        self._clone = clone(self.heroFrame[id])
        
        self._oi = self.heroFrame[id].i
        self._oj = self.heroFrame[id].j
        self._ocenter = self.heroFrame[id].center
        if self.heroFrame[id].center == true then
            self:setBigBox(self.heroFrame[id].i, self.heroFrame[id].j, 0)
            self.heroFrame[id].center = false
        else
            self._mt[self.heroFrame[id].i][self.heroFrame[id].j] = 0
        end
        
        return true

    elseif event.name == "moved" then
       
        self._clone:setPositionX(event.x)
        self._clone:setPositionY(event.y)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i >= 1 and i <= 10 and j >= 1 and j <= 6 then
            self._smallLayer:setVisible(true)
            self:setSpritePosition(self._smallLayer, i, j, true) --锚点 0，0 center true false设置相反
        end
    
    elseif event.name == "ended" or event.name == "cancelled" then
        self._smallLayer:setVisible(false)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i < 1 or j < 1 then
            self:setSpritePosition(self.heroFrame[id], self._oi, self._oj, self._ocenter)
            self._mt[self._oi][self._oj] = 1
            self.heroFrame[id].center = self._ocenter
            return 
        end
        
        local ai, aj = self:makeQuadTopRightIJ(self._oi, self._oj)
        local ni, nj = self:makeQuadTopRightIJ(i, j)
        self:afterMoveAdjust(id, ai, aj, ni, nj)

        if self:canPosCenter(i, j) then
            i,j = self:makeQuadTopRightIJ(i, j)
            self:setSpritePosition(self._clone, i, j, true)
            self.heroFrame[id].center = true
            self.heroFrame[id].i = i
            self.heroFrame[id].j = j
        else
            local ti ,tj = self:makeQuadTopRightIJ(i, j)
            local should = 0
            for k = 1, self.heroNum do
                if self.heroFrame[k].center == true and ti == self.heroFrame[k].i and tj == self.heroFrame[k].j then
                    should = should + 1
                end
            end
            if should > 0 then
                self:adjustFramePos(id, ti, tj)
            else
                if self._mt[i][j] == 1 then
                    for k = 1, self.heroNum do
                        if k ~= id then
                            if self.heroFrame[k].center == false and i == self.heroFrame[k].i and j == self.heroFrame[k].j then
                                self:setSpritePosition(self.heroFrame[k], self._oi, self._oj, self._ocenter)
                                self.heroFrame[k].center = self._ocenter
                                self.heroFrame[k].i = self._oi
                                self.heroFrame[k].j = self._oj
                                if self._ocenter then 
                                    self:setBigBox(self._oi, self._oj, true)
                                else
                                    self._mt[self._oi][self._oj] = 1
                                end
                            end
                        end
                    end
                else
                end
                self:setSpritePosition(self._clone, i, j, false)
                self.heroFrame[id].center = false
                self.heroFrame[id].i = i
                self.heroFrame[id].j = j
                self._mt[i][j] = 1
            end
        end
    end
end
--同touch1
function QUIDialogAdjust:_onTouch3(event)
    local id = 3
    if event.name == "began" then
        self._clone = clone(self.heroFrame[id])
        
        self._oi = self.heroFrame[id].i
        self._oj = self.heroFrame[id].j
        self._ocenter = self.heroFrame[id].center
        if self.heroFrame[id].center == true then
            self:setBigBox(self.heroFrame[id].i, self.heroFrame[id].j, 0)
            self.heroFrame[id].center = false
        else
            self._mt[self.heroFrame[id].i][self.heroFrame[id].j] = 0
        end
        
        return true

    elseif event.name == "moved" then
        
        self._clone:setPositionX(event.x)
        self._clone:setPositionY(event.y)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i >= 1 and i <= 10 and j >= 1 and j <= 6 then
            self._smallLayer:setVisible(true)
            self:setSpritePosition(self._smallLayer, i, j, true) --锚点 0，0 center true false设置相反
        else
            self._smallLayer:setVisible(false)
        end
    
    elseif event.name == "ended" or event.name == "cancelled" then
        self._smallLayer:setVisible(false)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i < 1 or j < 1 then
            self:setSpritePosition(self.heroFrame[id], self._oi, self._oj, self._ocenter)
            self._mt[self._oi][self._oj] = 1
            self.heroFrame[id].center = self._ocenter
            return 
        end

        local ai, aj = self:makeQuadTopRightIJ(self._oi, self._oj)
        local ni, nj = self:makeQuadTopRightIJ(i, j)
        self:afterMoveAdjust(id, ai, aj, ni, nj)

        if self:canPosCenter(i, j) then
            i,j = self:makeQuadTopRightIJ(i, j)
            self:setSpritePosition(self._clone, i, j, true)
            self.heroFrame[id].center = true
            self.heroFrame[id].i = i
            self.heroFrame[id].j = j
        else
            local ti ,tj = self:makeQuadTopRightIJ(i, j)
            local should = 0
            for k = 1, self.heroNum do
                if self.heroFrame[k].center == true and ti == self.heroFrame[k].i and tj == self.heroFrame[k].j then
                    should = should + 1
                end
            end
            if should > 0 then
                self:adjustFramePos(id, ti, tj)
            else
                if self._mt[i][j] == 1 then
                    for k = 1, self.heroNum do
                        if k ~= id then
                            if self.heroFrame[k].center == false and i == self.heroFrame[k].i and j == self.heroFrame[k].j then
                                self:setSpritePosition(self.heroFrame[k], self._oi, self._oj, self._ocenter)
                                self.heroFrame[k].center = self._ocenter
                                self.heroFrame[k].i = self._oi
                                self.heroFrame[k].j = self._oj
                                if self._ocenter then 
                                    self:setBigBox(self._oi, self._oj, true)
                                else
                                    self._mt[self._oi][self._oj] = 1
                                end
                            end
                        end
                    end
                else
                end
                self:setSpritePosition(self._clone, i, j, false)
                self.heroFrame[id].center = false
                self.heroFrame[id].i = i
                self.heroFrame[id].j = j
                self._mt[i][j] = 1
            end
        end
    end
end
--同touch1
function QUIDialogAdjust:_onTouch4(event)
    local id = 4
    if event.name == "began" then
        self._clone = clone(self.heroFrame[id])
        
        self._oi = self.heroFrame[id].i
        self._oj = self.heroFrame[id].j
        self._ocenter = self.heroFrame[id].center
        if self.heroFrame[id].center == true then
            self:setBigBox(self.heroFrame[id].i, self.heroFrame[id].j, 0)
            self.heroFrame[id].center = false
        else
            self._mt[self.heroFrame[id].i][self.heroFrame[id].j] = 0
        end
        
        return true

    elseif event.name == "moved" then
        
        self._clone:setPositionX(event.x)
        self._clone:setPositionY(event.y)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i >= 1 and i <= 10 and j >= 1 and j <= 6 then
            self._smallLayer:setVisible(true)
            self:setSpritePosition(self._smallLayer, i, j, true) --锚点 0，0 center true false设置相反
        else
            self._smallLayer:setVisible(false)
        end
    
    elseif event.name == "ended" or event.name == "cancelled" then
        self._smallLayer:setVisible(false)
        local pt = {x = event.x, y = event.y}
        local i, j = self:calcuPoint(pt)
        if i < 1 or j < 1 then
            self:setSpritePosition(self.heroFrame[id], self._oi, self._oj, self._ocenter)
            self._mt[self._oi][self._oj] = 1
            self.heroFrame[id].center = self._ocenter
            return 
        end
        
        local ai, aj = self:makeQuadTopRightIJ(self._oi, self._oj)
        local ni, nj = self:makeQuadTopRightIJ(i, j)
        self:afterMoveAdjust(id, ai, aj, ni, nj)

        if self:canPosCenter(i, j) then
            i,j = self:makeQuadTopRightIJ(i, j)
            self:setSpritePosition(self._clone, i, j, true)
            self.heroFrame[id].center = true
            self.heroFrame[id].i = i
            self.heroFrame[id].j = j
        else
            local ti ,tj = self:makeQuadTopRightIJ(i, j)
            local should = 0
            for k = 1, self.heroNum do
                if self.heroFrame[k].center == true and ti == self.heroFrame[k].i and tj == self.heroFrame[k].j then
                    should = should + 1
                end
            end
            if should > 0 then
                self:adjustFramePos(id, ti, tj)
            else
                if self._mt[i][j] == 1 then
                    for k = 1, self.heroNum do
                        if k ~= id then
                            if self.heroFrame[k].center == false and i == self.heroFrame[k].i and j == self.heroFrame[k].j then
                                self:setSpritePosition(self.heroFrame[k], self._oi, self._oj, self._ocenter)
                                self.heroFrame[k].center = self._ocenter
                                self.heroFrame[k].i = self._oi
                                self.heroFrame[k].j = self._oj
                                if self._ocenter then 
                                    self:setBigBox(self._oi, self._oj, true)
                                else
                                    self._mt[self._oi][self._oj] = 1
                                end
                                
                            end
                        end
                    end
                else
                end
                self:setSpritePosition(self._clone, i, j, false)
                self.heroFrame[id].center = false
                self.heroFrame[id].i = i
                self.heroFrame[id].j = j
                self._mt[i][j] = 1
            end
        end
    end
end
function QUIDialogAdjust:onEvent(event)
    if event == nil or event.name == nil then
        return
    end
    -- if event.name == QUIGestureRecognizer.EVENT_SWIPE_GESTURE then
    -- end
end

function QUIDialogAdjust:_onTriggerBack(tag, menuItem)
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)

end

function QUIDialogAdjust:canPosCenter(i, j)
    i,j = self:makeQuadTopRightIJ(i, j)
    if self._mt[i][j] == 0 and self._mt[i - 1][j] == 0 and self._mt[i][j - 1] == 0 and self._mt[i - 1][j - 1] == 0 then
        self._mt[i][j] = 1
        self._mt[i - 1][j] = 1
        self._mt[i][j -1 ] = 1
        self._mt[i - 1][j - 1] = 1
        return true
    else
        return false
    end
end

function QUIDialogAdjust:getIJPosition(i, j, center)
    local bx = (i - 1) * self._spriteWidth 
    local by = (j - 1) * self._spriteHeight 

    if center == false then
        bx = (bx + self._spriteWidth/2)
        by = (by + self._spriteHeight/2)
    end
    return bx, by
end

function QUIDialogAdjust:setSpritePosition(sprite, i, j, center)
    local bx = (i - 1) * self._spriteWidth + self._beginPoint.x
    local by = (j - 1) * self._spriteHeight + self._beginPoint.y

    if center == true then
        sprite:setPositionX(bx )
        sprite:setPositionY(by )
        sprite.i = i
        sprite.j = j
    else
        sprite:setPositionX(bx + self._spriteWidth/2)
        sprite:setPositionY(by + self._spriteHeight/2)
        sprite.i = i
        sprite.j = j
    end
end

function QUIDialogAdjust:calcuPoint(pt)
    if pt.x >= self._beginPoint.x and pt.x <= self._endPoint.x and
        pt.y >= self._beginPoint.y and pt.y <= self._endPoint.y then
        local i = math.ceil((pt.x - self._beginPoint.x) / self._spriteWidth)
        local j = math.ceil((pt.y - self._beginPoint.y) / self._spriteHeight)
        return i, j
    else
        return -1, -1
    end
end

function QUIDialogAdjust:_onAdjustCrew(tag, menuItem)
     self._formation = {}
    for i = 1, 4 do
        self._formation[i]=  {id = self.heroFrame[i].id , i = self.heroFrame[i].i, j = self.heroFrame[i].j, c = self.heroFrame[i].center}
    end
    --上传阵容
    app:getClient():pvpPkFormationAttack(self._formation, function() 
        app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, uiClass="QUIDialogTeamArrangement"})
        end)
end

function QUIDialogAdjust:_onChallenge(tag, menuItem)
    --上传我方阵容
    self._formation = {}
    local mineformation = {}
    for i = 1, self.heroNum do
        self._formation[i]=  {id = self.heroFrame[i].id , i = self.heroFrame[i].i, j = self.heroFrame[i].j, c = self.heroFrame[i].center}
        local mx, my = self:getIJPosition(self.heroFrame[i].i, self.heroFrame[i].j, self.heroFrame[i].center)
        mineformation[i] = {x = mx, y = my}
    end
    app:getClient():pvpPkFormationAttack(self._formation, function() 
       end)


    --获取对方阵容 当对方阵容为空时 一种帮对方英雄安排位置的策略
    local strategy_i = {4, 4, 4, 2}
    local strategy_j = {4, 6, 2, 4}

    local formation = json.decode(self._battle.user.arenaAttackFormation)
    if formation == nil then
        formation = {}
    end
    QStaticDatabase:sharedDatabase():clearMonstersById("ArenaPVP")
    for i, v in pairs(self._battle.heros) do
        if formation[i] == nil then
            formation[i] = {i = strategy_i[i], j = strategy_j[i], true}
        end
        -- bx by, 获取的与i,j中心对称的,i,j的位置（相对于beginPoint)
        local bx , by = self:getIJPosition(10 - formation[i].i + 1, formation[i].j, formation.center)
        QStaticDatabase:sharedDatabase():insertMonster("ArenaPVP", {
        wave = 1, appear = 0, x = bx, y = by, npc_id = v, is_boss = false}) --npc_id 是heroInfo
        
    end
    app:getNavigationController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    app:getNavigationController():pushViewController({uiType = QUIViewController.TYPE_PAGE, uiClass = "QUIPageLoadResources", 
        options = {dungeon = {monster_id = "ArenaPVP", isArena = true, heroPosition = mineformation, type = 1, difficulty = 1,
        money = 0, team_exp = 0, energy = 6, drop_index = 1, duration = 180, icon = "icon/head/ectoplasm.png", 
        scene = "ccb/Battle_Scene.ccbi", bg = "map/wailing_caverns01.png", bgm = "audio/bgm/battle_bgm.mp3"
        }}})
    app:getNavigationController():getTopPage():loadBattleResources()

    --上传战报
    remote.battleAim = self._battle

end

function QUIDialogAdjust:addHeroSprite()
    self.heroNum = 0
    if 0 ~= #remote.teams then
        for _, heroId in ipairs(remote.teams[1]:getTeams()) do
            local hero = remote.herosUtil:getHeroByID(heroId)
            if nil ~= hero then
                local character = QStaticDatabase:sharedDatabase():getCharacterByID(hero.actorId)
                local heroInfo = QStaticDatabase:sharedDatabase():getCharacterByID(hero.actorId)
                if nil ~= heroInfo then
                    local heroTalent = QStaticDatabase:sharedDatabase():getTalentByID(heroInfo.talent)
                    if nil ~= heroTalent then
                        self.heroFrame[self.heroNum + 1].func = heroTalent.func
                    end
                end

                if character ~= nil then
                    local characterDisplay = QStaticDatabase:sharedDatabase():getCharacterDisplayByID(character.display_id)
                    if characterDisplay ~= nil then
                        local resPath = characterDisplay.icon
                        local texture = CCTextureCache:sharedTextureCache():addImage(resPath)
                        local sprite = CCSprite:createWithTexture(texture)
                        local addsprite = self._ccbOwner["node_hero"..(self.heroNum + 1)]:getChildByTag(100)
                        if addsprite then
                            addsprite:removeFromParent()
                            addsprite = nil
                        end
                        self._ccbOwner["node_hero"..(self.heroNum + 1)]:addChild(sprite, 1, 100)

                        local s2 = CCSprite:createWithTexture(texture)
                        s2:setScale(.5)
                        self.heroFrame[self.heroNum + 1]:addChild(s2)
                        self.heroFrame[self.heroNum + 1].id = hero.actorId
                        self.heroNum = self.heroNum + 1

                        

                    end
                end
            end
        end
    end
end

return QUIDialogAdjust