
local QBattleDialog = import(".QBattleDialog")
local QNpcTipDialog = class("QNpcTipDialog", QBattleDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")

function QNpcTipDialog:ctor(name)
    local owner = {}
    QNpcTipDialog.super.ctor(self, "ccb/Battle_Dialog_NewEnemy.ccbi", owner)

    local info = QStaticDatabase.sharedDatabase():getCharacterDisplayByID(name)
    assert(info ~= nil)

    self._name = name
    local actorView = QSkeletonActor:create(info.actor_file)
    actorView:setScale(actor_scale)
    owner.actor:addChild(actorView)

    actorView:setPosition(0, info.selected_rect_height * -0.5)
    
    actorView:playAnimation(ANIMATION.STAND)

    owner.name:setString(info.name)
    owner.brief:setString(info.brief)
    owner.features:setString(info.features)
    owner.desc:setString(info.desc)
end

return QNpcTipDialog