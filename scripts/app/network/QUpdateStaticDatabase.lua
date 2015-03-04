
local QUpdateStaticDatabase = class("QUpdateStaticDatabase")

local QStaticDatabase = import("..controllers.QStaticDatabase")
local QUIViewController = import("..ui.pages.QUIViewController")
local QUIWidgetLoading = import("..ui.widgets.QUIWidgetLoading")

QUpdateStaticDatabase.STATUS_PROGRESS = "STATUS_PROGRESS"
QUpdateStaticDatabase.STATUS_COMPLETED = "STATUS_COMPLETED"
QUpdateStaticDatabase.STATUS_FAILED = "STATUS_FAILED"

local LOCAL_VERSION_FILE = "version"
local VERSION_FILE = "version"
if device.platform == "ios" then
    VERSION_FILE = "version_ios"
elseif device.platform == "android" then
    VERSION_FILE = "version_android"
end

local INDEX_FILE = "index" 
--local INDEX_FILE = "static/index"

QUpdateStaticDatabase.EVENT_STATUS_UPDATE = "EVENT_STATUS_UPDATE"

QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL = 0.2
QUpdateStaticDatabase.PROGRESS_MAX_SPEED = 1 / 1

local currentMinute = math.floor(q.time() / 60)
local currentVersion = "?ver=" .. tostring(currentMinute)

function QUpdateStaticDatabase:ctor()
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self._downloader = QDownloader:new(CCFileUtils:sharedFileUtils():getWritablePath(), 8)
end

-- 返回值 -1：出错
-- 返回值 0：不需要更新
-- 返回值 > 0: 总共需要下载的内容的大小
function QUpdateStaticDatabase:update(tmp_disable) 
    if not self._downloader:isDisableDownload() then
        app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_PAGE, uiClass="QUIPageUpdate"})
        -- QUIWidgetLoading.sharedLoading():Hide()
        self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = 0})
        QUIWidgetLoading.sharedLoading():Show()
    end

    local labelcaution = nil
    local labelcaution_end = false
    scheduler.performWithDelayGlobal(function()
        if self._downloader:isDisableDownload() == false and labelcaution_end == false then
            labelcaution = CCLabelTTF:create()
            labelcaution:setString("检查更新")
            app._uiScene:addChild(labelcaution)
            labelcaution:setPosition(CONFIG_SCREEN_WIDTH / 2, CONFIG_SCREEN_HEIGHT / 2 - 70 - 30)
            labelcaution:setFontSize(24)
            labelcaution:retain()
            labelcaution:setVisible(false)

            QUIWidgetLoading.sharedLoading():setCustomString("检查更新", true)
        end
    end, 0.2)
    local function removeLabelCaution()
        if labelcaution and labelcaution.removeFromParent then
            labelcaution:removeFromParent()
            labelcaution:release()
        end
        labelcaution = nil
        labelcaution_end = true
    end

    scheduler.performWithDelayGlobal(function()

        if self._downloader:isDisableDownload() then
            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_COMPLETED, total = 0, count = 0})
            if labelcaution and labelcaution.removeFromParent then
                labelcaution:removeFromParent()
                labelcaution:release()
            end
            labelcaution = nil
            return 0, 0
        end

        local fileutil = CCFileUtils:sharedFileUtils()
        -- nzhang: 下载服务器最新的version文件，如果version文件为空则表示服务器上没有任何更新
        --         不立即写回version文件，等全部下载完成之后再写回
        local function downloadStart(version, skipAll)
            if version == "error" then
                self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_FAILED})
                removeLabelCaution()
                return -1, -1 
            elseif string.len(version) < 2 then self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_COMPLETED, total = 0, count = 0}) 
                self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_FAILED})
                removeLabelCaution()
                return 0, 0
            end

            local version_content = version.sub(version, 1, 60)
            local version_md5 = string.sub(version_content, string.len(version_content) - 32 + 1, string.len(version))

            -- nzhang: 检查本地的index文件是否存在并且是version文件所指的内容
            local local_content_exist = fileutil:isFileExist(fileutil:getWritablePath() .. INDEX_FILE)
            local local_content = (local_content_exist and fileutil:getFileData(fileutil:getWritablePath() .. INDEX_FILE)) or ""
            local local_content_md5 = (local_content_exist and crypto.md5(local_content)) or ""
            local md5_match = local_content_exist and (version_md5 == local_content_md5)

            local function downloadFiles(content, skipAll)
                local total = 0 -- 记录总的字节大小
                local progress = 0 -- 记录当前进度字节大小
                local count = 0 -- 记录总的文件个数
                local completed = 0 -- 记录完成的文件个数
                local downloadStartTime = q.time() -- 开始下载的时间点，防止进度条走的过快

                if tmp_disable then
                    -- 临时屏蔽掉更新
                    self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_COMPLETED, total = total, count = count})
                    removeLabelCaution()
                    return 0, 0
                end

                local start = q.time()

                local labeltip = nil
                local function onDownloadCompleted(current_percent)
                    QUIWidgetLoading.sharedLoading():setCustomString(nil, true)
                    local handle
                    handle = scheduler.scheduleGlobal(function(dt)
                            if current_percent < 1.0 then
                                current_percent = current_percent + dt * self.PROGRESS_MAX_SPEED
                                current_percent = current_percent > 1.0 and 1.0 or current_percent
                                self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = current_percent * 100})
                            else
                                scheduler.unscheduleGlobal(handle)
                                -- 更新进度到100%
                                self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = 100})

                                -- printInfo("================ total time: %.2f seconds", q.time() - start)
                                self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_COMPLETED, total = total, count = count})

                                -- nzhang: 写回version串到本地的version文件，这样下次游戏启动就会从writable path下加载脚本
                                self._downloader:writeContent(LOCAL_VERSION_FILE, version_content)

                                if labeltip then
                                    labeltip:removeFromParent()
                                    labeltip:release()
                                    labeltip = nil
                                end
                            end
                        end, 0)
                end

                if skipAll then
                    onDownloadCompleted(1.0)
                    return
                end

                local index = QStaticDatabase.loadIndex(content)
                local function onDownloadEvent(eventPackage)
                    local eventData = string.split(eventPackage, ',')
                    local eventId = tonumber(eventData[1]);
                    local eventStr = eventData[2];
                    local eventNum = eventData[3];

                    if eventNum == nil then
                        eventNum = 0
                    else
                        eventNum = tonumber(eventNum)
                    end

                    --[[
                        返回格式为逗号“，”隔开的三个字段第一段是事件类型，有三种类型。
                        - QDownloader:kSuccess：成功下载一个文件，这时第二个字段eventStr是文件名
                        - QDownloader:kProgress：下载文件的进度，这时第二个字段eventStr是文件名，第三个字段eventNum是下载进度0 - 100
                        - QDownloader:kError：出错，此时第二个字段eventStr是下载文件名或者为空，第三个字段eventNum是错误代码，QDownloader:kCreateFile/QDownloader:kNetwork
                    --]]

                    if eventId == QDownloader.kSuccess or eventId == QDownloader.kProgress then
                        local cur = index[eventStr]
                        if cur == nil then
                            printError("file not found in index: " .. eventStr)
                        else
                            if cur.progress == nil then
                                cur.progress = 0
                            end
                            -- 更新总体的progress
                            progress = progress + cur.gz * (eventNum - cur.progress) / 100
                            cur.progress = eventNum

                            local adjustProgress = (1 - QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL) * progress / total
                            local deltaTime = q.time() - downloadStartTime
                            if deltaTime <= 0 then deltaTime = 0.001 end
                            if adjustProgress / deltaTime > QUpdateStaticDatabase.PROGRESS_MAX_SPEED then
                                adjustProgress = deltaTime * QUpdateStaticDatabase.PROGRESS_MAX_SPEED
                            end 

                            local percent = QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL + adjustProgress
                            if percent > 1.0 then percent = 1.0 end
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = percent * 100})

                            if eventId == QDownloader.kSuccess then
                                completed = completed + 1
                                printInfo("completed %d/%d, %s", completed, count, eventStr)
                                if labeltip ~= nil and labeltip:getParent() == nil then
                                    app._uiScene:addChild(labeltip)
                                end
                                -- labeltip:setString(string.format("更新客户端中：%d / %d", completed, count))
                                local updatepercent = math.ceil((completed / count) * 100)
                                if updatepercent < 10 then
                                    labeltip:setString(string.format("下载： %d%%", updatepercent))
                                    QUIWidgetLoading.sharedLoading():setCustomString(string.format("下载中： %d%%", updatepercent), false)
                                else
                                    labeltip:setString(string.format("下载中：%d%%", updatepercent))
                                    QUIWidgetLoading.sharedLoading():setCustomString(string.format("下载中：%d%%", updatepercent), false)
                                end
                                if completed == count then
                                    onDownloadCompleted(percent)
                                end
                            end
                        end
                    elseif eventId == QDownloader.kError then
                        if eventNum == QDownloader.kNetwork or eventNum == QDownloader.kValidation then
                            local cur = index[eventStr]
                            if cur == nil then
                                printError("file not found in index: " .. eventStr)
                            else
                                if cur.retry == 2 then
                                    -- 提示重新下载
                                    CCMessageBox(string.format("redownload %s", cur.name), "")
                                    cur.retry = 0
                                else
                                    cur.retry = cur.retry + 1
                                end
                                -- 重新下载cur
                                local values = cur
                                self._downloader:downloadFile(STATIC_URL .. version_content .. "/" .. values.name, values.name, values.md5, values.size, values.gz)
                            end
                        else
                            printError("event: error when download file: " .. eventStr .. " code: " .. eventNum)
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_FAILED})
                        end
                    else
                        printError("eventId not valid: " .. eventId)
                    end
                end

                local _count = 0 -- 需要更新的文件数量
                local _downloadIndex = {}
                local function requireDownload()
                    QUIWidgetLoading.sharedLoading():Hide()
                    -- nzhang: 下载数量可能为0，则直接完成下载（服务器要么没有更新，要么更新已经下载过），这种情况就不能依赖setf._downloader发出事件
                    if count == 0 then
                        onDownloadCompleted(QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL)
                    else
                        local confirmed = false
                        local function confirmDownload()
                            if confirmed ==  true then
                                return
                            else
                                confirmed = true
                            end

                            self._downloader:registerScriptHandler(onDownloadEvent)
                            for _, values in pairs(_downloadIndex) do
                                self._downloader:downloadFile(STATIC_URL .. version_content .. "/" .. values.name, values.name, values.md5, values.size, values.gz)
                            end

                            QUIWidgetLoading.sharedLoading():Show()

                            labeltip = CCLabelTTF:create()
                            -- labeltip:setString(string.format("更新客户端中：0 / %d", count))
                            labeltip:setString(string.format("下载中： 0%%"))
                            QUIWidgetLoading.sharedLoading():setCustomString(string.format("下载： 0%%"), false)
                            if labeltip ~= nil and labeltip:getParent() == nil then
                                app._uiScene:addChild(labeltip)
                            end
                            labeltip:setPosition(CONFIG_SCREEN_WIDTH / 2, CONFIG_SCREEN_HEIGHT / 2 - 70 - 30)
                            labeltip:setFontSize(24)
                            labeltip:retain()
                            labeltip:setVisible(false)

                            downloadStartTime = q.time()
                        end

                        -- TODO 请求更新
                        -- CCMessageBox(string.format("检查到更新，约%dKB", math.ceil(total / 1024)), "")
                        app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, 
                            uiClass = "QUIDialogAlert", options = {title = "更新提示", content = string.format("更新提示：检查到更新，需要下载约%dKB", math.ceil(total / 1024)), ok_only = true
                            , comfirmBack = function()
                                confirmDownload()
                            end
                            , callBack = function()
                                confirmDownload()
                            end }})
                    end

                    removeLabelCaution()
                end

                if self._downloader.checkFileAsync == nil then
                    -- nzhang: 检查需要更新的文件数量，分批QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL批,同步分帧运行。
                    local _job = QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL * 100
                    local _current = 1
                    local _index = {}
                    for _, values in pairs(index) do
                        table.insert(_index, values)
                    end
                    local _number = math.ceil(#_index / _job)
                    local handle_check
                    handle_check = scheduler.scheduleUpdateGlobal(function()
                        local i = _current
                        local j = _current + _number
                        j = j < #_index and j or #_index
                        while i <= j do
                            local values = _index[i]
                            if self._downloader:checkFile(STATIC_URL .. version_content .. "/" .. values.name, values.name, values.md5, values.size, values.gz) then
                                total = total + values.gz
                                count = count + 1
                                table.insert(_downloadIndex, values)
                            end
                            i = i + 1
                        end
                        if j == #_index then
                            -- 更新进度到 10%
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL * 100})
                            scheduler.unscheduleGlobal(handle_check)
                            requireDownload()
                        else
                            -- 更新进度+1%
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = _current / #_index * QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL * 100})
                            _current = j + 1
                        end
                    end, 0)
                else
                    -- nzhang: 检查需要更新的文件数量，异步执行。
                    local checkCount = 0
                    local checkTotal = 0
                    for _, values in pairs(index) do
                        checkTotal = checkTotal + 1
                    end
                    local function onCheckFileEvent(eventPackage)
                        local eventData = string.split(eventPackage, ',')
                        local eventId = tonumber(eventData[1]);
                        local eventStr = eventData[2];

                        --[[
                            返回格式为逗号“，”隔开的三个字段第一段是事件类型，有三种类型。
                            - QDownloader.kCheckNeedUpdate： 该文件需要下载
                            - QDownloader.kCheckSkipUpdate： 该文件不需要下载
                        --]]

                        if eventId == QDownloader.kCheckNeedUpdate then
                            local file = eventStr
                            local values = index[file]
                            total = total + values.gz
                            count = count + 1
                            table.insert(_downloadIndex, values)
                            checkCount = checkCount + 1
                        elseif eventId == QDownloader.kCheckSkipUpdate then
                            checkCount = checkCount + 1
                        end
                        self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = checkCount / checkTotal * QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL * 100})

                        if checkCount == checkTotal then
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_PROGRESS, progress = QUpdateStaticDatabase.CHECK_FILE_PROGRESS_TOTAL * 100})
                            requireDownload()
                        end
                    end
                    self._downloader:registerScriptHandler(onCheckFileEvent)
                    for _, values in pairs(index) do
                        self._downloader:checkFileAsync(STATIC_URL .. version_content .. "/" .. values.name, values.name, values.md5, values.size, values.gz)
                    end
                end
            end

            if skipAll then
                downloadFiles(nil, true)
                return
            end

            -- nzhang: 如果本地index文件不符合version，则重新下载index。index文件下载后会保存在writable path下
            if md5_match then
                local content = local_content
                downloadFiles(content)
            else
                self._downloader:downloadFile(STATIC_URL .. version_content .. "/" .. INDEX_FILE, INDEX_FILE, version_md5)
                self._downloader:registerScriptHandler(function(evtPkg)
                    local eventData = string.split(evtPkg, ',')
                    local eventId = tonumber(eventData[1])
                    local eventStr = eventData[2]
                    local eventNum = eventData[3]

                    if eventNum == nil then
                        eventNum = 0
                    else
                        eventNum = tonumber(eventNum)
                    end

                    if eventId == QDownloader.kSuccess or eventId == QDownloader.kProgress then
                        if eventId == QDownloader.kSuccess then
                            local content = fileutil:getFileData(fileutil:getWritablePath() .. INDEX_FILE)
                            downloadFiles(content)
                        end
                    elseif eventId == QDownloader.kError then
                        if eventNum == QDownloader.kNetwork or eventNum == QDownloader.kValidation then
                            self._downloader:downloadFile(STATIC_URL .. version_content .. "/" .. INDEX_FILE, INDEX_FILE, version_md5)
                        else
                            printError("event: error when download file: " .. eventStr .. " code: " .. eventNum)
                            self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_FAILED})
                        end
                    else
                        printError("eventId not valid: " .. eventId)
                    end
                end)
            end
        end

        self._downloader:downloadFile(STATIC_URL .. VERSION_FILE .. currentVersion, "tmp/" .. LOCAL_VERSION_FILE)
        self._downloader:registerScriptHandler(function(evtPkg)
            local eventData = string.split(evtPkg, ',')
            local eventId = tonumber(eventData[1])
            local eventStr = eventData[2]
            local eventNum = eventData[3]

            if eventNum == nil then
                eventNum = 0
            else
                eventNum = tonumber(eventNum)
            end

            if eventId == QDownloader.kSuccess or eventId == QDownloader.kProgress then
                if eventId == QDownloader.kSuccess then
                    local version = fileutil:getFileData(fileutil:getWritablePath() .. "tmp/" .. LOCAL_VERSION_FILE)

                    -- 检查本地version file是否一致，一致则跳过检查
                    if fileutil:isFileExist(fileutil:getWritablePath() .. LOCAL_VERSION_FILE) then
                        local localversion = fileutil:getFileData(fileutil:getWritablePath() .. LOCAL_VERSION_FILE)
                        if localversion == version then
                            downloadStart(version, true)
                            return
                        end
                    end

                    downloadStart(version)
                end
            elseif eventId == QDownloader.kError then
                if eventNum == QDownloader.kNetwork or eventNum == QDownloader.kValidation then
                    self._downloader:downloadFile(STATIC_URL .. VERSION_FILE .. currentVersion, "tmp/" .. LOCAL_VERSION_FILE)
                else
                    printError("event: error when download file: " .. eventStr .. " code: " .. eventNum)
                    self:dispatchEvent({name = QUpdateStaticDatabase.STATUS_FAILED})
                end
            else
                printError("eventId not valid: " .. eventId)
            end
        end)
    end, 0.2)
end

function QUpdateStaticDatabase:updateIndex()
end

function QUpdateStaticDatabase:purge()
    if self._downloader.purge then
        self._downloader:purge()
    end
end

return QUpdateStaticDatabase