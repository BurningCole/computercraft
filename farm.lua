print('Turtle farmer V1.4.0')

local moveFuncs = require("MoveFuncs");

local waitTime=30 -- time between finishing and starting again(s)
local maxSeedsHeld={8,64};
local x=tonumber(arg[1]) or 14
local y=tonumber(arg[2]) or 5
local invertYDir = false;
--  	  _________
-- 		 [         ]
-- 		 [         ]
-- 		y[         ]
-- 		 [         ]
-- 		#[_________]   #=Turtle, plants along x axis
--            x
local seeds=2
--Turtle inventory
--[1234] 0=keep empty
--[5678] 1=main seed(will fill empty rows)
--[0000] 2+= optional extra seeds (seeds must go to lowest value)
--[0000] the turtle will keep one of each seed placed inside
local seedsOnRow={1,2,3,4,5,6,7,1,1,1,1,1} --seeds on each row, add more values for a larger y
local seedAges = {3,7};

if #seedsOnRow < y then
	for s=#seedsOnRow,(y - 1) do
		table.insert(seedsOnRow, 1)
	end
end
if #maxSeedsHeld < seeds then
	for s=#maxSeedsHeld,(seeds - 1) do
		table.insert(maxSeedsHeld, maxSeedsHeld[1] or 8)
	end
end

function forward()
	while not turtle.forward() do
		sleep(2)
	end
	return true;
end

moveFuncs.setMoveFuncs(
	{
		forward = forward,
		up = turtle.up,
		down = turtle.down
	}
);

function doNextBlock(age,maxStack)
	local inspect, data = turtle.inspectDown()
	if inspect then
		if data.state.age==age then
			turtle.digDown()
		end
	end
	local numb=turtle.getItemCount()
	if numb > 1 then
		turtle.placeDown()
	end
	maxStack = math.max(60,maxStack)
	if numb > maxStack then
		turtle.dropDown(numb-maxStack)
	end
	return moveFuncs.next();
end 

moveFuncs.setOptions(x,0,y,0);
moveFuncs.setStartPosition(invertYDir,false);
while true do
	turtle.turnLeft();
	turtle.turnLeft();
	forward();
	local done = false;
	local row = 1;
	local seedSlot = seedsOnRow[row];
	turtle.select(seedSlot);
	local maxStack = maxSeedsHeld[seedSlot];
	local seedAge = seedAges[seedSlot]
	repeat
		local success, detail = doNextBlock(seedAge,maxStack);
		if(success and detail == "Complete") then
			done = true;
		end
		if(success and detail == "Row") then
			print("Row")
			row = row +1;
			seedSlot = seedsOnRow[row]
			turtle.select(seedSlot);
			maxStack = maxSeedsHeld[seedSlot];
			seedAge = seedAges[seedSlot]
		end
	until done;
	turtle.turnRight();
	turtle.turnRight();
	for drop=1,seeds do
		turtle.select(drop)
		numb=turtle.getItemCount()
		if numb>maxSeedsHeld[drop] then
			turtle.dropDown(numb-maxSeedsHeld[drop])
		end
	end
	for i=2,y do
		forward()
	end
	turtle.turnRight();
	if(x%2==1) then
		for i=2,x do
			forward();
		end
	end
	forward();
	for drop=(seeds+1),16 do
		turtle.select(drop)
		turtle.dropUp()
	end
	moveFuncs.setCoords(0,0,0,0);
	sleep(waitTime)
end
