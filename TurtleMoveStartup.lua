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
check=function()
	if turtle.forward() then
		x2, y2, z2 = gps.locate(5)
		turtle.back();
	elseif turtle.back() then
		x2, y2, z2 = gps.locate(5)
		x2=(x-x2)*2+x2
		y2=(y-y2)*2+y2
		z2=(z-z2)*2+z2
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
print("0")
elseif x < x2 then
dir=2
print("2")
elseif y > y2 then
dir=1
print("1")
else
dir=3
print("3")
end
print("check")
for i=1,dir do
turtle.turnRight()
end
forward=function(n)
for i=1,n do
	while not turtle.forward() do
		sleep(2)
	end
end
end
forward(x-home[1])
turtle.turnLeft()
forward(home[2]-z)
turtle.turnLeft()
shell.run("farm")