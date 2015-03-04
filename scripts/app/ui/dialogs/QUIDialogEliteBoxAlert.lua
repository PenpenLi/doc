--
-- Author: wkwang
-- Date: 2014-07-28 19:39:30
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogEliteBoxAlert = class("QUIDialogEliteBoxAlert", QUIDialog)

local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")
local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNavigationController = import("...controllers.QNavigationController")

QUIDialogEliteBoxAlert.EVENT_GET_SUCC = "EVENT_GET_SUCC"

function QUIDialogEliteBoxAlert:ctor(options)
	local ccbFile = "ccb/Dialog_ChestAward.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerCancel", callback = handler(self, QUIDialogEliteBoxAlert._onTriggerCancel)},
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogEliteBoxAlert._onTriggerConfirm)},
        {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogEliteBoxAlert._onTriggerClose)},
    }
    QUIDialogEliteBoxAlert.super.ctor(self, ccbFile, callBacks, options)

	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()

    self.isAnimation = true

	self._ccbOwner.btn_ok:setVisible(false)
	self._ccbOwner.btn_cancel:setVisible(false)
	self._ccbOwner.btn_close:setVisible(false)

	self._items = {}
	-- for i=1,4,1 do
	-- 	table.insert(self._items, QUIWidgetItemsBox.new())
	-- 	self._ccbOwner["node_goods"..i]:addChild(self._items[i])
	-- 	self._items[i]:resetAll()
	-- 	self._items[i]:setVisible(false)
	-- end

	if options ~= nil then

	    if options.instance_id ~= nil and options.index ~= nil then
	    	self._instance_id = options.instance_id
	    	self._index = options.index
	    	local mapBoxDropConfig = QStaticDatabase:sharedDatabase():getMapAchievement(self._instance_id)
			if options.starNum ~= nil and options.starNum >= tonumber(mapBoxDropConfig["box"..self._index]) and options.isGet ~= true then
				self._ccbOwner.btn_ok:setVisible(true)
				self._ccbOwner.btn_cancel:setVisible(true)
			else
				self._ccbOwner.btn_close:setVisible(true)
			end
	    	self._ccbOwner.tf_num:setString(mapBoxDropConfig["box"..self._index])
	    	local config = QStaticDatabase:sharedDatabase():getLuckyDraw(mapBoxDropConfig["index"..self._index])
	    	if config ~= nil then
	    		local i = 1
	    		while true do
	    			if config["type_"..i] ~= nil and i <= 4 then
	    				self._items[i] = QUIWidgetItemsBox.new()
	    				self._items[i]:setPositionX((i-1) * 140 + 70)
	    				self._ccbOwner.node_goods:addChild(self._items[i])
	    				self._items[i]:setGoodsInfo(config["id_"..i],config["type_"..i],config["num_"..i])
	    				i = i + 1
	    			else
	    				break
	    			end
	    		end
	    		self._ccbOwner.node_goods:setPositionX(-(#self._items * 140)/2)
	    	end
	    end
	end
end

function QUIDialogEliteBoxAlert:_backClickHandler()
    self:_close()
end

function QUIDialogEliteBoxAlert:_onTriggerCancel()
	app.sound:playSound("common_cancel")
    self:_close()
end

function QUIDialogEliteBoxAlert:_onTriggerClose()
	app.sound:playSound("common_cancel")
    self:_close()
end

function QUIDialogEliteBoxAlert:_close()
    self:playEffectOut()
end

function QUIDialogEliteBoxAlert:viewAnimationOutHandler()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
end

function QUIDialogEliteBoxAlert:_onTriggerConfirm()
	app.sound:playSound("common_confirm")
    app:getClient():luckyDrawMap(self._instance_id,self._index,function(data)
    		self:_onTriggerClose()
    		self:dispatchEvent({name = QUIDialogEliteBoxAlert.EVENT_GET_SUCC,data = data})
        end,nil)
end

return QUIDialogEliteBoxAlert