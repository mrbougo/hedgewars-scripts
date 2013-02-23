----------------------------------------------------------------------------------
--Barrel mudball:
--Mudballs are replaced by barrels when launched while pressing the precise
--button. Plenties of fun!
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

local precise = false;

function onGearAdd(gear)
	if GetGearType(gear) == gtSnowball and precise then
		local newgear = AddGear(0, 0, gtExplosives, 0, 0, 0, 0)
		CopyPV(gear, newgear)
		DeleteGear(gear)
	end
end

function onPrecise()
	precise = true
end

function onPreciseUp()
	precise = false
end
