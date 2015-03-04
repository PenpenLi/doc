
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetTutorialHandTouch = class("QUIWidgetTutorialHandTouch", QUIWidget)

function QUIWidgetTutorialHandTouch:ctor(options)
  local ccbFile = nil
  if options.direction == nil or options.direction == "up" or options.direction == "down" then
    if options.word2 or type(options.word) == "number" then
      ccbFile = "ccb/Widget_NewBuilding_open4.ccbi"
    else
      ccbFile = "ccb/Widget_NewBuilding_open.ccbi"
    end
	elseif options.direction == "right" then
     ccbFile = "ccb/Widget_NewBuilding_open2.ccbi"
  elseif  options.direction == "left" then
     ccbFile = "ccb/Widget_NewBuilding_open3.ccbi"
	end
	local callbacks = {}
	QUIWidgetTutorialHandTouch.super.ctor(self, ccbFile, callbacks, options)
--	self._ccbOwner.tf_tips1:setVisible(false)
--	self._ccbOwner.tf_tips1:setPosition(75,72)
	
	if options.word ~= nil then
	 self._word = options.word
	end
  if options.word2 ~= nil then
    self._word2 = options.word2
  end
  if self._word2 then
    self._ccbOwner.word3:setString(self._word)
    self._ccbOwner.word4:setString(self._word2)
    self._ccbOwner.word5:getParent():setVisible(false)
    self._ccbOwner.word7:getParent():setVisible(false)
  else
    if type(self._word) == "number" then
      self._ccbOwner.word1:getParent():setVisible(self._word == 1)
      self._ccbOwner.word3:getParent():setVisible(self._word ~= 1)
      self._ccbOwner.word5:getParent():setVisible(false)
      self._ccbOwner.word7:getParent():setVisible(false)
    else
      if self._word == nil then self._word = "" end
      self._ccbOwner.word:setString(self._word)
    end
  end
  
  if options.direction == "down" then
    self:getView():setScaleY(-1)
    self._ccbOwner.word:setScaleY(-1)
  end
  
  if options.type == nil then
    self._ccbOwner.controller_btn:setVisible(false)
  end
	
end

function QUIWidgetTutorialHandTouch:setHandTouch(word, direction)
  self._ccbOwner.word:setString(word or "")
  if direction == "right" or direction == "up" then
    self:getView():setScaleX(1)
  elseif direction == "left" or direction == "down" then
    self:getView():setScaleX(-1)
  end
end

--function QUIWidgetTutorialHandTouch:tipsLeftUp()
--    self._ccbOwner.tf_tips:setPosition(-75,72)
--end
--
--function QUIWidgetTutorialHandTouch:tipsLeftDown()
--    self._ccbOwner.tf_tips:setPosition(-75,-72)
--end
--
--function QUIWidgetTutorialHandTouch:tipsRightUp()
--    self._ccbOwner.tf_tips:setPosition(75,72)
--end
--
--function QUIWidgetTutorialHandTouch:tipsRightDown()
--    self._ccbOwner.tf_tips:setPosition(75,-72)
--end
--
--function QUIWidgetTutorialHandTouch:handLeftUp()
--    self._ccbOwner.node_hands:setRotation(180)
--end
--
--function QUIWidgetTutorialHandTouch:handLeftDown()
--    self._ccbOwner.node_hands:setRotation(90)
--end
--
--function QUIWidgetTutorialHandTouch:handRightUp()
--    self._ccbOwner.node_hands:setRotation(270)
--end
--
--function QUIWidgetTutorialHandTouch:handRightDown()
--    self._ccbOwner.node_hands:setRotation(0)
--end
--
--function QUIWidgetTutorialHandTouch:tipsClickHere()
--  self._ccbOwner.tf_tips:setVisible(true)
--  self._ccbOwner.tf_tips1:setVisible(false)
--end
--
--function QUIWidgetTutorialHandTouch:tipsClickBack()
--  self._ccbOwner.tf_tips:setVisible(false)
--  self._ccbOwner.tf_tips1:setVisible(true)
--end
return QUIWidgetTutorialHandTouch