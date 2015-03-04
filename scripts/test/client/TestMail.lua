--
-- 测试邮箱
-- Author: XuRui
-- Date: 2014-08-07
--
describe["邮箱测试"] = function ()
  before = function()
    printInfo('before')
  end

  after = function()
    printInfo('after')
  end
  
  local currentpage
  local mail_page
  
  it["邮箱"] = function(done)
    Promise()
    :delay(2)
    :and_then(function()
      currentpage = app:getNavigationController():getTopPage()
      mail_page = currentpage:_onMail()
    end)
    :delay(1)
    :and_then(function()
      expect(mail_page).should_be(app:getNavigationMidLayerController():getTopDialog())
      done()
    end)
    :done()
  end
  
  it["向上向移动邮件"] = function(done)
    Promise()
    :delay(1)
    :and_then(function()
        mail_page:_onEvent({name = "began",y = 0})
        mail_page:_onEvent({name = "moved",y = 100})
        mail_page:_onEvent({name = "ended",y = 100})
    end)
    :delay(1)
    :and_then(capture)
    :and_then(function()
        done()
    end)
    :done()
  end
  it["向下向移动邮件"] = function(done)
    Promise()
    :delay(1)
    :and_then(function()
        mail_page:_onEvent({name = "began",y = 0})
        mail_page:_onEvent({name = "moved",y = -100})
        mail_page:_onEvent({name = "ended",y = -100})
    end)
    :delay(1)
    :and_then(capture)
    :and_then(function()
        done()
    end)
    :done()
  end
  it["查看邮件正文"] = function(done)
    Promise()
    :delay(1)
    :and_then(function()
        mail_page._mailSheets[1]._btnEnable = true
        mail_page._mailSheets[1]:_onTriggerClick()
    end)
    :delay(2)
    :and_then(function()
        mail_page:_onTriggerClose()
        done()
    end)
    :done()
  end
end