local redis = require('resty.redis')
local red = redis:new()
red:set_timeouts(1000, 1000, 1000)
-- 创建一个本地缓存对象item_cache
local item_cache = ngx.shared.item_cache;

-- 关闭redis连接的工具方法，其实是放入连接池
local function close_redis(red)
    local pool_max_idle_time = 10000 -- 连接的空闲时间，单位是毫秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.log(ngx.ERR, "放入redis连接池失败: ", err)
    end
end

-- 查询redis的方法 ip和port是redis地址，key是查询的key
local function read_redis(ip, port, key)
    -- 获取一个连接
    local ok, err = red:connect(ip, port)
    if not ok then
        ngx.log(ngx.ERR, "连接redis失败 : ", err)
        return nil
    end
    -- 查询redis
    local resp, err = red:get(key)
    -- 查询失败处理
    if not resp then
        ngx.log(ngx.ERR, "查询Redis失败: ", err, ", key = " , key)
    end
    --得到的数据为空处理
    if resp == ngx.null then
        resp = nil
        ngx.log(ngx.ERR, "查询Redis数据为空, key = ", key)
    end
    close_redis(red)
    return resp
end

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
    -- query redis
    if not rsp then
        ngx.log(ngx.ERR, "local cache miss, try redis, key: ", key)
        rsp = read_redis("172.30.3.21", 6379, key)
        if not rsp then
            ngx.log(ngx.ERR, "redis cache miss, try tomcat, key: ", key)
            rsp = read_get(path, params)
        end
    end
    -- write into local cache
    item_cache:set(key, rsp, expire)
    return rsp
end

local _M = {
    read_get = read_get,
    read_redis = read_redis,
    read_data = read_data
}

return _M