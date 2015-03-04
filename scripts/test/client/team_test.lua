--
-- Author: Your Name
-- Date: 2014-05-27 15:59:41
--
-- Õ½¶ÓÏà¹Ø¹¦ÄÜ ¼ÙÉèÓ¢ÐÛÓÐ4¸ö Ã»ÓÐÓ¢ÐÛ¼ÓÈëÕ½¶Ó
describe["teamtest"] = function()
    before = function()
        printInfo('before team')
    end

    after = function()
        printInfo('after team')
    end
    local mainmenu
    local heroOverView
    local teamView
    it["Õ½¶Ó½çÃæ´ò¿ª"] = function(done)
        mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            heroOverView = mainmenu:_onButtondownSideMenuLineup()
        end)
        :delay(1)
        :and_then(function()
            teamView = heroOverView:_onTriggerOpenTeamArrangement()
            expect(teamView).should_be(app:getNavigationController():getTopDialog())
            done()
        end)
        :done()
    end

    it["Õ½¶Ó½çÃæÕ½¶ÓÓ¢ÐÛÊýÁ¿ÎªÁã"] = function(done)
        Promise()
        :and_then(function()
            expect(teamView._curPage).should_not_be(nil)
            if teamView._curPage then
                expect(#teamView._curPage._heroFrames).should_be(4)
        end
            expect(#teamView._teamField._heads).should_be(0)
            done()
        end)
        :done()
    end

    it["Ìí¼ÓµÚÒ»Ò³µÄµÚÒ»¸öÓ¢ÐÛµ½Õ½¶Ó"] = function(done)
        Promise()
        :and_then(function()
            if teamView._curPage then
                teamView:_addHeroToTeam(teamView._curPage._heroFrames._hero.heroId)
            end
        end)
        :delay(2)
        :and_then(function()
            expect(#teamView._teamField._heads).should_be(1)
            done()
        end)
        :done()
    end

    it["ÆÕÍ¨¸±±¾À§ÄÑÄÑ¶È"] = function(done)
        printInfo("done4")
        :done()
    end
end