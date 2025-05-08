local Memory = {containers = {__size = 0}}
_G._allobjects.__MemoryContainers = {__size = 0}
local garbagelimit = 1000
local Container = {
    __indices = {},
    __keyindices = {},
    __keys = {__size = 0,},
    __garbage = 0,
    name = "UNNAMED",
    __config = {draw = false, update = false}
}
Container.__index = Container
_c_todo{"03/20/2025","Container: add iterative functions and uses to __keyindices and __indices, otherwise the point of having these is moot", 
"Add debug output to validate the memory expenditure of a container before and after release"}
--- @param n any key, index, or value
--- add a value. To add an accessibly value n must be a string and v must be a value, 
--- otherwise it will be added to __indices as an inaccessible iterative value (this should only be used with anonymous
--- values which should be iterated quickly. To add accessible values use keys, and to iterate them use .__keyindices
function Container:add(n,v)
    if not v then   --we're putting it in __indices
        self.__indices[#self.__indices+1] = n
    elseif type(n,"number") then    --we're putting it in __indices
        self.__indices[n] = v
    elseif type(n)=="string" and v then   --we're putting it in __keys
        if not self.__keys[n] then  --adding a new value, thus incrementing size
            self.__keys.__size = self.__keys.__size + 1
        else    --overwriting a value, thus creating garbage in the index list
            type_print(self,true)
            _c_warn("Container:add() called on key that is already occupied! Releasing old item from memory. Key: "..tostring(n).." old value: "..tostring(self.__keys[n]).." new value: "..tostring(v))
            if type(self.__keys[n],"table") then _safe.release(self.__keys[n]) end
            self.__garbage = self.__garbage + 1
        end
        self.__keys[n] = v
        self.__keyindices[#self.__keyindices+1] = n
    else    --throw error
        _c_warn("warning, Memory Container "..tostring(self.name)..":add() called with invalid key value pair!", 4)
    end

    self:checksort()
end
--- @param t ?any can be left blank and will report both __keys as well as __indices.
function Container:report(t)    --TODO: add a function that greps memory USAGE maybe? per item?
    local keys, indices,reported
    if not t then --we're reporting defaults
        keys,indices = true,true
    elseif t == "keys" then
        keys = true
    elseif t == "indices" or t == "index" then
        indices = true
    elseif type(t) == "string" then --safecall pass the report command through to a specific key in __keys. Useful for pulling down data through a system.
        local item = self.__keys[t]
        if item then
            if type(item,"table") then
                if not _safe.call("report",item) then
                    _c_warn("problem with container:report() in "..self.name.." passthrough to "..t..": report() does not exist on this object!")
                else
                    reported = true
                end
            else
                _c_warn("problem with container:report() in "..self.name.." passthrough to "..t..": object is not a table!")
            end
        else
            _c_warn("problem with container:report() in "..self.name.." passthrough to "..t..": object does not exist on this container!")
        end
    end
    if keys or indices then
        local r = {"Report on Memory Container: "..self.name.."]"}
        local title = "["
        if keys then
            title = title.."Key "
            local item
            for i,v in ipairs(self.__keyindices) do
                item = self.__keys[v]
                table.insert(r,tostring(v).." : "..type_print(item,false,true))
            end    
        end
        if indices then
            if #title > 0 then
                title = title.."& Index "
            else
                title = title.."Index "
            end
            for i,v in ipairs(self.__indices) do
                table.insert(r,tostring(v).." : "..type_print(v,false,true))
            end
        end
        r[1] = title..r[1]
        _c_message({r,newline = true})
        reported = true
    end

    if not reported then _c_warn("problem with container:report() in "..self.name.." : Report failed!") end

    return reported
end

--- @param n any key or index. Value reference gets removed from the Container but does not touch the memory if it exists elsewhere
function Container:_remove(n)
    if type(n) == "number" then
        self.__indices[n] = "%REMOVED"
        self.__garbage = self.__garbage + 1
    elseif self.__keys[n] then
        self.__keys[n] = nil
        self.__keys.__size = self.__keys.__size - 1
        self.__garbage = self.__garbage + 1
    else
        type_print(self,true)
        _c_warn("Container:_remove() called with invalid or already-removed index/key: "..tostring(n))
    end
    self:checksort()
end
--- determines if Container needs sorting, that's all. check against garbagelimit.
function Container:checksort()
    if self.__garbage > garbagelimit then self:sort() end
end
--- rebuilds __indices and __keyindices. __keys do not need rebuilt as they are not iterated.
function Container:sort()
    local _newinds, _newkeyinds = {},{}
    for i,v in ipairs(self.__indices) do
        if v ~= "%REMOVED" then _newinds[#_newinds+1] = v end
    end
    for _,k in ipairs(self.__keyindices) do
        if self.__keys[k] then _newkeyinds[#_newkeyinds+1] = k end
    end
    self.__indices, self.__keyindices = _newinds, _newkeyinds
    self.__garbage = 0
end
--- releases from memory. Will iterate __keys via __keyindices as well as __indices to check if anything referenced is an object to be destroyed.
--- Note: this IS destructive for those objects! If that object exists anywhere else in memory it will still call its destroy function, which may cause
--- Breakages if a reference to it, or part of it, still exists. Please note that objects should never be instantiated in more than one Container at a time, to avoid this.
function Container:release()
    for i,v in ipairs(self.__indices) do
        self.__indices[i] = nil
        if type(v) == "table" then _safe.release(v) end
    end
    local k
    for i,v in ipairs(self.__keyindices) do
        if type(self.__keys[v])=="table" then _safe.release(self.__keys[v]) end
        self.__keys[v] = nil
        self.__keyindices[i] = "%REMOVED"
    end
    self.__keys = nil
    self.__keyindices = nil
    self.__indices = nil
    _G._allobjects.__MemoryContainers[self] = nil
    _G._allobjects.__MemoryContainers.__size = _G._allobjects.__MemoryContainers.__size - 1
end
function Container:generateName(name)
    name = name or "UnnamedMemoryContainer"
    local mode = Game:getMode(false)
    local time = tostring(love.timer.getTime())
    return "gamemode_"..mode.."_MemoryContainer: "..name.."_".."instantiated:"..time
end
--[[
name becomes:  gamemode_test_MemoryContainer:Splash_Gamestate_TopLevelMemoryContainer__instantiated:1.9408803

we might want to do some parsing of this or make it into its own metadata object
]]


--- Creates a new, empty, Memory Container
function Container:new(name)
    name = self:generateName(name)
    print("container: new, name = ",name)
    local c = {}
    for k,v in pairs(self) do
        if type(k) == "function" then
            c[k] = v
        else
            if type(v) == "table" then
                c[k] = {}
                c[k] = tablex.overlay(c[k],v)
            else
                c[k] = gcore.var.shallowcopy(v)
            end
        end
    end
    gcore.container.assignType(c,"MemContainer",name)
    c.super = self
    c.name = c.__name
    setmetatable(c,self)
    _G._allobjects.__MemoryContainers[c] = c
    _G._allobjects.__MemoryContainers.__size = _G._allobjects.__MemoryContainers.__size + 1
    return c
end

---@param key string
---@param value any
---Use exclusively for accessible key value pairs, not for indexing. Will catch attempted indices and throw warnings.
function Container:set(key,value)
    if not value then value = true end
    if not self.__keys[key] then self:add(key,value)
    elseif type(key,"number") then _c_warn("Container:set called on an index! set and unset can only be used on key value pairs!")
    else self.__keys[key] = value end
end

---@param key string
---Again, should only be used regarding key values. Changes that key to a boolean equal to false. Will skip if the key never existed. Will catch indexing attempts.
function Container:unset(key)
    if key == "__size" then _c_stop("Container:unset called with __size as key. Investigate why.") end
    if self.__keys[key] then    --if the key doesn't exist then we will ignore. This will be useful in situations where a system makes a generic call to unset a field to multiple objects, some of which may not have that field. 
        self.__keys[key] = false
    else
        _c_warn("container:unset called on an uninitialized value. Make sure a boolean is not being evaluated here and that this call remains generic!")
    end
end

---@param key string
---@param compare any
---Always returns true or false. 
function Container:check(key,compare)
    compare = compare or true
    return self.__keys[key] == compare
end

---@param key string
---Always returns the key value in __keys and never indices
function Container:get(key)
    return self.__keys[key]
end

---All configurations are false to start, thus when this is run it simply sets them to true. 
---In the future, we might make this more robust. I don't think it's needed for now.
function Container:configure(...)
    for _, v in ipairs({...}) do
        self.__config[v] = true
    end
end

function Container:update(dt)
    if self.__config.update then
        local item
        for _,key in ipairs(self.__keyindices) do
            item = self.__keys[key]
            if type(item,"table") then
                _safe.call(item.update,item,dt)
            end
        end
        for _,i in ipairs(self.__indices) do
            if type(i,"table") then
                _safe.call(i.update,i,dt)
            end
        end
    end
end
function Container:draw()
    if self.__config.draw then
        local item
        for _,key in ipairs(self.__keyindices) do
            item = self.__keys[key]
            if type(item,"table") then
                _safe.call(item.draw,item)
            end
        end
        for _,i in ipairs(self.__indices) do
            if type(i,"table") then
                _safe.call(i.draw,i)
            end
        end
    end
end

function Memory:update(dt)  --this may only be used during debugging probably

end

function Memory:new(name)
    local container = Container:new(name)
    self:add(container)
    return container
end

function Memory:add(container)
    if type(container, "MemContainer") then
        if self.containers[container] then  --this should almost never happen
            _c_warn("Memory:add(container) called with already instantiated container!! Check for instantiation loss.")
        else
            self.containers.__size = self.containers.__size + 1
        end
        self.containers[container] = container
        self.containers[#self.containers+1] = self.containers[container]
        container.__index = #self.containers
    else
        _c_warn("Memory:add called with invalid container! Container:")
        type_print(container,true)
    end
end

function Memory:report()    --report on memory usage


end


function Memory:release(container)
    if self.containers[container] then
        self.containers[container.__index] = nil
        self.containers[container] = nil
        container:release()
        self.containers.__size = self.containers.__size - 1
    else
        _c_warn("Memory:release called on non-tracked or non-existent container! Container:")
        type_print(container,true)
    end
end


return Memory