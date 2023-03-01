local peripheralName = arg[4] or "minecraft:furnace";
local needsFuel = arg[5] or true

local furnaces = {peripheral.find(peripheralName)};
 
local genericChest = "minecraft:chest_"
local input = genericChest .. (arg[1] or 6);
local fuel = genericChest .. (arg[2] or 7);
local output = genericChest .. (arg[3] or 8);
 
local furnaceInSlot = 1; 
local furnaceFuelSlot = 2; 
local furnaceOutSlot = 3;

if(~needsFuel) then
	furnaceOutSlot = 2;
end
 
local inputPer = peripheral.wrap(input);
local fuelPer = peripheral.wrap(fuel);
local outputPer = peripheral.wrap(output);
 
while true do
	local items = inputPer.list();
	local hasItems = false;
	for k,v in pairs(items) do hasItems = true; end
	if(hasItems == false) then
		print("waiting");
		sleep(30);
	end
	for _,v in ipairs(furnaces) do
		if(needsFuel) then
			local currentFuel = v.getItemDetail(furnaceFuelSlot) or {};
			if(currentFuel.name == "minecraft:bucket") then
				while( v.pushItems(output,furnaceFuelSlot) == 0 and v.getItemDetail(furnaceFuelSlot) ~= nil) do
					print("Output full, Sleeping");
					sleep(60);
				end
				currentFuel = {};
			end
			if(currentFuel.name == nil) then
				local fuelItems = {};
				for k,_ in pairs(fuelPer.list()) do table.insert(fuelItems,k) end
				local n = 0;
				while((#fuelItems == 0 or v.pullItems(fuel,fuelItems[1+n%(#fuelItems)],64,furnaceFuelSlot) == 0) and v.getItemDetail(furnaceFuelSlot) == nil) do
					print("No fuel found, sleeping");
					n = n+1;
					sleep(60);
					fuelItems = {};
					for k, _ in pairs(fuelPer.list()) do table.insert(fuelItems,k) end
				end
			end
		end
		while(v.getItemDetail(furnaceOutSlot) ~= nil and v.pushItems(output,furnaceOutSlot) == 0) do
			print("Output full, Sleeping");
			sleep(60);
		end
		local currentlySmeltingDetails = v.getItemDetail(furnaceInSlot) or {count = 0};
		local smeltCount = currentlySmeltingDetails.count;
		local smeltItemName = currentlySmeltingDetails.name;
		local continue = true;
		for slot,item in pairs(items) do
			if continue then
				if(item.name == smeltItemName or smeltItemName == nil) then
					smeltItemName = item.name;
					if(v.pullItems(input,slot,item.count,furnaceInSlot)<item.count) then
						continue = false;
					end
				end
			end
		end
		sleep(1)
	end
	items = inputPer.list();
	hasItems = false;
	for k,v in pairs(items) do hasItems = true; end
end