--
-- Author: Your Name
-- Date: 2014-08-14 11:43:56
--
describe["测试战斗是否正常"] = function ()
    before = function()
        printInfo('before')
    end

    after = function()
        printInfo('after')
    end
    
    local main_menu_page
    local city_dialog
    local copy_dialog
    
    it["进入地图页面"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        main_menu_page = app:getNavigationController():getTopPage()
        city_dialog = main_menu_page:_onInstance()
      end)
      :delay(1)
      :and_then(function()
        expect(city_dialog).should_be(app:getNavigationController():getTopDialog())
        done()
      end)
      :done()
    end
    
    it["选择地图"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        city_dialog = app:getNavigationController():getTopDialog()
        copy_dialog = city_dialog._currentMap._city[1]._clickButton:onButtonClicked()
      end)
      :delay(1)
      :and_then(function()
        expect(copy_dialog).should_be(app:getNavigationController():getTopDialog())
        done()
      end)
      :done()
    end
    
--    it["左右滑动"] = function(done)
--      Promise()
--      :delay(1)
--      :and_then(function()
--        copy_dialog:_onTriggereRight()
--      end)
--      :delay(1)
--      :and_then(function()
--        copy_dialog:_onTriggereLeft()
--      end)
--      :delay(1)
--      :and_then(capture)
--      :adn_then(function()
--        done()
--      end)
--      :done()
--    end
--    
--    it["选择副本"] = function(done)
--      Promise()
--      :delay(1)
--      :and_then(function()
--        copy_dialog._itemsBox[3]:_onTriggerClick()
--      end)
--      :delay(1)
--      :and_then(capture)
--      :and_then(function()
--        done()
--      end)
--      :done()
--    end
    
--    it["开战"] = function()
--      Promise()
--      :delay(1)
--      :and_then(function()
--        
--      end)
--    end

--    it["返回主页面"] = function(done)
--    local dialog
--      Promise
--      :delay(1)
--      :and_then(function()
--        dialog = app:getNavigationController():getTopDialog()
--        dialog:_onTriggerBack()
--      end)
--      :delay(1)
--      :and_then(function()
--        dialog = app:getNavigationController():getTopDialog()
--        dialog:_onTriggerBack()
--        done()
--      end)
--      :done()
--    end
    
end