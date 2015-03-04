--
-- Author: Your Name
-- Date: 2015-01-14 11:50:04
--
local QMails = class("QMails")

QMails.MAILS_UPDATE_EVENT = "MAILS_UPDATE_EVENT"

function QMails:ctor(options)
	cc.GameObject.extend(self)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
	self._mails = {}
end

function QMails:updateMaliData(data)
    for _, mail in pairs(data.mails) do
        local isfind = false 
        for index,localMail in pairs(self._mails) do
            if mail.mailId == localMail.mailId then
                self._mails[index] = mail
                isfind = true
                break
            end
        end
        if isfind == false then
            table.insert(self._mails, mail)
        end
        if mail.attachment ~= "" then
            local items = string.split(mail.attachment, ";")                
            mail.items = {}      
            mail.awards = {}
            for _, item in pairs(items) do
                local obj = string.split(item, "^")
                local itemType = remote.items:getItemType(obj[1])
                if itemType == ITEM_TYPE.MONEY or itemType == ITEM_TYPE.TOKEN_MONEY or itemType == ITEM_TYPE.ENERGY or itemType == ITEM_TYPE.ARENA_MONEY then
                    table.insert(mail.awards, {type = itemType, count = obj[2]})
                else
                    table.insert(mail.items, {type = ITEM_TYPE.ITEM, itemId = obj[1], count = obj[2]})
                end
            end
        end
    end
    -- 按照要求排序
    table.sort(self._mails, function (mailA, mailB)
        if mailA.read == true and mailB.read == true then
            return mailA.publishTime > mailB.publishTime 
        elseif mailA.read == true and mailB.read == false then
            return false
        elseif mailA.read == false and mailB.read == true then 
            return true
        else 
            if mailA.attachment ~= "" and mailB.attachment ~= "" then
                return mailA.publishTime > mailB.publishTime
            elseif mailA.attachment == "" and mailB.attachment ~= "" then
                return false
            elseif mailA.attachment ~= "" and mailB.attachment == "" then
                return true
            else 
                return mailA.publishTime > mailB.publishTime
            end
        end
    end)
    self:dispatchEvent({name = QMails.MAILS_UPDATE_EVENT})
end

function QMails:getMails()
	return self._mails or {}
end

function QMails:removeMailsForId(mailId)
	for index,value in pairs(self._mails) do
		if value.mailId == mailId then
			table.remove(self._mails, index)
    		self:dispatchEvent({name = QMails.MAILS_UPDATE_EVENT})
			return 
		end
	end
end

return QMails