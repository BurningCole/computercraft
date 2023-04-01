local x, y, z, x2, y2, z2;
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
		x2, _, z2 = gps.locate(5)
		turtle.back();
	elseif turtle.back() then
		x2, _, z2 = gps.locate(5)
		x2=2*x-x2
		z2=2*z-z2
		turtle.forward()
	else
		turtle.turnRight()
		check()
	end
end

check();

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
	turtle.turnLeft()
end

local forward=function(n)
	print("forward ",n);
	if(n<0) then
		for i=1,-n do
			while not turtle.back() do
				sleep(2)
			end
		end
	else
		for i=1,n do
			while not turtle.forward() do
				sleep(2)
			end
		end
	end
end

local up=function(n)
	print("up ",n);
	local turnAround = false;
	if(n<0) then
		for i=1,-n do
			while not turtle.down() do
				sleep(2)
			end
		end
	else
		for i=1,n do
			while not turtle.up() do
				sleep(2)
			end
		end
	end
end

forward(x-home[1])
turtle.turnLeft()
forward(home[3]-z)
up(home[2]-y);
for i=0,home[4] do
	turtle.turnRight()
end