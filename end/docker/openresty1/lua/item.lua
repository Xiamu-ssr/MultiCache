-- include
local commonUtils = require('common')
local cjson = require("cjson")

-- get url params
local id = ngx.var[1]
-- redirect item
local itemJson = commonUtils.read_data("item:id:"..id, 1800,"/item/"..id,nil)
-- redirect item/stock
local stockJson = commonUtils.read_data("item:stock:id:"..id, 4 ,"/item/stock/"..id, nil)
-- json2table
local item = cjson.decode(itemJson)
local stock = cjson.decode(stockJson)
-- combine item and stock
item.stock = stock.stock
item.sold = stock.sold
-- return result
ngx.say(cjson.encode(item))