function tryRequire(libraryName)
	local loaded, library = pcall(require,"AStar");
	if(loaded) then 
		return library;
	end
	return setmetatable(library, { 
		__index = function(lib,key)
			if(lib[key] ~= nil) then return lib[key] end
			return function() end;
		end
	});
end

local loaded, AStar = pcall(require,"AStar");
if(not loaded) then 
	AStar = {}; end

local run = true;
local replyChannel = 51;
local turtleChannel = 51;
local timeout = 30;
local modem = peripheral.find("modem") or error("no modem");
modem.open(turtleChannel);
local x,y,z,dir;
local directions = {
	[0] = "East",[1] = "South",[2] = "West",[3] = "North",
	n = 3, e = 0, s = 1, w = 2,
	x = 0, z = 1, ["-x"] = 2, ["-z"] = 3,
	north = 3, east = 0, south = 1, west = 2
}

function checkMessageArgs(message)
	if(string.byte(message)==58) then --starts with ":"
		local splitMessage = string.gmatch(message, "[^:\"]+|(\"[^\"]*\")*");
		local isValid = true;
		for i=1,#splitMessage-1 do
			if(string.sub(splitMessage[i],1,3)=="id=") then
				if(string.sub(splitMessage[i],4,-1)~=tostring(os.getComputerID())) then
					isValid = false;
					break;
				end
			end
		end
		if(not isValid) then return false; end
		message = splitMessage[#splitMessage];
		if(string.byte(message)==34) then
			message = message:sub(2,-2):gsub('""','"');
		end
	end
	return message;
end

function getPocketInput(requestStr)
	local id = os.getComputerID();
	modem.transmit(replyChannel,turtleChannel,":input:id="..id..":\""..requestStr:sub('"','""').."\"");
	local message;
	repeat
		event, side, _, replyChannel, message, distance = os.pullEvent("modem_message");
		message = checkMessageArgs(message);
	until(message ~= false);
	print(message);
	return message;
end

function transmitPrint(value)
	modem.transmit(replyChannel,turtleChannel,":print:id="..id..":\""..requestStr:gsub('"','""').."\"");
end

print("Starting remote...");
local x, y, z = gps.locate(5)
if(z ~= nil) then
	print("I am at (" .. x .. ", " .. y .. ", " .. z .. ")")
	local dx, dy;
	if turtle.forward() then
		x2, y2, z2 = gps.locate(5)
		dx = x2-x;
		dz = z2-z;
	elseif turtle.back() then
		x2, y2, z2 = gps.locate(5)
		dx = x-x2;
		dz = z-z2;
	else
		print("Can't find direction")
	end
	if(dx < -0.5) then
		dir = 2;
	elseif(dz > 0.5) then
		dir = 1
	elseif(dz < -0.5) then
		dir = 3
	else
		dir = 0
	end
	print("Pointing "..directions[dir]);
elseif(arg[1] ~= "nodef") then
	print("insert coodinates");
	while(x == nil) do
		io.write("Insert x>");
		xStr = io.read();
		x = tonumber(xStr)
	end
	while(y == nil) do
		io.write("Insert y>");
		yStr = io.read();
		y = tonumber(yStr)
	end
	while(z == nil) do
		io.write("Insert z>");
		zStr = io.read();
		z = tonumber(zStr)
	end
	while(dir == nil) do
		io.write("direction>");
		dirStr = io.read();
		dir = tonumber(dirStr)
		if(dir == nil) then
			dir = directions[dirStr];
		end
	end
end

function gotoPos(nx,ny,nz)
	local stuck =false;
	local stuckNum = 0;
	while((nx~=x or ny~=y or nz~=z)) do
		if(nx>x) then setDir(0);
		else setDir(2); end
		
		while(nx ~= x and not stuck) do
			stuck = forward() == false;
			if(stuck) then stuckNum = stuckNum + 1; else stuckNum = 0; end
		end
		stuck = false;
		
		if(nz>z) then setDir(1);
		else setDir(3); end
		
		while(nz ~= z and not stuck) do
			stuck = forward() == false;
			if(stuck) then stuckNum = stuckNum + 1; else stuckNum = 0; end
		end
		stuck = false;
		
		local yChange = up;
		if(ny<y) then yChange = down; end
		while(ny ~= y and not stuck) do
			stuck = yChange() == false;
			if(stuck) then stuckNum = stuckNum + 1; else stuckNum = 0; end
		end
		if(stuckNum >= 3) then break; end
	end
	return x..","..y..","..z;
end

function gotoCall()
	local target = getPocketInput("Input target in format \"x,y,z\"")..",";
	coords = {target:match( ("([^,]*),"):rep(3))};
	nx = tonumber(coords[1]);
	ny = tonumber(coords[2]);
	nz = tonumber(coords[3]);
	if(nx == nil or ny == nil or nz == nil)
	then return false; end
	return gotoPos(nx,ny,nz);
end

function setDir(nDir)
	local rotations = (nDir-dir+4)%4
	if(rotations==3) then
		turnLeft();
	else
		for i = 1,rotations do
			turnRight();
		end
	end
end

function getRelative(direction)
	if(direction == nil) then direction = dir end
	local nx,ny,nz = x,y,z;
	if(direction == 0) then
		nx = nx + 1;
	elseif(direction == 1) then
		nz = nz + 1;
	elseif(direction == 2) then
		nx = nx - 1;
	else
		nz = nz + 1;
	end
	return nx,ny,nz;
end

function turnLeft()
	turtle.turnLeft();
	dir = (dir+3)%4;
	local nx,ny,nz = getRelative(dir);
	AStar.setBlocked(nx,ny,nz,turtle.detect());
	return directions[dir];
end

function turnRight()
	turtle.turnRight();
	dir = (dir+1)%4;
	local nx,ny,nz = getRelative(dir);
	AStar.setBlocked(nx,ny,nz,turtle.detect());
	return directions[dir];
end

function forward()
	local moved = turtle.forward();
	if(moved) then
		if(dir == 0) then x = x+1;
		elseif(dir == 1) then z = z+1;
		elseif(dir == 2) then x = x-1;
		else                  z = z-1;
		end
		local nx,ny,nz = getRelative(dir);
		AStar.setBlocked(nx,ny,nz,turtle.detect());
		AStar.setBlocked(x,y+1,z,turtle.detectUp());
		AStar.setBlocked(x,y-1,z,turtle.detectDown());
		return x..","..y..","..z;
	end
	local nx,ny,nz = getRelative(dir);
	AStar.setBlocked(nx,ny,nz,turtle.detect());
	AStar.setBlocked(x,y+1,z,turtle.detectUp());
	AStar.setBlocked(x,y-1,z,turtle.detectDown());
	return moved;
end

function back()
	local moved = turtle.back();
	if(moved) then
		if(dir == 0) then x = x-1;
		elseif(dir == 1) then z = z-1;
		elseif(dir == 2) then x = x+1;
		else                  z = z+1;
		end
		AStar.setBlocked(x,y+1,z,turtle.detectUp());
		AStar.setBlocked(x,y-1,z,turtle.detectDown());
		return x..","..y..","..z;
	end
	return moved;
end

function down()
	local moved = turtle.down()
	if(moved) then
		y=y-1;
		local nx,ny,nz = getRelative(dir);
		AStar.setBlocked(nx,ny,nz,turtle.detect());
		AStar.setBlocked(x,y-1,z,turtle.detectDown());
		return x..","..y..","..z;
	end
	return moved;
end

function up()
local moved = turtle.up()
	if(moved) then
		y=y+1;
		local nx,ny,nz = getRelative(dir);
		AStar.setBlocked(nx,ny,nz,turtle.detect());
		AStar.setBlocked(x,y+1,z,turtle.detectUp());
		return x..","..y..","..z;
	end
	return moved;
end

AStar.move = {
	forward = forward,
	back = back,
	up = up,
	down = down,
	setDir = setDir
}

commands = {
	f = forward,
	b = back,
	l = turnLeft,
	r = turnRight,
	d = down,
	u = up,
	df = turtle.dig,
	du = turtle.digUp,
	dd = turtle.digDown,
	s = turtle.detect,
	i = turtle.inspect,
	pd = turtle.placeDown,
	pf = turtle.place,
	pu = turtle.placeUp,
	sd = turtle.suckDown,
	sf = turtle.suck,
	su = turtle.suckUp,
	drd = turtle.dropDown,
	drf = turtle.drop,
	dru = turtle.dropUp,
	sel = function() 
		local slot = (((tonumber(getPocketInput("insert slot number 1-16")) or turtle.getSelectedSlot())-1)%16)+1; 
		turtle.select(slot);
		local data = turtle.getItemDetail();
		if(data == nil)then return slot .. ": empty" end
		return slot .. ": \"".. data.name .."\" x"..data.count;
	end,
	inv = function() 
		local out = ""; 
		for i=1,16 do 
			local data = turtle.getItemDetail(i); 
			if(data) then out = out .. "\n" .. i .. ": \"".. data.name .."\" x"..data.count; end
		end
		return out; end,
	["goto"] = gotoCall,
	loc = function() return x..","..y..","..z; end,
	setx = function() x=tonumber(getPocketInput("insert x value")) or x; return "x set to: "..x; end,
	sety = function() y=tonumber(getPocketInput("insert y value")) or y; return "y set to: "..y; end,
	setz = function() z=tonumber(getPocketInput("insert z value")) or z; return "z set to: "..z; end,
	setd = function() 
		local dirStr = getPocketInput("insert direction value"); 
		dir=tonumber(dirStr) or directions[dirStr] or dir; 
		return "direction set to: "..directions[dir]; end,
	id = os.getComputerID,
	run = function()
		local functionString = getPocketInput("Insert function body");
		local success, data = pcall (load(functionString));
		if(success) then
			return data;
		else
			return "error encountered";
		end
	end,
	stop = function() run=false; return true; end
};
local channel = 51;
local timer = nil;
local filter = "modem_message timer";
if(timeout == 0 or timeout == nil) then
	filter = "modem_message"
end
while (run) do
	if(timeout > 0 and timer == nil)then
		timer = os.startTimer(timeout);
	end
	local response = "";
	event, side, _, modemChannel, message, distance = os.pullEvent(filter);
	if(event == "timer") then
		modem.transmit(replyChannel,51,"Waiting for input");
	elseif(event == "modem_message") then
		message = checkMessageArgs(message);
		replyChannel = modemChannel;
		if(message ~= false) then 
			os.cancelAlarm(timer);
			for submatch in string.gmatch(message, "%S+") do
				print(submatch)
				if(commands[submatch] ~=nil) then
					local results = {commands[submatch]()};
					local resultStr = {}
					for k, v in pairs(results) do
						resultStr[k] = v..""
					end
					response = response .. "\n" .. table.concat(resultStr,", ");
				else
					response = response .. "\n" .. "Unknown command"
				end
			end
			response = ":done:" .. response;
			modem.transmit(replyChannel,51,response);
		end
	end
end