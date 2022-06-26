/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include "declarations.h"
#include "item.h"

#include <framework/luaengine/luaobject.h>

 // @bindclass
class Container : public LuaObject
{
protected:
    Container(int id, int capacity, const std::string_view name, const ItemPtr& containerItem, bool hasParent, bool isUnlocked, bool hasPages, int containerSize, int firstIndex)
        :m_id(id), m_capacity(capacity), m_containerItem(containerItem), m_name(name), m_hasParent(hasParent), m_unlocked(isUnlocked), m_hasPages(hasPages), m_size(containerSize), m_firstIndex(firstIndex)
    {}

public:
    ItemPtr getItem(int slot);
    std::deque<ItemPtr> getItems() { return m_items; }
    int getItemsCount() { return m_items.size(); }
    Position getSlotPosition(int slot) { return { 0xffff, m_id | 0x40, static_cast<uint8_t>(slot) }; }
    int getId() { return m_id; }
    int getCapacity() { return m_capacity; }
    ItemPtr getContainerItem() { return m_containerItem; }
    std::string getName() { return m_name; }
    bool hasParent() { return m_hasParent; }
    bool isClosed() { return m_closed; }
    bool isUnlocked() { return m_unlocked; }
    bool hasPages() { return m_hasPages; }
    int getSize() { return m_size; }
    int getFirstIndex() { return m_firstIndex; }
    ItemPtr findItemById(uint32_t itemId, int subType);

protected:
    void onOpen(const ContainerPtr& previousContainer);
    void onClose();
    void onAddItem(const ItemPtr& item, int slot);
    void onAddItems(const std::vector<ItemPtr>& items);
    void onUpdateItem(int slot, const ItemPtr& item);
    void onRemoveItem(int slot, const ItemPtr& lastItem);

    friend class Game;

private:
    void updateItemsPositions();

    int m_id;
    int m_capacity;
    ItemPtr m_containerItem;
    std::string m_name;
    bool m_hasParent;
    bool m_closed{ false };
    bool m_unlocked;
    bool m_hasPages;
    int m_size;
    int m_firstIndex;
    std::deque<ItemPtr> m_items;
};
