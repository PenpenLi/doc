
local QUIWidget = import(".QUIWidget")
local QUIWidgetLoadingAnimation = class("QUIWidgetLoadingAnimation", QUIWidget)

local QSkeletonViewController = import("...controllers.QSkeletonViewController")

function QUIWidgetLoadingAnimation:ctor(options)
	local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()

    self._actor = skeletonViewController:createSkeletonActorWithFile(global.loading_actor_file)
    self:addChild(self._actor)
    self._actor:setPositionX(-100)
    self._actor:setScaleX(-1.0)
    self._actor:playAnimation(global.loading_skeleton_animation_name, true)

    self._sheep = skeletonViewController:createSkeletonActorWithFile(global.loading_sheep_file)
    self:addChild(self._sheep)
    self._sheep:setPositionX(100)
    self._sheep:setScaleX(-1.0)
    self._sheep:playAnimation(global.loading_skeleton_animation_name, true)

    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.8, ccp(-10, 0)))
    arr:addObject(CCMoveBy:create(1.6, ccp(20, 0)))
    arr:addObject(CCMoveBy:create(0.8, ccp(-10, 0)))
    self._actor:runAction(CCRepeatForever:create(CCSequence:create(arr)))

    arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.8, ccp(20, 0)))
    arr:addObject(CCMoveBy:create(1.6, ccp(-40, 0)))
    arr:addObject(CCMoveBy:create(0.8, ccp(20, 0)))
    self._sheep:runAction(CCRepeatForever:create(CCSequence:create(arr)))

	self:setNodeEventEnabled(true)
end

function QUIWidgetLoadingAnimation:onCleanup()
    local skeletonViewController = QSkeletonViewController.sharedSkeletonViewController()
    skeletonViewController:removeSkeletonActor(self._actor)
    skeletonViewController:removeSkeletonActor(self._sheep)
end

return QUIWidgetLoadingAnimation