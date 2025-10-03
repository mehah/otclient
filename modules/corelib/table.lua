-- @docclass table
function table.dump(t, depth)
    if not depth then
        depth = 0
    end
    for k, v in pairs(t) do
        str = (' '):rep(depth * 2) .. k .. ': '
        if type(v) ~= 'table' then
            print(str .. tostring(v))
        else
            print(str)
            table.dump(v, depth + 1)
        end
    end
end

function table.clear(t)
    for k, v in pairs(t) do
        t[k] = nil
    end
end

function table.copy(t)
    local res = {}
    for k, v in pairs(t) do
        res[k] = v
    end
    return res
end

function table.recursivecopy(t)
    local res = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            res[k] = table.recursivecopy(v)
        else
            res[k] = v
        end
    end
    return res
end

function table.selectivecopy(t, keys)
    local res = {}
    for i, v in ipairs(keys) do
        res[v] = t[v]
    end
    return res
end

function table.merge(t, src)
    for k, v in pairs(src) do
        t[k] = v
    end
end

function table.find(t, value, lowercase)
    for k, v in pairs(t) do
        if lowercase and type(value) == 'string' and type(v) == 'string' then
            if v:lower() == value:lower() then
                return k
            end
        end
        if v == value then
            return k
        end
    end
end

function table.findbykey(t, key, lowercase)
    for k, v in pairs(t) do
        if lowercase and type(key) == 'string' and type(k) == 'string' then
            if k:lower() == key:lower() then
                return v
            end
        end
        if k == key then
            return v
        end
    end
end

function table.contains(t, value, lowercase)
    return table.find(t, value, lowercase) ~= nil
end

function table.findkey(t, key)
    if t and type(t) == 'table' then
        for k, v in pairs(t) do
            if k == key then
                return k
            end
        end
    end
end

function table.haskey(t, key)
    return table.findkey(t, key) ~= nil
end

function table.removevalue(t, value)
    for k, v in pairs(t) do
        if v == value then
            table.remove(t, k)
            return true
        end
    end
    return false
end

function table.popvalue(value)
    local index = nil
    for k, v in pairs(t) do
        if v == value or not value then
            index = k
        end
    end
    if index then
        table.remove(t, index)
        return true
    end
    return false
end

function table.compare(t, other)
    if #t ~= #other then
        return false
    end
    for k, v in pairs(t) do
        if v ~= other[k] then
            return false
        end
    end
    return true
end

function table.empty(t)
    if t and type(t) == 'table' then
        return next(t) == nil
    end
    return true
end

function table.permute(t, n, count)
    n = n or #t
    for i = 1, count or n do
        local j = math.random(i, n)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function table.findbyfield(t, fieldname, fieldvalue)
    for _i, subt in pairs(t) do
        if subt[fieldname] == fieldvalue then
            return subt
        end
    end
    return nil
end

function table.size(t)
    local size = 0
    for i, n in pairs(t) do
        size = size + 1
    end

    return size
end

function table.tostring(t)
    local maxn = #t
    local str = ''
    for k, v in pairs(t) do
        v = tostring(v)
        if k == maxn and k ~= 1 then
            str = str .. ' and ' .. v
        elseif maxn > 1 and k ~= 1 then
            str = str .. ', ' .. v
        else
            str = str .. ' ' .. v
        end
    end
    return str
end

function table.collect(t, func)
    local res = {}
    for k, v in pairs(t) do
        local a, b = func(k, v)
        if a and b then
            res[a] = b
        elseif a ~= nil then
            table.insert(res, a)
        end
    end
    return res
end

function table.insertall(t, s)
    for k, v in pairs(s) do
        table.insert(t, v)
    end
end

function table.equals(t, comp)
    if type(t) == 'table' and type(comp) == 'table' then
        for k, v in pairs(t) do
            if v ~= comp[k] then
                return false
            end
        end
    end
    return true
end

function table.equal(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not table.equal(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not table.equal(v1, v2) then return false end
    end
    return true
end

function table.isList(t)
    local size = #t
    return table.size(t) == size and size > 0
end

function table.isStringList(t)
    if not table.isList(t) then return false end
    for k, v in ipairs(t) do
        if type(v) ~= 'string' then
            return false
        end
    end
    return true
end

function table.isStringPairList(t)
    if not table.isList(t) then return false end
    for k, v in ipairs(t) do
        if type(v) ~= 'table' or #v ~= 2 or type(v[1]) ~= 'string' or type(v[2]) ~= 'string' then
            return false
        end
    end
    return true
end

function table.encodeStringPairList(t)
    local ret = ""
    for k, v in ipairs(t) do
        if v[2]:find("\n") then
            ret = ret .. v[1] .. ":[[\n" .. v[2] .. "\n]]\n"
        else
            ret = ret .. v[1] .. ":" .. v[2] .. "\n"
        end
    end
    return ret
end

function table.decodeStringPairList(l)
    local ret = {}
    local r = regexMatch(l, "(?:^|\\n)([^:^\n]{1,20}):?(.*)(?:$|\\n)")
    local multiline = ""
    local multilineKey = ""
    local multilineActive = false
    for k, v in ipairs(r) do
        if multilineActive then
            local endPos = v[1]:find("%]%]")
            if endPos then
                if endPos > 1 then
                    table.insert(ret, { multilineKey, multiline .. "\n" .. v[1]:sub(1, endPos - 1) })
                else
                    table.insert(ret, { multilineKey, multiline })
                end
                multilineActive = false
                multiline = ""
                multilineKey = ""
            else
                if multiline:len() == 0 then
                    multiline = v[1]
                else
                    multiline = multiline .. "\n" .. v[1]
                end
            end
        else
            local bracketPos = v[3]:find("%[%[")
            if bracketPos == 1 then -- multiline begin
                multiline = v[3]:sub(bracketPos + 2)
                multilineActive = true
                multilineKey = v[2]
            elseif v[2]:len() > 0 and v[3]:len() > 0 then
                table.insert(ret, { v[2], v[3] })
            end
        end
    end
    return ret
end

function table.remove_if(t, fnc)
    local j, n = 1, #t;
    for i = 1, n do
        if not fnc(i, t[i]) then
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1;
        else
            t[i] = nil;
        end
    end
    return t;
end

-- table.watchList
-- Watches an array-like table (1..N) for structural changes.
-- Detects inserts, removes and moves between scans.
-- Keys can be taken from ops.keyOf(item) or by default the item reference itself.
-- initial inserts can be emitted via ops.initialScan = true or w:scan(true).
function table.watchList(realList, ops)
  local self = {}
  local keyOf      = (ops and ops.keyOf) or function(x) return x end
  local beginBatch = ops and ops.beginBatch
  local endBatch   = ops and ops.endBatch
  local onInsert   = ops and ops.onInsert
  local onRemove   = ops and ops.onRemove
  local onMove     = ops and ops.onMove

  self.list  = realList
  self.prev  = {}
  self.prevK = {}

  for i = 1, #realList do
    self.prev[i]  = realList[i]
    self.prevK[i] = keyOf(realList[i])
  end

  local function copyKeys(src)
    local dst = {}
    for i = 1, #src do dst[i] = src[i] end
    return dst
  end

  local function buildIndexMap(keys)
    local m = {}
    for i = 1, #keys do m[keys[i]] = i end
    return m
  end

  function self:scan(initial)
    if initial then
      if beginBatch then beginBatch() end
      if onInsert then
        for i = 1, #self.list do
          onInsert(i, self.list[i])
        end
      end
      if endBatch then endBatch() end
      return
    end

    local curr = self.list
    local wantK = {}
    for i = 1, #curr do wantK[i] = keyOf(curr[i]) end

    if beginBatch then beginBatch() end

    local curK = copyKeys(self.prevK)
    local idxByKey = buildIndexMap(curK)

    local i = 1
    while i <= #wantK do
      local want = wantK[i]
      if curK[i] == want then
        i = i + 1
      else
        local j = idxByKey[want]
        if j then
          if onMove then onMove(j, i, curr[i]) end
          local movedKey = table.remove(curK, j)
          table.insert(curK, i, movedKey)
          if j > i then
            for p = i + 1, j do idxByKey[curK[p]] = p end
          else
            for p = j, i do idxByKey[curK[p]] = p end
          end
          idxByKey[movedKey] = i
          i = i + 1
        else
          if onInsert then onInsert(i, curr[i]) end
          table.insert(curK, i, want)
          for p = i, #curK do idxByKey[curK[p]] = p end
          i = i + 1
        end
      end
    end

    for k = #curK, #wantK + 1, -1 do
      if onRemove then onRemove(k, self.prev[k]) end
      idxByKey[curK[k]] = nil
      table.remove(curK, k)
    end

    if endBatch then endBatch() end

    self.prev  = {}
    for k = 1, #curr do self.prev[k] = curr[k] end
    self.prevK = wantK
  end

  if ops and ops.initialScan then
    self:scan(true)
  end

  return self
end