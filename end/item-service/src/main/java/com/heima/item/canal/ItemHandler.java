package com.heima.item.canal;

import com.github.benmanes.caffeine.cache.Cache;
import com.heima.item.config.RedisHandler;
import com.heima.item.pojo.Item;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import top.javatool.canal.client.annotation.CanalTable;
import top.javatool.canal.client.handler.EntryHandler;

@CanalTable(value = "tb_item")
@Component
public class ItemHandler implements EntryHandler<Item> {

    @Autowired
    private RedisHandler redisHandler;
    @Autowired
    private Cache<Long, Item> itemCache;

    @Override
    public void insert(Item item) {
        itemCache.put(item.getId(), item);
        redisHandler.saveItem(item);
    }

    @Override
    public void update(Item before, Item after) {
        itemCache.put(after.getId(), after);
        redisHandler.saveItem(after);
    }

    @Override
    public void delete(Item item) {
        itemCache.invalidate(item.getId());
        redisHandler.deleteItemById(item.getId());
    }
}