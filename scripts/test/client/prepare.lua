-- 准备测试，比如创建新用户等等
describe["准备测试"] = function()
    it["创建新用户"] = function(done)
        Promise()
        :delay(2)
        :and_then(function()
            app:getClient():userCreateForTest(function(data)
                expect(data).should_not_be(nil)
                expect(data.user).should_not_be(nil)
                done()
            end, function(data)
                expect("失败代码").should_be(data.code)
                done()
            end)
        end)
        :done()
    end
end