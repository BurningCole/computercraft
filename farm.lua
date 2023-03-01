print('Turtle farmer V1.4.1');

local moveFuncs = require("MoveFuncs");
local config = {
	waitTime=30, -- time between finishing and starting again(s)
	seeds = 1,
	maxSeedsHeld={16},
	seedsOnRow={1},
	seedAges = {7},
	invertYDir = false
}

local x=tonumber(arg[1]) or 14;
local y=tonumber(arg[2]) or 5;

local fuelThreshold = 1000 + 2*x*y;

--  	  _________
-- 		 [         ]
-- 		 [         ]
-- 		y[         ]
-- 		 [         ]
-- 		#[_________]   #=Turtle, plants along x axis
--            x
--Turtle inventory
--[1234] 0=keep empty
--[5678] 1=main seed(will fill empty rows)
--[0000] 2+= optional extra seeds (seeds must go to lowest value)
--[0000] the turtle will keep one of each seed placed inside
local seedsOnRow={1,2,3,4,5,6,7,1,1,1,1,1} --seeds on each row, add more values for a larger y
local seedAges = {3,7};


if(fs.exists("config/farm")) then
	local configFile = fs.open("config/farm", "r");
	local fileContents = configFile.readAll();
	for key, v in string.gmatch(fileContents, "(%w+) *= *(%w[%w ,]*);") do
		if(config[key] ~= nil) then
			local valuetype = type(config[key])
			if(valuetype == "number") then
			local numberValue = tonumber(v);
				if(numberValue~=nil) then
					config[key] = numberValue;
				end
			elseif(valuetype == "string") then
				config[key] = v;
			elseif(valuetype == "table") then
				config[key] = {};
				for subVal in string.gmatch(v, "(%w*)") do
					local subValNumber = tonumber(subVal)
					if(subValNumber ~= nil) then
						table.insert(config[key],subValNumber);
					end
				end
			end
		end
    end
	configFile.close();
end

if #(config.seedsOnRow) < y then
	for s=#(config.seedsOnRow),(y - 1) do
		table.insert(config.seedsOnRow, 1)
	end
end
if #(config.maxSeedsHeld) < config.seeds then
	for s=#(config.maxSeedsHeld),(config.seeds - 1) do
		table.insert(config.maxSeedsHeld, config.maxSeedsHeld[1] or 8)
	end
end

function forward()
	while not turtle.forward() do
		sleep(2)
	end
	return true;
end

moveFuncs.setMoveFuncs(turtle);

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

function refuel()
	if(turtle.getFuelLevel() > fuelThreshold)then 
		return 
	end
	local maxFuel = turtle.getFuelLimit()-1000;
	maxFuel = math.min(fuelThreshold*2,maxFuel);
	for i=1,16 do
		if(turtle.getItemCount(i) == 0) then
			turtle.select(i);
			break;
		end
	end
	local repeats = 0;
	while(turtle.getFuelLevel() < maxFuel) do
		while(not turtle.suck(1)) do
			turtle.drop();
			if(repeats > 0) then
				if((repeats%10) == 0) then
					print("Failed to get fuel ("..repeats..") please press a key to continue reattempting");
					os.pullEvent("key");
				else
					print("Failed to get fuel ("..repeats..") reattempting...");
					sleep(5);
				end
			end
			repeats = repeats + 1;
		end
		turtle.refuel(1);
		turtle.dropUp();
		print("Fuel "..turtle.getFuelLevel().."/"..maxFuel);
	end
end

moveFuncs.setOptions(x,0,y,0);
moveFuncs.setStartPosition(config.invertYDir,false);
while true do
	refuel();
	turtle.turnLeft();
	turtle.turnLeft();
	forward();
	local done = false;
	local row = 1;
	local seedSlot = config.seedsOnRow[row];
	turtle.select(seedSlot);
	local maxStack = config.maxSeedsHeld[seedSlot];
	local seedAge = config.seedAges[seedSlot]
	repeat
		local success, detail = doNextBlock(seedAge,maxStack);
		if(success and detail == "Complete") then
			done = true;
		end
		if(success and detail == "Row") then
			print("Row")
			row = row +1;
			seedSlot = config.seedsOnRow[row]
			turtle.select(seedSlot);
			maxStack = config.maxSeedsHeld[seedSlot];
			seedAge = config.seedAges[seedSlot]
		end
	until done;
	turtle.turnRight();
	turtle.turnRight();
	for drop=1,config.seeds do
		turtle.select(drop)
		numb=turtle.getItemCount()
		if numb>config.maxSeedsHeld[drop] then
			turtle.dropDown(numb-config.maxSeedsHeld[drop])
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
	for drop=(config.seeds+1),16 do
		turtle.select(drop)
		turtle.dropUp()
	end
	moveFuncs.setCoords(0,0,0,0);
	sleep(config.waitTime)
end
