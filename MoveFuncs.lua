local moveLib = {};
local move = {
	forward = turtle.forward,
	up = turtle.up,
	down = turtle.down,
};

local x, y, z, dir = 0,0,0,0;
local w, l, h= 1,1,1;
local wGap, lGap, hGap = 0,0,0;
local startIsLeft = false;
local startIsTop = false;
local failedMoves = 0;

local turnA, turnB, yMove;

if(startIsLeft) then
	turnA = turtle.turnRight;
	turnB = turtle.turnLeft;
else
	turnA = turtle.turnLeft;
	turnB = turtle.turnRight;
end

function moveNextZigZag()
	if(failedMoves>0) then
		local correctMove = move.forward;
		if((z==0 and dir==3) or (z==l and dir==1)) then
			correctMove = yMove;
		end
		for i = 1,failedMoves do
			local success, err = correctMove();
			if(not success) then
				failedMoves = 1+failedMoves-i;
				return false, err;
			end
		end
	end
	if(w == 1) then 
		if(dir == 0 and z==0) or (dir == 2 and z+1 == l) then
			turnA();
			dir = (dir+1)%4
		elseif(dir == 2 and z==0) or (dir == 0 and z+1 == l) then
			turnB();
			dir = (dir+3)%4
		end
	end;
	local details = nil;
	if((z==0 and dir==3) or (z+1==l and dir==1)) then
		if(y+1 >= h) then
			return true, "Complete";
		end
		details = "Level";
		if((dir==1) and (l%2 == 1)) then
			turnA();
			dir = (dir+1)%4
		else
			turnB();
			dir = (dir+3)%4 
		end
		for i = 0,hGap-failedMoves do
			local success, err = yMove();
			if(not success) then
				failedMoves = 1+gap-i;
				return false, err;
			end
		end
		y=y+1;
	else
		local forward = 0;
		if(dir%2 == 0) then
			forward = wGap +1;
		else
			if(l>1) then
				forward = lGap +1;
			end
		end
		for i = 1,forward-failedMoves do
			local success, err = move.forward();
			if(not success) then
				failedMoves = 1+forward-i;
				return false, err;
			end
		end
		if(dir == 0) then
			x =x+1;
			if(x+1>=w) then
				if((y%2) ==0) then
					turnA();
					dir = 1;
				else
					turnB();
					dir = 3;
				end
			end
		elseif(dir == 1) then
			z=z+1;
			details = "Row";
			if(w>1) then
				if(x<=0)then
					turnB();
					dir = 0;
				else
					turnA();
					dir = 2;
				end
			end
		elseif(dir == 2) then
			x =x-1
			if(x<=0)then
				if((y%2) == 0) then
					turnB();
					dir = 1;
				else
					turnA();
					dir = 3;
				end
			end
		elseif(dir == 3) then
			z=z-1;
			details = "Row";
			if(w>1) then
				if(x<=0) then
					turnA();
					dir = 0
				else
					turnB();
					dir = 2
				end
			end
		end
	end
	--print(x,y,z,dir);
	failedMoves = 0;
	return true,details;
end

local usedMethod = "ZigZag";


local methods = {
	ZigZag = moveNextZigZag
};

moveLib.setMethod = function(method)
	if(methods[method] == nil) then
		return false
	end
	usedMethod = method;
	return methods[method];
end

moveLib.next = function()
	return methods[usedMethod]();
end

moveLib.setOptions = function(width,widthGap,length,lengthGap,height,heightGap)
	w=width  or 1;
	l=length or 1;
	h=height or 1;
	wGap=widthGap  or 0;
	lGap=lengthGap or 0;
	hGap=heightGap or 0;
end

moveLib.setCoords = function(nx,ny,nz,direction)
	x=nx or 0;
	y=ny or 0;
	z=nz or 0;
	dir=direction or 0;
end

moveLib.getCoords = function()
	return x,y,z,d
end

moveLib.setMoveFuncs = function(funcObject)
	move = funcObject;
	if(
		funcObject.forward == nil or
		funcObject.up == nil or
		funcObject.down == nil
	) then
		return false;
	end
	move = {
		forward = funcObject.forward,
		up = funcObject.up,
		down = funcObject.down,
	}
	if(startIsTop) then
		yMove = move.down;
	else
		yMove = move.up;
	end
end

moveLib.setMoveFuncs(turtle);

moveLib.setStartPosition = function(areaIsLeft,areaIsTop)
	startIsTop = areaIsTop;
	startIsLeft = areaIsLeft;
	if(startIsTop) then
		yMove = move.down;
	else
		yMove = move.up;
	end
	if(startIsLeft) then
		turnA = turtle.turnRight;
		turnB = turtle.turnLeft;
	else
		turnA = turtle.turnLeft;
		turnB = turtle.turnRight;
	end
end

--[[
if(arg ~= nil and arg[1] ~= nil) then
	if(arg[1] == "help" or #arg<3) then
		print("usage")
		print("MoveFuncs <width> <length> <height> [method]");
	else
		moveLib.setOptions(tonumber(arg[1]),0,
						   tonumber(arg[2]),0,
						   tonumber(arg[3]),0);
		moveLib.setStartPosition(true,false);
		while true do
			local success, details = moveLib.next();
			if(success and details == "Complete") then
				break;
			end
		end
	end
	return;
end
]]
return moveLib;