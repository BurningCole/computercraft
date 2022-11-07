local x = 0; y=0; z=-1;
local w = 5; h=8; l=15;
local zOff = 00
local dir = 3;
local done = false;

if(arg[1] ~= nil) then
	w = tonumber(arg[1]);
	h = tonumber(arg[2]);
	l = tonumber(arg[3]);
	if(arg[4] ~= nil) then
		zOff = tonumber(arg[4]);
	end
end

local fortune = {
	"coal_ore",
	"iron_ore",
	"copper_ore",
	"gold_ore",
	"redstone_ore",
	"emerald_ore",
	"lapis_ore",
	"diamond_ore",
	"zinc_ore",
	"iridium_ore",
	"lead_ore",
	"ruby_ore",
	"peridot_ore",
	"sapphire_ore",
	"silver_ore",
	"tin_ore",
	"quartz_ore",
	"glowstone"
};

print("mine");
print(w,h,l);


for i=1,zOff do
	if not turtle.forward() then
		zOff = i-1;
		break;
	end
end
local inSlot = turtle.getItemDetail(1);
local left = peripheral.wrap("left");
local fortuneEquipped = (string.sub(inSlot.name,1,6) ~= "turtle");

function dig()
	local detected,data = turtle.inspect();
	if(detected == false)then return; end
	local digF = turtle.dig;
	local fortuneF = false;
	for k,ore in ipairs(fortune) do
		if(data.name:match(ore.."$")) then
			if(not fortuneEquipped) then
				turtle.select(1);
				turtle.equipLeft();
				turtle.select(2);
				fortuneEquipped = true;
				if(left == nil) then
					left = peripheral.wrap("left");
				end
			end
			fortuneF = true;
			digF = function() return left.swing("block"); end
			break;
		end
	end
	if(fortuneEquipped and not fortuneF) then
		turtle.select(1);
		turtle.equipLeft();
		fortuneEquipped = false;
	end
	while(turtle.detect()) do
		local success,reason = digF();
		if(success == false) then
			h=0
			print(reason)
			break
		end
		sleep(0.5)
	end
end

function digDown()
	local detected,data = turtle.inspectDown();
	if(detected == false)then return; end
	local digF = turtle.digDown;
	local fortuneF = false;
	for k,ore in ipairs(fortune) do
		if(data.name:match(ore.."$")) then
			if(not fortuneEquipped) then
				turtle.select(1);
				turtle.equipLeft();
				turtle.select(2);
				fortuneEquipped = true;
				if(left == nil) then
					left = peripheral.wrap("left");
				end
			end
			fortuneF = true;
			digF = function () return left.swing("block","down"); end
			break;
		end
	end
	if(fortuneEquipped and not fortuneF) then
		turtle.select(1);
		turtle.equipLeft();
		fortuneEquipped = false;
	end
	while(turtle.detectDown()) do
		local success,reason = digF()
		if(success == false) then
			h=0
			print(reason)
			break
		end
	end
end

function digUp()
	local detected,data = turtle.inspectUp();
	if(detected == false)then return; end
	local digF = turtle.digUp;
	local fortuneF = false;
	for k,ore in ipairs(fortune) do
		if(data.name:match(ore.."$")) then
			if(not fortuneEquipped) then
				turtle.select(1);
				turtle.equipLeft();
				turtle.select(2);
				fortuneEquipped = true;
				if(left == nil) then
					left = peripheral.wrap("left");
				end
				fortuneF = true;
				digF = left.swing("block","up");
				break;
			end
		end
	end
	if(fortuneEquipped and not fortuneF) then
		turtle.select(1);
		turtle.equipLeft();
		fortuneEquipped = false;
	end
	while (turtle.detectUp()) do
		local success, reason = digF()
		if(success == false) then
			print(reason)
			h=0
			break
		end
	end
end

function move(x,y,z)
	if(z>0) then
		for i=1,(dir+3)%4 do
			turtle.turnLeft() --point 1
		end
		for i=1,z do
			turtle.forward() -- to exit z
		end
	end
	--target y
	if(y>0) then	
		for i = 1,y*3 do
			turtle.down()	
		end
	else
		for i = 1,-y do
			turtle.up()
		end
	end
	turtle.turnLeft();
	--target x
	if(x>0) then
		for i=1,x do
			turtle.back()
		end
	else
		for i=1,-x do
			turtle.forward()
		end
	end
	turtle.turnRight()
	if(z<0) then
		for i=1,-z do
			turtle.back()
		end
		for i=1,(dir+3)%4 do
			turtle.turnRight()
		end
	end
end
while(done ~= true) do
	dig()
	turtle.forward()
	digUp()
	digDown()
	print(x,y,z)
	if(dir == 0) then 
		x =x+1;
		if(x>=w) then
			if(((z%2) == 0 and y==h) or
			   ((z%2) == 1 and y==0)) then
				turtle.turnLeft()
				dir = 3;
			else
				local move = turtle.down;
				local digF = digDown;
				if((z%2)==0) then
					move = turtle.up;
					digF = digUp;
				end
				for i = 1,3 do
					move();
					digF();
				end
				turtle.turnLeft();
				turtle.turnLeft();
				dir = 2;
			end
		end
	elseif(dir == 2) then
		x = x-1
		if(x<=0)then
			if(((z%2) == 0 and y==h) or
				(z%2) == 1 and y==0)) then
				turtle.turnRight()
				dir = 3;
			else
				local move = turtle.down;
				local digF = digDown;
				local dy = -1;
				if((z%2)==0) then
					move = turtle.up;
					digF = digUp;
					dy = 1;
				end
				y = y + dy;
				for i = 1,3 do
					move();
					digF();
				end
				turtle.turnLeft();
				turtle.turnLeft();
				dir = 0;
			end
		end
		
	elseif(dir == 3) then
		z=z+1;
		if(x<=0) then
			turtle.turnRight()
			dir = 0
		else
			turtle.turnLeft()
			dir = 2
		end
	end
	if(z==l and dir ==3) then
		done = true;
		break;
	end
	if(turtle.getItemCount(15)>0) then
		move(x,y,z)
		for i=0,zOff do
			turtle.forward()
		end
		for i=16,3,-1 do
			turtle.select(i)
			turtle.drop()
		end
		for i=0,zOff do
			turtle.back()
		end
		move(-x,-y,-z)
	end
end
print(x,y,z)
move(x,y,z)
for i=0,zOff do
	turtle.forward()
end
turtle.turnLeft();
turtle.turnLeft();
