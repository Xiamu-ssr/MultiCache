-- 创建一个本地缓存对象item_cache
local item_cache = ngx.shared.item_cache;

-- 函数，向openresty本身发送类似/path/item/10001请求，根据conf配置，将被删除/path前缀并代理至tomcat程序
local function read_get(path, params)
    local rsp = ngx.location.capture('/path'..path,{
        method = ngx.HTTP_GET,
        args = params,
    })
    if not rsp then
        ngx.log(ngx.ERR, "http not found, path: ", path, ", args: ", params);
        ngx.exit(404)
    end
    return rsp.body
end

-- 函数，如果本地有缓存，使用缓存，如果没有代理到tomcat然后将数据存入缓存
local function read_data(key, expire, path, params)
    -- query local cache
    local rsp = item_cache:get(key)
    -- query tomcat
    if not rsp then
        ngx.log(ngx.ERR, "redis cache miss, try tomcat, key: ", key)
        rsp = read_get(path, params)
    end
    -- write into local cache
    item_cache:set(key, rsp, expire)
    return rsp
end

local _M = {
    read_data = read_data
}

return _M