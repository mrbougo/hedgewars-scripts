HedgewarsScriptLoad("/Scripts/Menu.lua");

local settings = {};
local data = {};

local mainmenu = Menu:new("Main menu", {
	ItemBool:new("testy bool", settings, 'testbool'),
	ItemInt:new("testy int", settings, 'testint', -3, 5),
	ItemSelector:new("field to print", data, 'field', {'testbool','testint'}),
	ItemCB:new("print field", function(d) HogSay(CurrentHedgehog, d.field .. ': ' .. tostring(settings[d.field]), SAY_SAY) end, data),
	ItemCB:new("end game", EndGame)
	});

function mrefresh()
	ShowMission('Menu', nil, menuContents('|'), -amBirdy, 0x7FFFFFFF);
end

function onUp()    menuUp()   ; mrefresh() end
function onDown()  menuDown() ; mrefresh() end
function onRight() menuRight(); mrefresh() end
function onLeft()  menuLeft() ; mrefresh() end
function onPrecise() EndGame() end

function onGameInit()
	--SetInputMask(band(0xFFFFFFFF, bnot(gmLeft + gmRight + gmUp + gmDown)));
	SetInputMask(0);

	menuEnter(mainmenu);
end

function onGameStart()
	mrefresh();
end
