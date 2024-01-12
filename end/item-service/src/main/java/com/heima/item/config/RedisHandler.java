package com.heima.item.config;

import com.alibaba.fastjson2.JSON;
import com.heima.item.pojo.Item;
import com.heima.item.pojo.ItemStock;
import com.heima.item.service.IItemService;
import com.heima.item.service.IItemStockService;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class RedisHandler implements InitializingBean {
    @Autowired
    private StringRedisTemplate redisTemplate;
    @Autowired
    private IItemService itemService;
    @Autowired
    private IItemStockService stockService;
    @Override
    public void afterPropertiesSet() throws Exception {
        List<Item> itemList = itemService.list();
        for (Item item : itemList) {
            String json = JSON.toJSONString(item);
            redisTemplate.opsForValue().set("item:id:"+item.getId(), json);
        }
        List<ItemStock> stockList = stockService.list();
        for (ItemStock stock : stockList) {
            String json = JSON.toJSONString(stock);
            redisTemplate.opsForValue().set("item:stock:id:"+stock.getId(), json);
        }
    }

    public void saveItem(Item item){
        String json = JSON.toJSONString(item);
        redisTemplate.opsForValue().set("item:id:"+item.getId(), json);
    }

    public void deleteItemById(Long id){
        redisTemplate.delete("item:id:"+id);
    }
}
