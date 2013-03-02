dofile("../Menu.lua");

local settings = {};
local data = {};

local mainmenu = Menu:new("Main menu", {
	ItemBool:new("testy bool", settings, 'testbool'),
	ItemBool:new("testy bool2", settings, 'testbool2'),
	ItemSelector:new("field to print", data, 'field', {'testbool','testbool2'}),
	ItemCB:new("print field", function(d) print(settings[d.field]) end, data)
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
