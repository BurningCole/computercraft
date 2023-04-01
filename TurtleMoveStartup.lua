local forceMove = require("forceMove");

local x, y, z;
while x == nil do
	x, y, z = gps.locate(5);
end
local home = {
	arg[1] or 8,
	arg[2] or 80,
	arg[3] or 429,
	arg[4] or 0
};

print("I am at (" .. x .. ", " .. y .. ", " .. z .. ")")
print("I want to be at (" .. home[1] .. ", " .. home[2] .. ", " .. home[3] .. ")")

check=function()
	if turtle.forward() then
		while x2 == nil do
			x2, _, z2 = gps.locate(5)
		end
		turtle.back();
	elseif turtle.back() then
		while x2 == nil do
			x2, _, z2 = gps.locate(5)
		end
		x2=2*x-x2
		z2=2*z-z2
		turtle.forward()
	else
		turtle.turnRight()
		sleep(5)
		check()
	end
end

check()

if x > x2 then
	dir=0
	print("Facing: West")
elseif x < x2 then
	dir=2
	print("Facing: East")
elseif z > z2 then
	dir=1
	print("Facing: North")
else
	dir=3
	print("Facing: South")
end

for i=1,dir do
	turtle.turnRight()
end


local forward=function(n)
	print("forward ",n);
	if(n<0) then
		for i=1,-n do
			forceMove.back();
		end
	else
		for i=1,n do
			forceMove.forward();
		end
	end
end

local up=function(n)
	print("up ",n);
	local turnAround = false;
	if(n<0) then
		for i=1,-n do
			forceMove.down();
		end
	else
		for i=1,n do
			forceMove.up();
		end
	end
end

forward(x-home[1])
turtle.turnLeft()
forward(home[2]-z)
turtle.turnLeft()
up(home[2]-y);
for i=0,home[4] do
	turtle.turnRight()
end