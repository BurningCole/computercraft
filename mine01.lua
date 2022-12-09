local x = 0; y=0; z=0;
local w = 15; h=10; l=15;
local yOff = 60
local dir = 0;
local done = false;

if(arg[1] ~= nil) then
	w = tonumber(arg[1]);
	h = tonumber(arg[2]);
	l = tonumber(arg[3]);
	if(arg[4] ~= nil) then
		yOff = tonumber(arg[4]);
	end
end

print("mine");
print(w,h,l);


for i=1,yOff do
	turtle.down()
end

--TODO
function refuel()
	print("do later");
end

function dig()
	while(turtle.detect()) do
		local success,reason = turtle.dig();
		if(success == false) then
			h=0
			print(reason)
			break
		end
		sleep(0.5)
	end
end
function digDown()
	while(turtle.detectDown()) do
		local success,reason = turtle.digDown()
		if(success == false) then
			h=0
			print(reason)
			break
		end
	end
end
function digUp()
	while (turtle.detectUp()) do
		local success, reson = turtle.digUp()
		if(success == false) then
			print(reason)
			h=0
			break
		end
	end
end

function move(x,y,z)
	if(x+y+z>0) then
		for i = 1,(y*3) do
			turtle.up()
		end
		for i=1,dir do
			turtle.turnLeft()
		end
	end
	if(x>0) then
		for i=1,x do
			turtle.back()
		end
	else
		for i=1,-x do
			turtle.forward()
		end
	end
	turtle.turnLeft()
	if(z>0) then
		for i=1,z do
			turtle.forward()
		end
	else
		for i=1,-z do
			turtle.back()
		end
	end
	turtle.turnRight()
	if(x+y+z<0) then
		for i = 1,(-y*3) do
			turtle.down()
		end
		for i=1,dir do
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
			break;
		end
		if((dir==1)~=(x==0)) then
			turtle.turnRight()
			dir = (dir+1)%4
		else
			turtle.turnLeft()
			dir = (dir+3)%4 
		end
		for i = 1,3 do
			turtle.down()
			digDown()
		end
		print(x,y,z)
		y=y+1;
	end
	if(turtle.getItemCount(15)>0) then
		move(x,y,z)
		for i=1,yOff do
			turtle.up()
		end
		for i=16,3,-1 do
			turtle.select(i)
			turtle.dropUp()
		end
		for i=1,yOff do
			turtle.down()
		end
		move(-x,-y,-z)
	end
end
print(x,y,z)
move(x,y,z)
for i=1,yOff do
	turtle.up()
end
