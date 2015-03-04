
local QUITransition = import(".QUITransition")
local QUITransitionImmediately = class("QUITransitionImmediately", QUITransition)

local QNotificationCenter = import("...controllers.QNotificationCenter")

function QUITransitionImmediately:start()
    QUITransitionImmediately.super._doTransition(self)
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUITransition.EVENT_TRANSITION_START, transition = self, controller = self.controller})
    QUITransitionImmediately.super.finished(self)
end

return QUITransitionImmediately