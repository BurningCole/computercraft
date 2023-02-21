local width = 1;
local height = 1;
local length = 1;

local wGap = 0;
local hGap = 0;
local lGap = 0;

local x = 0; y=0; z=0;

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
	gentleForward = function()
		while not turtle.forward() do
			sleep(2)
		end
	end,
	setAreaScales = function(newWidth,newHeight,newLength,newWGap,newHGap,newLGap)
		width = newWidth-1;
		height = newHeight-1;
		length = newLength-1;

		wGap = newWGap or 0;
		hGap = newHGap or 0;
		lGap = newLGap or 0;
	end,
	setDeviceLocation = function(x,y,z,d) end,
	getAreaLocation = function() end
};

forceMove.moveNext = function()
	if(dir == 0) then 
		x =x+1;
		if(x>=w) then
			if((y%2) ==0) then
				turtle.turnRight();
				dir = 1;
			else
				turtle.turnLeft();
				dir = 3;
			end
		end
	elseif(dir == 1) then 
		z=z+1;
		if(x<=0)then
			turtle.turnLeft();
			dir = 0;
		else
			turtle.turnRight();
			dir = 2;
		end
	elseif(dir == 2) then
		x =x-1
		if(x<=0)then
			if((y%2) == 0) then
				turtle.turnLeft();
				dir = 1;
			else
				turtle.turnRight();
				dir = 3;
			end
		end
	elseif(dir == 3) then
		z=z-1;
		if(x<=0) then
			turtle.turnRight()
			dir = 0
		else
			turtle.turnLeft()
			dir = 2
		end
	end
	if((z==0 and dir==3) or (z==l and dir==1)) then
		if(y >= h) then
			done = true;
			return true, done;
		end
		if((dir==1)~=(x==0)) then
			turtle.turnRight()
			dir = (dir+1)%4
		else
			turtle.turnLeft()
			dir = (dir+3)%4 
		end
		for i = 1,hGap do
			forceMove.down()
			digDown()
		end
		print(x,y,z)
		y=y+1;
	end
end



return forceMove;