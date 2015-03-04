
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetHeroSkillUpgrade = class("QUIWidgetHeroSkillUpgrade", QUIWidget)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroSkillCell = import("..widgets.QUIWidgetHeroSkillCell")
local QUIGestureRecognizer = import("..QUIGestureRecognizer")
local QRemote = import("...models.QRemote")
local QVIPUtil = import("...utils.QVIPUtil")

function QUIWidgetHeroSkillUpgrade:ctor(options)
	local ccbFile = "ccb/Widget_HeroSkillUpgrade.ccbi"
	local callBacks = {{ccbCallbackName = "onTriggerBuy", callback = handler(self, QUIWidgetHeroSkillUpgrade._onTriggerBuy)}}
	QUIWidgetHeroSkillUpgrade.super.ctor(self, ccbFile, callBacks, options)

    self._totleHeight = 0
    self._offsetY = -55

    self._pageWidth = self._ccbOwner.node_mask:getContentSize().width
    self._pageHeight = self._ccbOwner.node_mask:getContentSize().height
    self._pageContent = self._ccbOwner.node_contain
    self._orginalPosition = ccp(self._pageContent:getPosition())

    local layerColor = CCLayerColor:create(ccc4(255,0,0,150),self._pageWidth,self._pageHeight)
    local ccclippingNode = CCClippingNode:create()
    layerColor:setPositionX(self._ccbOwner.node_mask:getPositionX())
    layerColor:setPositionY(self._ccbOwner.node_mask:getPositionY())
    ccclippingNode:setStencil(layerColor)
    self._pageContent:removeFromParent()
    ccclippingNode:addChild(self._pageContent)

    self._ccbOwner.node_mask:getParent():addChild(ccclippingNode)
    
    self._touchLayer = QUIGestureRecognizer.new()
    self._touchLayer:attachToNode(self._ccbOwner.node_mask:getParent(),self._pageWidth, self._pageHeight, self._pageWidth/2-50, 
    0, handler(self, self.onTouchEvent))

    self._ccbOwner.node_normal:setVisible(false)
    self._ccbOwner.node_buy:setVisible(false)
    self._ccbOwner.scroll_bar:setOpacity(0)
    self._ccbOwner.scroll_sm:setOpacity(0)
    self._ccbOwner.node_shadow_bottom:setVisible(true)
    self._ccbOwner.node_shadow_top:setVisible(false)
    self:scrollAutoLayout()
    self:showPointAndTime()
    self:setSkillCurrency()
end

function QUIWidgetHeroSkillUpgrade:onEnter()
    self._touchLayer:enable()
    self._touchLayer:addEventListener(QUIGestureRecognizer.EVENT_SLIDE_GESTURE, handler(self, self.onTouchEvent))
    self.prompt = app:promptTips()
    self.prompt:addSkillEventListener()

    self._remoteProxy = cc.EventProxy.new(remote)
    self._remoteProxy:addEventListener(QRemote.HERO_UPDATE_EVENT, handler(self, self.onEvent)) 
    
    self._itemEventProxy = cc.EventProxy.new(remote)
    self._itemEventProxy:addEventListener(QRemote.ITEMS_UPDATE_EVENT, handler(self, self.setSkillCurrency))
end

function QUIWidgetHeroSkillUpgrade:onExit()
    self._touchLayer:removeAllEventListeners()
    self._touchLayer:disable()
    self._touchLayer:detach()
    self._remoteProxy:removeAllEventListeners()
    self._itemEventProxy:removeAllEventListeners()
    self.prompt:removeSkillEventListener()
    
    if self._timeHandler ~= nil then
        scheduler.unscheduleGlobal(self._timeHandler)
    end
    self:removeSkillCell()
end

-- 处理各种touch event
function QUIWidgetHeroSkillUpgrade:onTouchEvent(event)
    if event == nil or event.name == nil then
        return
    end
    if self._totleHeight <= self._pageHeight then
        return 
    end
    if event.name == QUIGestureRecognizer.EVENT_SLIDE_GESTURE then
        -- self._page:endMove(event.distance.y)
    elseif event.name == "began" then
        self._startY = event.y
        self._pageY = self._pageContent:getPositionY()
    elseif event.name == "moved" then
        if math.abs(event.y - self._startY) < 5 then return end
        local offsetY = self._pageY + event.y - self._startY
        if offsetY < self._orginalPosition.y then
            self._ccbOwner.node_shadow_bottom:setVisible(true)
            self._ccbOwner.node_shadow_top:setVisible(false)
            offsetY = self._orginalPosition.y
        elseif offsetY > (self._totleHeight - self._pageHeight + self._orginalPosition.y) then
            offsetY = (self._totleHeight - self._pageHeight + self._orginalPosition.y)
            self._ccbOwner.node_shadow_bottom:setVisible(false)
            self._ccbOwner.node_shadow_top:setVisible(true)
        else
        self._ccbOwner.node_shadow_bottom:setVisible(true)
        self._ccbOwner.node_shadow_top:setVisible(true)
        end
        self._pageContent:setPositionY(offsetY)
        self:showScroll()
    elseif event.name == "ended" then
    end
end

function QUIWidgetHeroSkillUpgrade:onEvent(event)
    self:showPointAndTime()
    self:updateHero()
end

function QUIWidgetHeroSkillUpgrade:showScroll()
    if self._handler ~= nil then
        scheduler.unscheduleGlobal(self._handler)
    end
    self._handler = scheduler.performWithDelayGlobal(function()
            self._ccbOwner.scroll_bar:runAction(CCFadeOut:create(0.3))
            self._ccbOwner.scroll_sm:runAction(CCFadeOut:create(0.3))
            -- self._ccbOwner.node_scroll:setVisible(false)
            scheduler.unscheduleGlobal(self._handler)
            self._handler = nil
        end,0.5)
      self._ccbOwner.scroll_bar:setOpacity(255)
      self._ccbOwner.scroll_sm:setOpacity(255)
    self:scrollAutoLayout()
end

function QUIWidgetHeroSkillUpgrade:scrollAutoLayout()
    local totalHeight = self._ccbOwner.scroll_bar:getContentSize().height
    local smHeight = self._ccbOwner.scroll_sm:getContentSize().height
    local rate = (self._pageContent:getPositionY() - self._orginalPosition.y)/(self._totleHeight - self._pageHeight)
    self._ccbOwner.scroll_sm:setPositionY(rate * (totalHeight - smHeight) + self._ccbOwner.scroll_bar:getPositionY() + smHeight/2)
end

function QUIWidgetHeroSkillUpgrade:updateHero()
    local heroInfo = remote.herosUtil:getHeroByID(self._actorId)
    if self._heroInfo == nil then return end

    if #heroInfo.skills ~= #self._heroInfo.skills or (heroInfo.level ~= self._heroInfo.level) then
        self:setHero(self._actorId)
    end
end

function QUIWidgetHeroSkillUpgrade:setHero(actorId)
    self._actorId = actorId
    self._heroInfo = clone(remote.herosUtil:getHeroByID(actorId))
    self:removeSkillCell()
    self._pageContent:removeAllChildren()
    self._pageContent:setPosition(self._orginalPosition.x, self._orginalPosition.y)
    self._totleHeight = 0
    local breakthroughConfig = QStaticDatabase:sharedDatabase():getBreakthroughHeroByActorId(self._actorId)
    if breakthroughConfig ~= nil then
        for _,value in pairs(breakthroughConfig) do
            self:addSkill(value.skills)
        end
    end
end

function QUIWidgetHeroSkillUpgrade:removeSkillCell()
    if self.skillCell ~= nil then
        for _,cell in pairs(self.skillCell) do
            cell:removeAllEventListeners()
        end
    end
    self.skillCell = {}
end

function QUIWidgetHeroSkillUpgrade:addSkill(skillName)
    if skillName ~= nil and skillName ~= "" then
        local _skillCell = QUIWidgetHeroSkillCell.new({skillName = skillName, actorId = self._actorId, content = self})
        _skillCell:addEventListener(QUIWidgetHeroSkillCell.EVENT_BUY, handler(self, self.buySkillPointHandler))
        _skillCell:setPositionY(-self._totleHeight + self._offsetY)
        self._pageContent:addChild(_skillCell)
        self._totleHeight = self._totleHeight + _skillCell:getHeight()
        table.insert(self.skillCell, _skillCell)
    end
end

function QUIWidgetHeroSkillUpgrade:setText(name, text)
    if self._ccbOwner[name] then
        self._ccbOwner[name]:setString(text)
    end
end

-- TODO: max skill point might be 20 after certain level
function QUIWidgetHeroSkillUpgrade:showPointAndTime()
    if self._timeHandler ~= nil then
        scheduler.unscheduleGlobal(self._timeHandler)
    end
    local point, lastTime = remote.herosUtil:getSkillPointAndTime()
    self._ccbOwner.tf_point_num:setString(point)
    if point > 0 then
        self._ccbOwner.node_normal:setVisible(true)
        self._ccbOwner.node_buy:setVisible(false)
    else
        self._ccbOwner.node_normal:setVisible(false)
        self._ccbOwner.node_buy:setVisible(true)
        self._ccbOwner.btn_buy:setEnabled(true)
    end
    if point >= 10 then
        self._ccbOwner.tf_time:setString("")
    else
        self._ccbOwner.tf_time:setString(string.format("(%.2d:%.2d)", math.floor(lastTime / 60.0), math.floor(lastTime % 60.0)))
        self._ccbOwner.tf_time_other:setString(string.format("%.2d:%.2d", math.floor(lastTime / 60.0), math.floor(lastTime % 60.0)))
        self._timeHandler = scheduler.performWithDelayGlobal(handler(self, self.showPointAndTime),1)
    end
end

function QUIWidgetHeroSkillUpgrade:setSkillCurrency()
  self._ccbOwner.tf_money:setString(remote.items:getItemsNumByID(12) or 0)
end

function QUIWidgetHeroSkillUpgrade:_onTriggerBuy()
    self:buySkillPointHandler()
end

function QUIWidgetHeroSkillUpgrade:buySkillPointHandler()
    local config = remote.user:getSkillTicketConfig()

    if not QVIPUtil:canBuySkillPoint() then
        local unlockLevel = QVIPUtil:getBuySkillPointUnlockLevel()
        app.tip:floatTip("达成VIP"..unlockLevel.."时解锁")
    else
        local skillPoint = QVIPUtil:getSkillPointCount()
        app:alert({content="购买"..skillPoint.."点技能点需花费"..config.token_cost.."符石\n是否继续？(今日已购买"..remote.user.skillTicketsReset.."次)", title="系统提示", comfirmBack = function()
                        self._ccbOwner.btn_buy:setEnabled(false)
                        app:getClient():buySkillTicket(function ()
                            remote.user:addPropNumForKey("skillTicketsReset")
                        end)
                    end, callBack = function ()
                end}, false)
    end
end

return QUIWidgetHeroSkillUpgrade