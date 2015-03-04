
local QNpcTipIcon = class("QNpcTipIcon", function()
    return display.newNode()
end)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QNpcTipDialog = import(".QNpcTipDialog")

function QNpcTipIcon:ctor(displayID)
    local info = QStaticDatabase.sharedDatabase():getCharacterDisplayByID(displayID)
    assert(info ~= nil)

    self._displayID = displayID
    self._name = info.name

    local proxy = CCBProxy:create()
    self._owner = {} 
    self._owner["onClick"] = handler(self, QNpcTipIcon.onClick)

    local node = CCBuilderReaderLoad("ccb/Battle_Widget_NewEnemy.ccbi", proxy, self._owner)
    self._ccbProxy = proxy;
    self:addChild(node)

    self:addChild(CCSprite:create(info.icon))
end

function QNpcTipIcon:getDisplayID()
    return self._displayID
end

function QNpcTipIcon:getName()
    return self._name
end

function QNpcTipIcon:setClickThisVisible(visible)
    self._owner.clickThis:setVisible(visible)
end

function QNpcTipIcon:onClick()
    local dlg = QNpcTipDialog.new(self:getName())
    dlg.onOK = function()
        printInfo("TBD: set don't show this NPC tip again.")
    end
end

return QNpcTipIcon