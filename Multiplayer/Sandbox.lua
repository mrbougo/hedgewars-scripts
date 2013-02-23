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

-----------CONFIG-----------
--end turn after replaced teleport
local endturn = false

local mineFountainMines = 100
local mineFountainDelta = 70
local mineFountainMaxV = 100000
--------END OF CONFIG-------

--not gear types
local nogtMineFountain = -1

local precise = false
local teleport = nil

local itemnames = { "Barrel", "Mine", "Flame", "Mine Fountain" }
local items     = { gtExplosives, gtMine, gtFlame, nogtMineFountain }

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

----random "real" number. I do not trust this to not desync
--function randomReal()
--	return GetRandom(5001)/5000
--end

local selidx = 1
function chSelector(dir)
	selidx = 1 + (selidx + dir - 1) % #items
	AddCaption(itemnames[selidx])
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
	--in terms of real numbers: t = (randomReal() * pi/2) - pi/4
	--here t is 10000 times too large and t*t 100000000 too large
	local t = GetRandom(15709) - 7854
	x = quotient(ampl * t, 10000)
	y = quotient(ampl * (10000 - t*t), 100000000)

	return x,y
end

local mineFountainTime = 0
local mineFountainCnt = 0
local mineFountainPos = { 0, 0 }
function mineFountainThink()
	if mineFountainCnt <= 0 then return end

	-- count down one frame
	mineFountainTime = mineFountainTime - 1
	if mineFountainTime > 0 then return end

	local tx,ty = unpack(mineFountainPos)
	local vx,vy
	if mineFountainMaxV > 0 then
		-- the following does not work due to floating point arithmetic being
		-- architecture-dependant and thus causing desync:
		--local v = mineFountainMaxV -- * randomReal()
		----upwards only
		----first order taylor expansion around pi/2: angle = pi/2 - t, t in [-pi/4,pi/4]
		--local t = 3.1416 * (randomReal() * 2 - 1) / 4
		----cos
		--vx = v * t
		----sin * (-1)
		--vy = -v * (1 - t*t / 2)

		vx,vy = upQuadVector(mineFountainMaxV)
	else
		vx = 0
		vy = 0
	end

	--AddCaption("spawning mine: ".. tx..","..ty)
	local mine = AddGear(tx, ty, gtMine, 0, vx, vy, 0)
	mineFountainCnt = mineFountainCnt - 1

	--reset frame counter
	mineFountainTime = mineFountainDelta + 1
end

function mineFountainPlace(x, y)
	if mineFountainCnt > 0 then
		--remove mine fountain
		mineFountainCnt = 0
	else
		--AddCaption("placing mine fountain: ".. x..","..y)
		mineFountainPos = { x, y }
		mineFountainCnt = mineFountainMines
		mineFountainTime = mineFountainDelta + 1
	end
end

function teleportThink()
	if teleport == nil then return end

	--AddCaption(GetState(teleport) .. ", " .. GetGearMessage(teleport))
	local tx,ty = GetGearTarget(teleport)

	if items[selidx] == nogtMineFountain then
		mineFountainPlace(tx, ty)
	else
		local newgear = AddGear(tx, ty, items[selidx], 0, 0, 0, 0)
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
	teleportThink()
	switchThink()

	mineFountainThink()
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

function onUp()
	if GetCurAmmoType() == amTeleport then
		chSelector(1)
	end
end

function onDown()
	if GetCurAmmoType() == amTeleport then
		chSelector(-1)
	end
end