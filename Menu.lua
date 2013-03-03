local menuStack = {}
local menuCur = nil

function menuEnter(m)
	--check if menu is in the stack, pop everything on top if found
	local found = false
	for i,sm in ipairs(menuStack) do
		if found then
			menustack[i] = nil
		elseif m == sm then
			found = true
		end
	end

	--if it was not found, push it
	if not found then
		table.insert(menuStack,m)
	end

	menuCur = m
end

function menuStackPop(m)
	local pos = #menuStack
	menuStack[pos] = nil
	menuCur = menuStack[pos-1]
end

-------------------------------------------------------------------------------
--simple OO class thing, inspired by http://lua-users.org/wiki/SimpleLuaClasses
-------------------------------------------------------------------------------
do
	local isa = function(self, class)
			local mt = getmetatable(self)
			while mt do
				if mt == class then return true end
				mt = mt._base
			end
			return false
		end

	function class(base, init)
		local theclass = {}

		if not init and type(base) == 'function' then
			--one-argument version: class(init)
			init = base
			base = nil
		elseif type(base) == 'table' then
			--inheritance
			setmetatable(theclass, base)
			theclass._base = base
		end

		--the class' objects will have the class as metatable
		theclass.__index = theclass

		function theclass:new(...)
			local o = {}
			setmetatable(o,self)

			if init then
				init(o, ...)
			elseif base and base.init then
				base.init(o, ...)
			end

			return o
		end

		theclass.init = init
		theclass.isa = isa

		return theclass
	end
end

----------------------------------------------
--Menu class: instances hold items in an array
----------------------------------------------
Menu = class(
	function(o,title,items)
		o.title = title
		o.items = items
		o.pos = 1
	end)

function Menu:print()
	print(self.title)
	print(string.rep("-", string.len(self.title)))
	print()

	print(self:contents())
end

function Menu:contents(lbr)
	local i,item
	local out, marker, line
	local delim
	lbr = lbr or "\n"

	out = ""
	delim = ""
	for i,item in ipairs(self.items) do
		if type(item) == 'string' then
			line = item
		else
			line = item:_line()
		end

		if line then
			marker = (i == self.pos) and ">" or " "
			out = out .. delim .. marker .. line
			delim = lbr
		end
	end

	return out
end

function Menu:len()
	return #self.items
end

function Menu:down()
	--1-indexed
	--self.pos = 1+(self.pos-1+1)%self.length
	self.pos = 1 + self.pos%self:len()
end
function Menu:up()
	self.pos = 1 + (self.pos-2)%self:len()
end
function Menu:right()
	self.items[self.pos]:right()
end
function Menu:left()
	self.items[self.pos]:left()
end


--------------------------
--Item and derived classes
--------------------------
--Parent item class: text only, not interactive.
EVENT_LEFT  = 1
EVENT_RIGHT = 2

Item = class(
	function(o,text)
		o.text = text
		o.enabled = true
		o.hidden = false
	end)
function Item:enable() self.enabled=true end
function Item:disable() self.enabled=false end
function Item:hide() self.hidden=true end
function Item:unhide() self.hidden=false end
function Item:_event(ev)
	if self.cb then self.cb(self,ev,self.cbdata) end
end
function Item:left()  self:_event(EVENT_LEFT) end
function Item:right() self:_event(EVENT_RIGHT) end
function Item:connect(cb, data)
	assert(not self.cb)  --error if already connected
	print('connected'..tostring(cb))
	self.cb = cb
	self.cbdata = data
end
function Item:disconnect()
	self.cb = nil
	self.cbdata = nil
end
function Item:display() return "" end
function Item:_line()
	local out
	local rightout
	if self.hidden then return nil end

	if not self.enabled then
		out = '('..self.text..')'
	else
		out = self.text
	end

	rightout = self:display()
	if rightout then
		return out .. '       ' .. rightout
	else
		return out
	end
end

--Menu item: enters a submenu by making self.menu the top of the stack.
--Untested.
ItemMenu = class(
	function(o,text,menu)
		Item.init(o, text or menu.title)
		o.menu = menu
	end)
function ItemMenu:right()
	menuEnter(self.menu)
	Item.right(self)
end
function ItemMenu:display()
	if self.enabled then
		return '>>>'
	else
		return '>XX'
	end
end

--Setting item: sets a value in a given table, parent class of more useful
--setting items.
ItemSetting = class(Item,
	function(o, text, table, key)
		Item.init(o, text)
		o.table = table
		o.key = key
	end)
function ItemSetting:set()
	self.table[self.key] = self.value
end
function ItemSetting:string()
	return self.value
end
function ItemSetting:display()
	if self.enabled then
		return '< ' .. self:string() .. ' >'
	else
		return 'x ' .. self:string() .. ' x'
	end
end

--Selector setting item: select a value from a given list.
--If a value in the list is a table, it is displayed as its first element (a
--string) while the actual value is held in its second element.
ItemSelector = class(ItemSetting,
	function(o, text, table, key, values, start)
		ItemSetting.init(o,text,table,key)
		o.values = values
		--starting value provided or first found
		o.pos = start or 1
		o:updateValue()
	end)
function ItemSelector:left()   --see Menu:down/up
	if self.enabled then
		self.pos = 1+(self.pos-2)%#self.values
		self:updateValue()
	end
	Item.left(self)
end
function ItemSelector:right()  --see Menu:down/up
	if self.enabled then
		self.pos = 1+self.pos%#self.values
		self:updateValue()
	end
	Item.right(self)
end
function ItemSelector:updateValue()
	local val = self.values[self.pos]
	if type(val) == 'table' then
		self.valuestr = val[1]
		self.value = val[2]
	else
		self.valuestr = val
		self.value = val
	end

	self:set()
end
function ItemSelector:string()
	return self.valuestr
end

--Boolean setting item: an true/false selector.
ItemBool = class(ItemSelector,
	function(o, text, table, key, start)
		ItemSelector.init(o,text,table,key, {{"True",true},{"False",false}}, (start and 1 or 2))
	end)

--Integer setting item: selects an integer in a given, inclusive range.
ItemInt = class(ItemSetting,
	function(o, text, table, key, min, max, start)
		ItemSetting.init(o,text,table,key)
		o.min = min
		o.max = max
		o.value = start or min
		o:set()
	end)
function ItemInt:left()
	if self.enabled then
		self.value = self.min + (self.value - self.min - 1)%(self.max - self.min + 1)
		self:set()
	end
	Item.left(self)
end
function ItemInt:right()
	if self.enabled then
		self.value = self.min + (self.value - self.min + 1)%(self.max - self.min + 1)
		self:set()
	end
	Item.right(self)
end

--Callback item: calls a function with some data as argument.
ItemCB = class(Item,
	function(o, text, cb, data)
		Item.init(o, text)
		--drop self and event information
		o:connect(function(s,ev,data) if ev==EVENT_RIGHT and s.enabled then cb(data) end end, data)
	end)
function ItemCB:display()
	if self.enabled then
		return "**"
	else
		return "--"
	end
end


-------------------------------------------
--Functional interface to the object system
-------------------------------------------
function menuPrint() menuCur:print() end
function menuTitle() return menuCur.title end
function menuContents(...) return menuCur:contents(...) end

--key event handlers
function menuUp() menuCur:up() end
function menuDown() menuCur:down() end
function menuRight() menuCur:right() end
function menuLeft() menuCur:left() end
