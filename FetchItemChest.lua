------------------

-- call with empty inventory slot selected
-----------------------------
local searchFor =  
     "oak_log" --item to look for
local numItems =  
      64; -- number to fetch
-----------------------------

local searchForLower = string.lower(searchFor);
local size = peripheral.call("front","size");
local items = peripheral.call("front","list");

local empty = 0;
local found = {}
local prev = 0;

--look for items
for slot, item in pairs(items) do
  if string.find(string.lower(item.name),searchForLower) then
    found[#found +1] = {slot = slot,count = item.count};
  end
  if slot ~= (prev + 1) and empty == 0 then
    empty = prev + 1;
  end
  prev = slot
end
--check for empty inv slot
if(empty == 0 and #items < size) then
  empty = #items + 1;
end
-- auto set number of items
if(numItems == 0) then 
  if(#found ~= 0) then
    numItems = found[#found].count;
  else
    numItems = 1;
  end
end
--
local total = numItems;
while numItems > 0 and #found ~= 0 do
  local fromData = found[#found];
  table.remove(found, #found);
  if(empty == 0) then
    turtle.suck()
  elseif(empty ~= 1 and fromData.slot ~= 1) then
    peripheral.call("front","pullItems","front",1,64,empty)
  end
  if(fromData.slot ~= 1) then
    peripheral.call("front","pullItems","front",fromData.slot,64,1)
  end
  if(empty == 0) then
    turtle.drop()
  end
  empty = 1;
  local pullNum = math.min(numItems,fromData.count)
  turtle.suck(pullNum);
  numItems = numItems - pullNum;
end
if numItems > 0 then
  return  (total - numItems).."/"..total.." fetched, "..numItems.." missing"
end
return "success"