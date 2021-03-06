describe["副本测试"] = function ()
    before = function()
      printInfo('before')
    end

    after = function()
      printInfo('after')
    end
    
    local main_menu_page
    local copy_dialog
    local dungeon_dialog
    
    it["打开副本页面"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        main_menu_page = app:getNavigationController():getTopPage()
        copy_dialog = main_menu_page:_onInstance()
      end)
      :delay(1)
      :and_then(function()
        expect(copy_dialog).should_be(app:getNavigationController():getTopDialog())
        done()
      end)
      :done()
    end
    
    it["上一个副本"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        copy_dialog:_onTriggerLeft()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        done()
      end)
      :done()
    end
    it["下一个副本"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        copy_dialog:_onTriggerRight()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        done()
      end)
      :done()
    end
    it["点击铜箱"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        copy_dialog._chest:_onTriggerBoxCopper()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogEliteBoxAlert")
        done()
      end)
      :done()
    end
    it["关闭铜箱"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        copy_dialog._chest._alert:_onTriggerCancel()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect(app:getNavigationController():getTopDialog().class.__cname).should_be(".QUIDialogInstance")
        done()
      end)
      :done()
    end
--    it["精英副本"] = function(done)
--      Promise()
--      :delay(1)
--      :and_then(function()
--        copy_dialog:_onTriggerElite()
--      end)
--      :delay(2)
--      :and_then(capture)
--      :and_then(function()
--        copy_dialog:_onTriggerNormal()
--        done()
--      end)
--      :done()
--    end
    it["选择关卡"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        dungeon_dialog = copy_dialog._currentPage._heads[1]:_onTriggerClick()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogDungeon")
        done()
      end)
      :done()
    end
    it["返回主界面"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        dungeon_dialog = app:getNavigationController():getTopDialog()
        main_menu_page = dungeon_dialog:_onTriggerHome()
      end)
      :delay(2)
      :and_then(capture)
      :and_then(function()
        expect(app:getNavigationController():getTopPage().class.__cname).should_be("QUIPageMainMenu")
        done()
      end)
      :done()
    end
end