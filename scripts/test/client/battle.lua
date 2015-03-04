-- 测试主场景能否被滑动
describe["战斗相关的测试"] = function()
    before = function()
        printInfo('before battle')
    end

    after = function()
        printInfo('after battle')
    end

    it["普通副本简单难度"] = function(done)
        printInfo("done3")
        done()
    end

    it["普通副本困难难度"] = function(done)
        printInfo("done4")
        done()
    end
end