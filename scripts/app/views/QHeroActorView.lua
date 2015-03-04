--[[
    Class name QHeroActorView 
    Create by julian 
    This class is a hero actor.
--]]

local QTouchActorView = import(".QTouchActorView")
local QHeroActorView = class("QHeroActorView", QTouchActorView)

function QHeroActorView:ctor(hero, skeletonView)
    QHeroActorView.super.ctor(self, hero, skeletonView)
    self._canTouchBegin = true

    if app.battle:isPVPMode() and not (app.battle:isInSunwell() and app.battle:isSunwellAllowControl()) then
        if hero:getType() == ACTOR_TYPES.HERO then
            self._selectSourceCircle:setVisible(true)
            self._selectSourceCircle:playAnimation(EFFECT_ANIMATION)
        else
            self._selectSourceCircle:setVisible(true)
            self._selectSourceCircle:playAnimation(EFFECT_ANIMATION)

            local view = self._selectSourceCircle
            local maskRect = CCRect(-200, -200, 400, 400)
            view:setScissorEnabled(true)
            view:setScissorRects(
                maskRect,
                CCRect(0, 0, 0, 0),
                CCRect(0, 0, 0, 0),
                CCRect(0, 0, 0, 0)
            )
            local func = ccBlendFunc()
            func.src = GL_DST_ALPHA
            func.dst = GL_DST_ALPHA
            view:setScissorBlendFunc(func)
            view:setScissorColor(ccc3(255, 0, 0))
            view:setScissorOpacity(0)
            func.src = GL_SRC_ALPHA
            func.dst = GL_ONE_MINUS_SRC_ALPHA
            view:setRenderTextureBlendFunc(func)

            app.battle:performWithDelay(function() view:getSkeletonView():setRenderTextureCached(true) end, 0.5)
        end
    end
end

function QHeroActorView:onEnter()
    QHeroActorView.super.onEnter(self)
    self:setEnableTouchEvent(true)
end

function QHeroActorView:onExit()
    self:setEnableTouchEvent(false)
    QHeroActorView.super.onExit(self)
end

return QHeroActorView