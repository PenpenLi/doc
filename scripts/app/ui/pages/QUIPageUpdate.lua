
local QUIPage = import(".QUIPage")
local QUIPageUpdate = class("QUIPageUpdate", QUIPage)

local QUIWidgetLoadBar = import("..widgets.QUIWidgetLoadBar")
local QUpdateStaticDatabase = import("...app.network.QUpdateStaticDatabase")

function QUIPageUpdate:ctor(options)
  local ccbFile = "ccb/Page_Login.ccbi"

  QUIPageUpdate.super.ctor(self, ccbFile, callbacks, options)

  self._ccbOwner.btn_logout:setVisible(false)
  self._ccbOwner.btn_game:setVisible(false)
  self._ccbOwner.node_panel:setVisible(false)
  self._ccbOwner.label_welcome:getParent():setVisible(false)

  self._loadBar = QUIWidgetLoadBar.new()
  self._loadBar:setVisible(false)
  self._ccbOwner.node_loading:addChild(self._loadBar)

  self._proxy = cc.EventProxy.new(app:getUpdater())
  self._proxy:addEventListener(QUpdateStaticDatabase.STATUS_PROGRESS, handler(self, self.onUpdaterProgress))
end

function QUIPageUpdate:onUpdaterProgress(event)
  if event.name == QUpdateStaticDatabase.STATUS_PROGRESS then
    local progress = math.ceil(event.progress)
    self._loadBar:setPercent(progress / 100)

    if progress <= app:getUpdater().CHECK_FILE_PROGRESS_TOTAL * 100 then
      self._loadBar:setTip("检查更新中......")
    else
      self._loadBar:setTip("下载更新中......")
    end

    if progress == 100 then
      self._proxy:removeEventListener(QUpdateStaticDatabase.STATUS_PROGRESS, handler(self, self.onUpdaterProgress))
    end
  end
end

return QUIPageUpdate



