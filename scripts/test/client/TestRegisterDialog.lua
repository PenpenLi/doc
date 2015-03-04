-- 
-- 测试注册是否正常
-- Author: XuRui
-- Date: 2014-08-06
--
describe["测试注册是否正常"] = function ()
    before = function()
        printInfo('before')
    end

    after = function()
        printInfo('after')
    end
    
    local loginDialog
    local registerDialog
    
    it["切换注册页面"] = function (done)
    
    loginDialog = app:getNavigationController():getTopDialog()
    
      Promise()
      :delay(1)
      :and_then(function ()
            registerDialog = loginDialog:onRegister()
            done()
      end)
        :done()
    end
    it["激活确认"] = function (done)
      local enter
      local activation = "[]{}#"
      loginDialog = app:getNavigationController():getTopDialog()
      Promise()
      :delay(1)
      :and_then(function()
        loginDialog._code:setText(activation) 
        enter = loginDialog:onActive()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
          done()
       end)
       :done()
    end     
    
    it["注册"] = function(done)
    math.randomseed(os.time())
    local user = "abc"..math.random(10000)
    local pass = "123456"
    local register
      Promise()
      :delay(1)
      :and_then(function()
        loginDialog._edit1:setText(user)
        loginDialog._edit2:setText(pass)
        loginDialog._edit3:setText(pass)
        register = loginDialog:onRegister()
        done()
      end)
      :delay(1)
      :and_then(capture)
      :done()
    end
    
end