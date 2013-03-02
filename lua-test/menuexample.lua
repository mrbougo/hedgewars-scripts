dofile("../Menu.lua");

local settings = {};
local data = {};

local mainmenu = Menu:new("Main menu", {
	ItemBool:new("testy bool", settings, 'testbool'),
	ItemInt:new("testy int", settings, 'testint', -3, 5),
	ItemInt:new("testy int2", settings, 'testint2', -3, 5),
	ItemSelector:new("field to print", data, 'field', {'testbool','testint','testint2'}),
	ItemCB:new("print field", function(d) print(tostring(settings[d.field])) end, data),
	ItemCB:new("print 'test'", function() print('test') end)
	});

menuEnter(mainmenu);

while true do
	menuPrint();
	local chr = string.sub(io.read(),1,1);
	if chr == 'q' then break end;

	if chr == 'k' then menuUp() end;
	if chr == 'j' then menuDown() end;

	if chr == 'l' then menuRight() end;
	if chr == 'h' then menuLeft() end;
end
