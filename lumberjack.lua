
local width = 3;	--saplings per row
local height = 3;	--saplings per column

local wGap = 2;	--blocks between saplings
local hGap = 2;

local checkPeriod = 10;

-- if turtle starts in bottom left going up instead of bottom right
local startIsLeft = false;

--[[
		  <-----> width
		 /-------\
		^|X  X  X|
		||       |	X = sappling location		
 height ||X  X  X|	T = turtle location
		||       |	F = fuel chest
		v|X  X  X|	S = output storage
		 \------TF
	            S
				
	Bottom row must be cleared
]]

local x = 0;
local y = 0;
local dir = 0;

local turnA;
local turnB;

local fuelThreshold = 16000;

local treeStrings = {
	"_log",
	"_leaves"
};

if(startIsLeft) then
	turnA = turtle.turnRight;
	turnB = turtle.turnLeft;
else
	turnA = turtle.turnLeft;
	turnB = turtle.turnRight;
end


local forceMove = {
	forward = function() 
		while(not turtle.forward()) do
			turtle.dig();
			sleep(0.2);
		end
	end,
	up = function() 
		while(not turtle.up()) do
			turtle.digUp();
			sleep(0.2);
		end
	end,
	down = function() 
		while(not turtle.down()) do
			turtle.digDown();
			sleep(0.2);
		end
	end,
	back = function()
		if(not turtle.back()) then
			turtle.turnLeft();
			turtle.turnLeft();
			repeat
				turtle.dig();
				sleep(0.2);
			until(turtle.forward())
			turtle.turnLeft();
			turtle.turnLeft();
		end
	end,
};

function findAny(strings, inString)
	if(inString == nil) then 
		return false; 
	end
	for i,v in ipairs(strings) do 
		if(inString:find(v) ~= nil) then
			return true;
		end
	end
	return false
end

--
function mineDepth(toMine,back)
	local minedPath = {
		{backFunc = nil, side = 0}
	};
	repeat
		local currentNode = minedPath[#minedPath];
		if(currentNode.side == 0) then -- check up
			local check, data = turtle.inspectUp();
			if(check and findAny(toMine,data.name)) then
				turtle.digUp();
				forceMove.up();
				table.insert(minedPath,{backFunc = forceMove.down, side = 0});
			end
		elseif(currentNode.side == 1) then -- check down
			local check, data = turtle.inspectDown();
			if(check and findAny(toMine,data.name)) then
				turtle.digDown();
				forceMove.down();
				table.insert(minedPath,{backFunc = forceMove.up, side = 1});
			end
		elseif(currentNode.side == 6) then	-- all sides checked
			turtle.turnLeft();
			if(currentNode.backFunc ~= nil) then 
				currentNode.backFunc() 
			end;
			table.remove(minedPath);
		else	-- check forward and rotate
			if(currentNode.side>2) then 
				turtle.turnLeft() 
			end;
			local check, data = turtle.inspect();
			if(check and findAny(toMine,data.name)) then
				turtle.dig();
				forceMove.forward();
				table.insert(minedPath,{backFunc = forceMove.back, side = 0});
			end
		end
		currentNode.side = currentNode.side + 1;
		
	until (#minedPath == 0);
end


function nextTree()
	if(dir == 0) then 
		x =x+1;
		if(x>=height) then
			turnA();
			dir = 1;
		end
	elseif(dir == 1 and height>1) then 
		y=y+1;
		if(x<=0)then
			turnB();
			dir = 0;
		else
			turnA();
			dir = 2;
		end
	elseif(dir == 2) then
		x =x-1
		if(x<=1)then
			turnB();
			dir = 1;
		end
	end
	local gap = wGap;
	if((dir%2)==1) then
		gap = hGap;
	end
	for i=1,gap do
		forceMove.forward();
	end
	turtle.dig();
	forceMove.forward();
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
		while(not turtle.suck()) do
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
			turtle.drop();
		end
		turtle.refuel();
		print("Fuel "..turtle.getFuelLevel().."/"..maxFuel);
	end
end

function dropLogs()
	for i=1,16 do
		turtle.select(i);
		local repeats = 0;
		while(turtle.getItemCount()>0) do
			if(repeats > 0) then
				if((repeats%10) == 0) then
					print("Failed to Drop ("..repeats..") please press a key to continue reattempting");
					os.pullEvent("key");
				else
					print("Failed to Drop ("..repeats..") reattempting...");
					sleep(5);
				end
			end
			repeats = repeats + 1;
			turtle.drop();
		end
	end
end

turnB();
refuel();
turnA();
while true do
	local detect, data = turtle.inspect();
	if(not detect or findAny(treeStrings,data.name)) then
		turtle.select(1)
		forceMove.up();
		turtle.dig();
		forceMove.forward();
		for i = 1,width*height do
			if(i~=1) then
				nextTree();			-- Go to next Tree location
			end
			mineDepth(treeStrings);	-- Chop down tree
			if(turtle.getItemCount()>1) then
				turtle.placeDown();	-- Place sapling
			end
		end
		if(height == 1) then
			turnB();
		end
		-- return home
		if((y%2) == 1) then		--turtle on bottom of field
			forceMove.forward();
			turnA();
		else					--turtle on top of field
			turnA();
			forceMove.forward();
			turnA();
			for i=1,(height-1)*(hGap+1)+1 do
				forceMove.forward();
			end
			turnA();
			forceMove.forward();
		end
		for i=1,(width-1)*(wGap+1) do
			forceMove.forward();
		end
		forceMove.down();
		turnB();
		dropLogs();
		turnA();
		refuel();
		turnA();
		x = 0;
		y = 0;
		dir = 0;
	end
	sleep(checkPeriod);
end