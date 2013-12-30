----------------------------------------------------------------------------------
--Sandbox mode:
--Unlimited fun! Select teleport, press up/down to select an item, then click
--while pressing shift. You can also throw barrels by launching mudballs while
--pressing shift.
--
--Copyright 2012, 2013 by MrBougo <bougospam@gmail.com>
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
----------------------------------------------------------------------------------

HedgewarsScriptLoad("/Scripts/Menu.lua");

-----------CONFIG-----------
--Runtime config
local settings = {};

--Hard config
--end turn after replaced teleport
local endturn = false

local fountainDelta = 70
--------END OF CONFIG-------

--Constants
--Fountain items and names
local itemValues = {
{"gtGrenade"        , gtGrenade},
{"gtHedgehog"       , gtHedgehog},  --causes crashes
{"gtShell"          , gtShell},
{"gtGrave"          , gtGrave},
{"gtBee"            , gtBee},  --bee disappears when entering seeking mode, falls into water somewhere
{"gtShotgunShot"    , gtShotgunShot},  --no trajectory
{"gtPickHammer"     , gtPickHammer},  --funny glitch
{"gtRope"           , gtRope},  --no rope
{"gtMine"           , gtMine},
{"gtCase"           , gtCase},  --case portal, but no case
{"gtDEagleShot"     , gtDEagleShot},  --no trajectory, big damage when spawned on a hog
{"gtDynamite"       , gtDynamite},
{"gtClusterBomb"    , gtClusterBomb},
{"gtCluster"        , gtCluster},  --no detonation force?
{"gtShover"         , gtShover},  --30 damage when spawned on hog, what is this?
{"gtFlame"          , gtFlame},
{"gtFirePunch"      , gtFirePunch},
{"gtATStartGame"    , gtATStartGame},  --does nothing?
{"gtATFinishGame"   , gtATFinishGame},  --does nothing?
{"gtParachute"      , gtParachute},  --no effect?
{"gtAirAttack"      , gtAirAttack},  --plane doesn't drop a thing, sound ends abruptly
{"gtAirBomb"        , gtAirBomb},
{"gtBlowTorch"      , gtBlowTorch},
{"gtGirder"         , gtGirder},  --can't place
{"gtTeleport"       , gtTeleport},  --appears to work normally
{"gtSwitcher"       , gtSwitcher},  --spawns switch sprite, no effect?
{"gtTarget"         , gtTarget},
{"gtMortar"         , gtMortar},
{"gtWhip"           , gtWhip},  --same as desert eagle
{"gtKamikaze"       , gtKamikaze},
{"gtCake"           , gtCake},  --multiple cakes have glitchy visuals
{"gtSeduction"      , gtSeduction},  --excellent in fountain mode
{"gtWatermelon"     , gtWatermelon},
{"gtMelonPiece"     , gtMelonPiece},
{"gtHellishBomb"    , gtHellishBomb},
{"gtWaterUp"        , gtWaterUp},  --raises water (by how much?)
{"gtDrill"          , gtDrill},
{"gtBallGun"        , gtBallGun},
{"gtBall"           , gtBall},
{"gtRCPlane"        , gtRCPlane},  --a bit buggy, plane doesn't move and input weirdness
{"gtSniperRifleShot", gtSniperRifleShot},  --see shotgun
{"gtJetpack"        , gtJetpack},  --lifts the hog a little
{"gtMolotov"        , gtMolotov},
{"gtExplosives"     , gtExplosives},
{"gtBirdy"          , gtBirdy},  --weird
{"gtEgg"            , gtEgg},  --sounds nice
{"gtPortal"         , gtPortal},  --just a portal blob, needs velocity
{"gtPiano"          , gtPiano},  --can spawn multiple, hedgehog dies
{"gtGasBomb"        , gtGasBomb},
{"gtSineGunShot"    , gtSineGunShot},  --crashes immediately
{"gtFlamethrower"   , gtFlamethrower},
{"gtSMine"          , gtSMine},
{"gtPoisonCloud"    , gtPoisonCloud},  --can be given velocity
{"gtHammer"         , gtHammer},  --66 damage?
{"gtHammerHit"      , gtHammerHit},  --draws a gray rectangle on terrain??
{"gtResurrector"    , gtResurrector},  --only the effect
{"gtNapalmBomb"     , gtNapalmBomb},
{"gtSnowball"       , gtSnowball},  --spawns as a barrel when shift is pressed because of mod
{"gtFlake"          , gtFlake},  --background effect, doesn't seem affected by velocity?
{"gtStructure"      , gtStructure},  --wat.
{"gtLandGun"        , gtLandGun},
{"gtTardis"         , gtTardis}  --can freeze the engine if spammed!
}
--Fountain-able item lookup table
local fountainable={}
do
	local fitems = {gtGrenade,gtHedgehog,gtShell,gtGrave,gtBee,gtShotgunShot,gtPickHammer,gtRope,gtMine,gtCase,gtDEagleShot,gtDynamite,gtClusterBomb,gtCluster,gtShover,gtFlame,gtFirePunch,gtATStartGame,gtATFinishGame,gtParachute,gtAirAttack,gtAirBomb,gtBlowTorch,gtGirder,gtTeleport,gtSwitcher,gtTarget,gtMortar,gtWhip,gtKamikaze,gtCake,gtSeduction,gtWatermelon,gtMelonPiece,gtHellishBomb,gtWaterUp,gtDrill,gtBallGun,gtBall,gtRCPlane,gtSniperRifleShot,gtJetpack,gtMolotov,gtExplosives,gtBirdy,gtEgg,gtPortal,gtPiano,gtGasBomb,gtSineGunShot,gtFlamethrower,gtSMine,gtPoisonCloud,gtHammer,gtHammerHit,gtResurrector,gtNapalmBomb,gtSnowball,gtFlake,gtStructure,gtLandGun,gtTardis}
	for i=1, #fitems do
		fountainable[fitems[i]] = true
	end
end

local precise = false
local teleport = nil

local switchcnt = 0


function direction(x,y,nr)
	if not nr then
		nr = 1
	end

	--FIXME: using math.sqrt for non-visual gears probably causes desync
	local r = math.sqrt(x*x + y*y)

	-- this is a dev thing
	--local nx = div(x*nr, r)
	--local ny = div(y*nr, r)
	local nx = x*nr/r
	local ny = y*nr/r

	return nx, ny
end

--integer division (assuming positive arguments)
function quotient(p,q)
	return (p - p%q)/q
end

--returns the integer components of a random vector of approx. ampl length in
--the [pi/4, 3pi/4] quadrant
function upQuadVector(ampl)
	local x,y
	--pi/2 == 15708 / 10 000
	--pi/4 ==  7854 / 10 000
	--in terms of real numbers: t = (math.random() * pi/2) - pi/4
	--here t is 10000 times too large and t*t 100000000 too large
	local t = GetRandom(15709) - 7854
	x = quotient(ampl * t, 10000)
	y = quotient(ampl * (10000 - t*t), 100000000)

	return x,y
end

local fountainGear = 0
local fountainTime = 0
local fountainCnt = 0
local fountainPos = { 0, 0 }
function fountainThink()
	if fountainCnt <= 0 then return end

	-- count down one frame
	fountainTime = fountainTime - 1
	if fountainTime > 0 then return end

	local tx,ty = unpack(fountainPos)
	local vx,vy
	if settings.fountainVel > 0 then
		vx,vy = upQuadVector(settings.fountainVel*1000)
	else
		vx = 0
		vy = 0
	end

	--AddCaption("spawning fountain gear: ".. tx..","..ty)
	local gear = AddGear(tx, ty, fountainGear, 0, vx, vy, 0)
	fountainCnt = fountainCnt - 1

	--reset frame counter
	fountainTime = fountainDelta + 1
end

function fountainPlace(gear, x, y)
	if fountainCnt > 0 then
		--remove fountain
		fountainCnt = 0
	else
		--AddCaption("placing fountain: ".. x..","..y)
		fountainGear = gear
		fountainPos = { x, y }
		fountainCnt = settings.fountainCnt
		fountainTime = fountainDelta + 1
	end
end

function teleportThink()
	if teleport == nil then return end

	--AddCaption(GetState(teleport) .. ", " .. GetGearMessage(teleport))
	local tx,ty = GetGearTarget(teleport)

	if settings.fountain and fountainable[settings.item] then
		fountainPlace(settings.item, tx, ty)
	else
		local newgear = AddGear(tx, ty, settings.item, 0, 0, 0, 0)
	end

	DeleteGear(teleport)

	if endturn then
		TurnTimeLeft = 0
	else
		--unlock hog
		SetState(CurrentHedgehog, band(GetState(CurrentHedgehog), bnot(gstAttacking)))
		SetState(CurrentHedgehog, bor(GetState(CurrentHedgehog), gstHHChooseTarget))
		--make the cursor reappear on next frame by switching to Skip then Teleport
		switchcnt = 5
	end

	teleport = nil
end

--this is an ugly hack, FIXME?
function switchThink()
	if switchcnt >= 0 then
		switchcnt = switchcnt - 1
		if     switchcnt == 2 then
			-- setweap 0 switches to hammer, not to "no weapon"?
			ParseCommand("setweap " .. string.char(amSkip))
		elseif switchcnt == 1 then
			--TODO: make sure the hog has some teleports left?
			ParseCommand("setweap " .. string.char(amTeleport))
		end
	end
end

function onGameTick()
	menuThink()
	teleportThink()
	switchThink()

	fountainThink()
end

function onGearAdd(gear)
	if GetGearType(gear) == gtTeleport and precise then
		teleport = gear  --to be removed later
	end

	if GetGearType(gear) == gtSnowball and precise then
		--local newgear = AddGear(0, 0, gtNapalmBomb, 0, 0, 0, 0)
		local newgear = AddGear(0, 0, gtExplosives, 0, 0, 0, 0)

		--CopyPV(gear, newgear)
		local vx,vy = GetGearVelocity(gear)
		-- hog radius: 9, barrel radius: 16
		local nx,ny = direction(vx,vy, 25)
		nx = nx + GetX(CurrentHedgehog)
		ny = ny + GetY(CurrentHedgehog)
		SetGearPosition(newgear, nx, ny)
		SetGearVelocity(newgear, vx, vy)
		DeleteGear(gear)
	end
end

function onPrecise()
	precise = true
end

function onPreciseUp()
	precise = false
end

----
--UI
----
local inMenu = false

function menuThink()
	if GetCurAmmoType() ~= amTeleport and inMenu then
		mHide()
	end
end

function mRefresh()
	if not inMenu then return end
	ShowMission('Menu', nil, menuContents('|'), -amBirdy, 0x7FFFFFFF)
end

function mHide()
	inMenu = false
	ShowMission(' ', nil, nil, 1, 1) --FIXME: have a mission text explaining sandbox that we can fall back to
	HideMission()
end

local miItem = ItemSelector:new("Sandbox item", settings, 'item', itemValues)
local miFountain = ItemBool:new("Fountain", settings, 'fountain', false)
local miCnt = ItemSelector:new("Fountain items", settings, 'fountainCnt', {10,20,50,100,200}, 3)
local miVel = ItemSelector:new("Fountain velocity", settings, 'fountainVel', {-100, 0, 100,200,500,1000}, 3)

miItem:connect(function(self) if fountainable[self.value] then miFountain:enable() else miFountain:disable() end end)

local menu = Menu:new("Main menu", {
	miItem,
	miFountain,
	miCnt,
	miVel,
	ItemCB:new("Exit menu", mHide)
	})
menuEnter(menu);

function onUp()
	--HogSay(CurrentHedgehog, 'up', SAY_SAY)
	if GetCurAmmoType() ~= amTeleport then return end
	if inMenu then menuUp()
	else inMenu = true end
	mRefresh()
end
function onDown()
	if GetCurAmmoType() ~= amTeleport then return end
	if inMenu then menuDown()
	else inMenu = true end
	mRefresh()
end
function onLeft()
	if GetCurAmmoType() ~= amTeleport then return end
	if inMenu then
		menuLeft()
		mRefresh()
	end
end
function onRight()
	if GetCurAmmoType() ~= amTeleport then return end
	if inMenu then
		menuRight()
		mRefresh()
	end
end

function onNewTurn()
	mHide()
end
