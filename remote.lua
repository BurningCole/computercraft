local run = true;
local modem = peripheral.find("modem") or error("no modem");
modem.open(51);
local x,y,z,dir;
local directions = {
  [0] = "North",[1] = "East",[2] = "South",[3] = "west",
  n = 0, e = 1, s = 2, w = 3,
  x = 0, z = 1, ["-x"] = 2, ["-z"] = 3,
  north = 0, east = 1, south = 2, west = 3
}

function getPocketInput(requestStr)
  modem.transmit(replyChannel,51,requestStr);
  event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message");
  print(message);
  return message;
end

print("Starting remote...");
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
  if(z == nil) then
    z = directions[dirStr];
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
    while(yz ~= y and not stuck) do
      stuck = yChange() == false;
      if(stuck) then stuckNum = stuckNum + 1; else stuckNum = 0; end
    end
    if(stuckNum == 3) then break; end
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

function turnLeft()
  turtle.turnLeft();
  dir = (dir+3)%4;
  return directions[dir];
end

function turnRight()
  turtle.turnRight();
  dir = (dir+1)%4;
end

function forward()
  local moved = turtle.forward();
  if(moved) then
        if(dir == 0) then x = x+1;
    elseif(dir == 1) then z = z+1;
    elseif(dir == 2) then x = x-1;
    else                  z = z-1;
    end
    return x..","..y..","..z;
  end
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
    return x..","..y..","..z;
  end
  return moved;
end

function down()
  local moved = turtle.down()
  if(moved) then
    y=y-1;
    return x..","..y..","..z;
  end
  return moved;
end

function up()
local moved = turtle.up()
  if(moved) then
    y=y+1;
    return x..","..y..","..z;
  end
  return moved;
end

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
    ["goto"] = gotoCall,
    setx = function() x=tonumber(getPocketInput("insert x value")) or x; return "x set to: "..x; end,
    sety = function() y=tonumber(getPocketInput("insert y value")) or y; return "y set to: "..y; end,
    setz = function() z=tonumber(getPocketInput("insert z value")) or z; return "z set to: "..z; end,
    setd = function() 
      local dirStr = getPocketInput("insert direction value"); 
      z=tonumber(dirStr) or directions[dirStr] or dir; 
      return "direction set to: "..directions[dir]; end,
    stop = function() run=false; return true; end
};
while (run) do
    event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message");
    local response = "Unknown command"
    for submatch in string.gmatch(message, "%S+") do
      print(submatch)
      if(commands[submatch] ~=nil) then
          response = response .. "\n" .. tostring(commands[submatch]());
      else
        response = response .. "\n" .. "Unknown command"
      end
    end
    modem.transmit(replyChannel,51,response);
end