describe["copyelite_test"] = function()
    before = function()
        printInfo('before team')
    end

    after = function()
        printInfo('after team')
    end

    local mainmenu
    local instanceChoose
    local eliteInstance
    it["战队界面打开"] = function(done)
        mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
        	local event = {}
        	event.name = QUIWidgetMainMenuInfo.EVENT_MAIN_MENU_ONTRIGGER
            instanceChoose = mainmenu:_onMenuEvent(event)
        end)
        :delay(1)
        :and_then(function()
            eliteInstance = instanceChoose:_onEliteDungeonTab()
            expect(eliteInstance).should_be(app:getNavigationController():pushViewController({uiType=QUIViewController.TYPE_DIALOG, 
            	uiClass="QUIDialogCopyEliteChoose"}))
            done()
        end)
        :done()
    end

    it["副本选择条滑动"] = function(done)
        Promise()
        :and_then(function()
            eliteInstance._onTouch("began", 0, 0)
            eliteInstance._onTouch("moved", eliteInstance._endureRight, 0)
            eliteInstance._onTouch("ended", eliteInstance._endureRight, 0)
    	end)
        :done()
    end

    it["副本选择"] = function(done)
        Promise()
        :and_then(function()
            for i = 1, #eliteInstance._nodeFrame do
            	eliteInstance._nodeFrame[i]:selected()
            	expect(eliteInstance._selectID).should_be(eliteInstance._instanceInfo[i])
            	delay(1)
            end
    	end)
        :done()
    end
end