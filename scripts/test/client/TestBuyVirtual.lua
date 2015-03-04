--购买金钱、体力测试
describe["购买金钱、体力测试"] = function()
    before = function()
        printInfo('before')
    end

    after = function()
        printInfo('after')
    end
    
    local main_menu_page
    local energy_dialog
    local money_dialog
    
    it["点击购买体力"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        main_menu_page = app:getNavigationController():getTopPage()
        energy_dialog = main_menu_page:_onTopRegionCCBLayerClick({kind = 3})
      end)
      :delay(1)
      :and_then(function()
        expect(energy_dialog).should_be(app:getNavigationMidLayerController():getTopDialog())  
        done()
      end)
      :done()
    end
    it["购买体力按钮"] = function(done)
      local name = "energy"
      Promise()
      :delay(1)
      :and_then(function ()
        energy_dialog._typeName = name
        energy_dialog:_onTriggerBuy()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test") 
        energy_dialog:_backClickHandler()
        done()
      end)
      :done()
    end
    
    it["点击购买金钱"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        main_menu_page = app:getNavigationController():getTopPage()
        money_dialog = main_menu_page:_onTopRegionCCBLayerClick({kind = 1})
      end)
      :delay(1)
      :and_then(function()
        expect(money_dialog).should_be(app:getNavigationMidLayerController():getTopDialog()) 
        done()  
      end)
      :done()
    end
    it["购买金钱按钮"] = function(done)
    local name = "money"
      Promise()
      :delay(1)
      :and_then(function()
        money_dialog._typeName = name
        money_dialog:_onTriggerBuy()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test")
        money_dialog:_backClickHandler()  
        done()
      end)
      :done()
    end
end