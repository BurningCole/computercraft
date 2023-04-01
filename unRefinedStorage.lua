local userInterfaceChestIds = {["minecraft:chest_11"] = true,["reinfchest:gold_chest_0"] = true};
local userInterfaceChests = {};
local storageChests = {};
local items = {};
local emptySlots = {total = 0};
local totalSlots = {total = 0};
local resultChest = "reinfchest:gold_chest_0";
local storageFile = "config/preCompiledInventory.cnf"
local debugScreen = peripheral.find("monitor");

local modem = nil;

local listenId = 40513;

for _,m in ipairs({peripheral.find('modem')}) do
	if(m.isWireless()) then
		modem = m;
		break;
	end
end
	
if(modem ~= nil) then
	modem.open(listenId);
end

if(debugScreen) then
	debugScreen.setTextScale(0.5)
end

local storagePeripherals = {"minecraft:chest","reinfchest:gold_chest"};
local genericChest = "minecraft:chest";

local outputInventory = nil;

function chestIsStorage(chestId)
	return not userInterfaceChestIds[chestId];
end

function addConnectedInventory(chestId,chest)
	chest = chest or peripheral.wrap(chestId);
	if(chestIsStorage(chestId)) then
		storageChests[chestId] = chest;
		checkInventoryItems(chestId);
		totalSlots.total = totalSlots.total -(totalSlots[chestId] or 0) + chest.size();
		totalSlots[chestId] = chest.size();
		printDebug("Storage: "..chestId.." added");
	else
		userInterfaceChests[chestId] = chest;
		printDebug("Interface: "..chestId.." added");
		--handle other
	end
end

function removeConnectedInventory(chestId)
	if(chestIsStorage(chestId)) then
		local markremoval = {};
		for k,v in pairs(items) do
			if(v[chestId]~=nil) then
				v.total = v.total - v[chestId];
				v[chestId] = nil;
				if(v.total<=0) then
					table.insert(markremoval,k);
				end
			end
		end
		for k,v in ipairs(markremoval) do
			items[v] = nil;
		end
		emptySlots.total = emptySlots.total - (emptySlots[chestId] or 0);
		emptySlots[chestId] = nil;
		totalSlots.total = totalSlots.total -(totalSlots[chestId] or 0);
		totalSlots[chestId] = 0;
		printDebug("Storage: "..chestId.." removed");
	else
		userInterfaceChests[chestId] = nil;
		printDebug("inerface: "..chestId.." removed");
		--handle other
	end
end

function initConnectedInventories()
	storageChests = {};
	for _,storagePeripheral in ipairs(storagePeripherals) do
	for _,chest in ipairs({peripheral.find(storagePeripheral)}) do
		local chestId = peripheral.getName(chest);
		if(chestIsStorage(chestId)) then
			storageChests[chestId] = chest;
		else
			userInterfaceChests[chestId] = chest;
			--handle other
		end
	end
	end
end

function checkConnectedInventories()
	storageChests = {};
	for _,storagePeripheral in ipairs(storagePeripherals) do
	for _,chest in ipairs({peripheral.find(storagePeripheral)}) do
		addConnectedInventory(peripheral.getName(chest),chest);
	end
	end
end

function checkInventoryItems(chestId,checkRemoved)
	checkRemoved = checkRemoved or false;
	local chest = storageChests[chestId];
	local chestItems = {};
	local filledSlots = 0;
	for slot,item in pairs(chest.list()) do
		local ref = item.name..(item.nbt or "");
		filledSlots = filledSlots +1;
		if(chestItems[ref] == nil) then
			chestItems[ref] = {
				slot = slot,
				count = item.count
			};
		else
			chestItems[ref].count = chestItems[ref].count + item.count;
		end
	end
	for name, data in pairs(chestItems) do
		if(items[name] == nil) then
			local detail = chest.getItemDetail(data.slot)
			items[name] = {
				total = data.count, 
				stackSize = detail.maxCount,
				displayName = detail.displayName,
				[chestId] = data.count
			};
		else
			local itemData = items[name];
			local difference = data.count;
			if(itemData[chestId] ~= nil) then
				difference = difference - itemData[chestId];
			end
			itemData.total = itemData.total + difference;
			itemData[chestId] = data.count;
		end
	end
	if checkRemoved then
		local toRemove = {}
		for name, item in pairs(items) do
			if(item[chestId] ~= nil and chestItems[name] == nil) then
				item.total = item.total - item[chestId]; 
				item[chestId] = nil;
				if(item.total <= 0) then
					table.insert(toRemove,name);
				end
			end
		end
		for _,name in ipairs(toRemove) do
			items[name] = nil;
		end
	end
	emptySlots.total = emptySlots.total - (emptySlots[chestId] or 0) + chest.size() - filledSlots;
	emptySlots[chestId] = chest.size() - filledSlots;
end

function findIncompleteStack(chest,itemName, stackSize)
	local items = chest.list();
	for slot, item in pairs(items) do
		local ref = item.name..(item.nbt or "");
		if(ref == itemName and item.count<stackSize) then 
			return slot
		end
	end
	return false;
end

function chestHasEmpty(chest)
	local slots = chest.size();
	local items = chest.list();
	for i=1,slots do
		if(items[i] == nil) then 
			return i
		end
	end
	return false;
end

function StoreItem(fromChestId,slot)
	local chest = userInterfaceChests[fromChestId];
	if(fromChestId == "player" or fromChestId == "output") then
		chest = outputInventory;
	end
	if(chest == nil) then
		printDebug("chest "..fromChestId.." doesn't exist");
		return false;
	end
	local item = chest.getItemDetail(slot)
	if(item == nil) then
		return true;
	end
	local ref = item.name..(item.nbt or "");
	local itemStore = items[ref];
	if(itemStore ~= nil) then
		local existingStack = itemStore.total % itemStore.stackSize;
		local pushToExisting = math.min(itemStore.stackSize - existingStack,item.count);
		if(item.count == itemStore.stackSize)then
			pushToExisting = 0;
		end
		local pushToNew = item.count - pushToExisting;
		for key, chestdetail in pairs(itemStore) do
			local storageChest = storageChests[key];
			if(storageChest ~= nil) then 
				if(chestdetail % itemStore.stackSize ~=0 ) then
					
					local existingStackLoc = findIncompleteStack(storageChest,ref,itemStore.stackSize);
					if(existingStackLoc == false) then
						checkInventoryItems(key,true);
						return false;
					end
					chest.pushItems(key,slot,pushToExisting,existingStackLoc);
					itemStore[key] = itemStore[key] + pushToExisting;
					itemStore.total = itemStore.total + pushToExisting;
					printDebug("Stored "..pushToExisting.."*"..itemStore.displayName.." To "..key);
					pushToExisting = 0;
					if(pushToNew <= 0) then
						return true;
					end
				end
				if(pushToNew > 0 and 
					chest.pushItems(key,slot,pushToNew) > 0
				) then
					itemStore[key] = itemStore[key] + pushToNew;
					itemStore.total = itemStore.total + pushToNew;
					emptySlots.total = emptySlots.total -1;
					emptySlots[key] = emptySlots[key] -1;
					printDebug("Stored "..pushToNew.."*"..itemStore.displayName.." To "..key);
					pushToNew = 0
					if(pushToExisting <= 0) then
						return true;
					end
				end
			end
		end
	else
		items[ref] = {
			total = 0, 
			stackSize = item.maxCount,
			displayName = item.displayName
		};
		itemStore = items[ref];
	end
	for key, storageChest in pairs(storageChests) do
		local stored = chest.pushItems(key,slot,item.count);
		if(stored > 0) then
			itemStore[key] = (itemStore[key] or 0) + stored;
			itemStore.total = itemStore.total + stored;
			emptySlots.total = emptySlots.total -1;
			emptySlots[key] = emptySlots[key] -1;
			printDebug("Stored "..stored.."*"..itemStore.displayName.." To "..key);
			return true;
		end
	end
	return false;
end

function FetchItem(toChestId,itemName, count)
	local fetchChest = userInterfaceChests[toChestId];
	if(toChestId == "player" or toChestId == "output") then
		fetchChest = outputInventory;
	elseif(userInterfaceChests[toChestId] == nil) then
		printDebug("Error: invalid chest");
		return false, "invalid chest";
	end
	printDebug("Fetching: "..itemName.."*"..count);
	if(items[itemName] == nil) then
		printDebug("Error: item doesn't exist");
		return false, "No items";
	end
	local itemStore = items[itemName];
	local existingStack = itemStore.total % itemStore.stackSize;
	local firstAllowedSlot = 2*fetchChest.size()/3+1;
	local fetchChestItems = fetchChest.list();
	local empty = {};
	if(outputInventory == fetchChest) then
		empty[1] = {nil,99999};
	else
		for i = fetchChest.size(),firstAllowedSlot,-1 do
			local slotItem = fetchChestItems[i];
			if(slotItem == nil or slotItem.name == itemName and slotItem.count < itemStore.stackSize) then
				empty[#empty+1] = {i,itemStore.stackSize};
			elseif(slotItem.name == itemName and slotItem.count < itemStore.stackSize) then
				empty[#empty+1] = {i,itemStore.stackSize - slotItem.count};
			end
		end
		if(#empty == 0)then
			return false;
		end
	end
	local remaining = count - existingStack;
	for key, chestdetail in pairs(itemStore) do
		local storageChest = storageChests[key];
		if(storageChest ~= nil) then 
			if(existingStack > 0 and chestdetail>0 and chestdetail % itemStore.stackSize ~=0 ) then
				local existingStackLoc = findIncompleteStack(storageChest,itemName,itemStore.stackSize);
				if(existingStackLoc) then
					while(existingStack>0) do
						if(#empty == 0)then
							return false;
						end
						local extractSlot = empty[#empty];
						local removecount = math.min(existingStack,count);
						local moved = fetchChest.pullItems(key,existingStackLoc,removecount,extractSlot[1]);
						if(extractSlot[2]>moved and moved >= removecount)then
							extractSlot[2] = extractSlot[2] - moved;
						else
							table.remove(empty);
						end
						existingStack = existingStack - moved;
						if(moved == 0 or moved == count)then
							existingStack = 0;
						end
						itemStore[key] = itemStore[key] - moved;
						itemStore.total = itemStore.total - moved;
						printDebug("Fetched "..moved.." From "..key);
						if(existingStack == moved) then
							emptySlots.total = emptySlots.total +1;
							emptySlots[key] = emptySlots[key] +1;
						end
					end
					printDebug("remaining "..itemStore[key].." / "..itemStore.total);
					if(itemStore[key] <= 0) then
						itemStore[key] = nil;
						if(itemStore.total <= 0) then
							items[itemName] = nil;
							return true, remaining;
						end
					end
					if(remaining <= 0) then
						return true;
					end
				else
					checkInventoryItems(key,true);
				end
			end
			if(remaining > 0) then
				local storedItems = storageChest.list();
				for slot, item in pairs(storedItems) do
					local ref = item.name..(item.nbt or "");
					if(ref == itemName) then
						local removecount = math.min(remaining,itemStore.stackSize);
						local extractSlot = nil;
						for _,v in ipairs(empty) do
							if(v[2]>=removecount) then
								extractSlot = v[1];
								v[2] = v[2]-removecount;
								break;
							end
						end
						local moved =fetchChest.pullItems(key,slot,removecount,extractSlot);
						if(moved == itemStore.stackSize)then
							emptySlots.total = emptySlots.total +1;
							emptySlots[key] = emptySlots[key] +1;
						end
						printDebug("Fetched "..moved.." From "..key);
						remaining = remaining-moved;
						itemStore[key] = itemStore[key] - moved;
						itemStore.total = itemStore.total - moved;
						printDebug("reamining "..itemStore[key].." / "..itemStore.total);
						if(itemStore[key] <= 0) then
							itemStore[key] = nil;
							if(itemStore.total <= 0) then
								items[itemName] = nil;
								return true, remaining;
							end
						end
						if(remaining <= 0 and existingStack <= 0) then 
							return true
						end
					end
				end
			end
		end
	end
	printDebug("Fetched "..(count-remaining).."/"..count);
	return false;
end

function printDebug(str)
	if(debugScreen ~= nil) then
		debugScreen.scroll(1);
		local _, ySize = debugScreen.getSize();
		debugScreen.setCursorPos(1,ySize);
		debugScreen.write(str);
	end
end

function printItemCounts()
	printDebug("Items:");
	for name, item in pairs(items) do
		printDebug("- "..item.displayName.." * "..item.total)
	end
end

function printChests()
	printDebug("Storages:");
	for chestId, chest in pairs(storageChests) do
		printDebug("- "..peripheral.getName(chest)..": "..chest.size().." slots");
	end
end

function writeInventoryFile()
	local configFile = fs.open(storageFile, "w");
	configFile.writeLine("items");
	for id,v in pairs(items) do
		configFile.writeLine(" "..id);
		configFile.writeLine("  total = 0");
		configFile.writeLine("  stackSize = " .. v.stackSize);
		configFile.writeLine("  displayName = " .. v.displayName);
		--[[
			items
				[name]
					total = data.count, 
					stackSize = detail.maxCount,
					displayName = detail.displayName,
					[chestId] = data.count
			};
		]]
	end
end

function readInventoriesFile()
	initConnectedInventories()
	local configFile = fs.open(storageFile, "r");
	local parent = {};
	parent[1] = items;
	local parentSpaces = {0};
	local line;
	while(true) do
		local line = configFile.readLine();
		if(line == nil) then
			break;
		end
		local _, spaces = line:find("^ *");
		if(line:find("%w")==spaces+1 or line:find("^ *-[^-]") or line:find("^ *-$")) then
			local lineDetails = line:match("[^ =][^=]*[^ =]") or line:match("([^ =])");
			if(spaces>parentSpaces[#parentSpaces]) then
				table.insert(parentSpaces,spaces);
				printDebug("new level: "..spaces.." > "..#parentSpaces);
			elseif(spaces < parentSpaces[#parentSpaces]) then
				repeat
					table.remove(parentSpaces);
				until(parentSpaces[#parentSpaces] <= spaces);
				printDebug("lowered level to: "..parentSpaces[#parentSpaces].." > "..#parentSpaces);
			end
			local blockAdd = false;
			if(spaces == 0)then
				if(lineDetails == "items") then
					parent[2] = items;
					blockAdd = true;
				elseif(lineDetails == "interfaces") then
					parent[2] = userInterfaceChestIds
				end
			end
			if(line:find("%w")~=spaces+1) then
				lineDetails = #(parent[#parentSpaces]);
			end
			if(not blockAdd) then
				local value = line:match("= *([^ =][^=]*[^ =])") or line:match("= *([^ =])");
				if(value ~= nil) then
					local nValue = tonumber(value);
					if(nValue == nil) then
						parent[#parentSpaces][lineDetails] = value;
					else
						parent[#parentSpaces][lineDetails] = nValue;
					end
					printDebug(lineDetails.." = "..value);
				else
					local newObject = {};
					parent[#parentSpaces][lineDetails] = newObject;
					parent[#parentSpaces+1] = newObject;
					printDebug(lineDetails.." = {}");
				end
			end
		end
	end
	configFile.close();
end

for _,manipulator in ipairs({peripheral.find("manipulator")}) do
	printDebug("checking: "..peripheral.getName(manipulator));
	if(manipulator.hasModule("plethora:introspection")) then
		outputInventory = manipulator.getInventory();
		resultChest = "output";
		printDebug("inventory Found");
		break;
	end
end

if(fs.exists(storageFile)) then
	--read inventories;
	readInventoriesFile();
else
	--printChests();
	--printItemCounts();
end
checkConnectedInventories();

-- user interface

--[[
/---------------------\
| Search:             |
| [search-------]     |
|                     |
| [item name]*[count] |
...
| [item name]*[count] |
|                     |
| {1} {5} {10} {64}   |
| [NInput] {N}        |
\---------------------/

]]
local inputBgColour = colours.lightGrey;
local inputFgColour = colours.black;
local boxColours = {colours.lightBlue, colours.cyan};
local selectedColour = colours.green;
local terminalSize = {term.getSize()};
local focusedInput = 0;
local inputCount = 2;
local scrollOffset = 0;
local selectedIndex = 1;
local searchText = "";
local numberText = "";
local filteredItems = {};

local textboxStarts = {
	{2,2},
	{terminalSize[1] - 6,terminalSize[2] -1}
};
local textboxLengths = {terminalSize[1]-2,4};

--						x,y,width,         height
local itemListBounds = {1,3,terminalSize[1],terminalSize[2]-7};

local textRemoved = false;

local itemListW = {
	terminalSize[1] - 8;
}

function drawInputBoxText()
	term.setTextColour(inputFgColour);
	term.setBackgroundColour(inputBgColour);
	term.setCursorPos(table.unpack(textboxStarts[1]));
	term.write(searchText:sub(math.max(0,#searchText-textboxLengths[1])) .. string.rep(" ",textboxLengths[1]-#searchText));
	term.setCursorPos(table.unpack(textboxStarts[2]));
	term.write(numberText .. string.rep(" ",textboxLengths[2]-#numberText));
	term.setCursorBlink(true);
	if(focusedInput == 0) then
		term.setCursorPos(textboxStarts[1][1]+math.min(textboxLengths[1]-1,#searchText),textboxStarts[1][2]);
	elseif(focusedInput == 1) then
		term.setCursorPos(textboxStarts[2][1]+math.min(textboxLengths[2]-1,#numberText),textboxStarts[2][2]);
	end
end

function drawButtons()
	term.setTextColour(inputFgColour);
	term.setBackgroundColour(inputBgColour);
	local oldCursor = {term.getCursorPos()};
	term.setCursorPos(2,terminalSize[2]-1);
	term.write(" 1 ");
	term.setCursorPos(6,terminalSize[2]-1);
	term.write(" 4 ");
	term.setCursorPos(10,terminalSize[2]-1);
	term.write(" 10 ");
	term.setCursorPos(15,terminalSize[2]-1);
	term.write(" 64 ");
	term.setCursorPos(terminalSize[1] - 11,terminalSize[2]-1);
	term.write(" X ");
	term.setCursorPos(oldCursor[1],oldCursor[2]);
end

function drawItemList()
	local oldCursor = {term.getCursorPos()};
	if(selectedIndex-1<scrollOffset) then
		scrollOffset = math.min(selectedIndex-1,math.max(0,#filteredItems-itemListBounds[4]));
	elseif(selectedIndex>scrollOffset + itemListBounds[4]) then
		scrollOffset = math.max(0,selectedIndex - itemListBounds[4]);
	end
	term.setTextColour(inputFgColour);
	if(#filteredItems == 0 and #searchText == 0) then
		textRemoved = true;
		updateFilter();
	end
	
	for i = 1,itemListBounds[4] do
		term.setBackgroundColour(boxColours[1+i%2]);
		if(scrollOffset + i == selectedIndex) then
			term.setBackgroundColour(selectedColour);
		end
		term.setCursorPos(itemListBounds[1],itemListBounds[2]+i);
		if(#filteredItems >= scrollOffset + i) then
			local item = filteredItems[scrollOffset + i].item;
			local name = item.displayName;
			local number = numberToText(item.total)
			local line = " " .. name:sub(1,itemListBounds[3]-9) .. 
					string.rep(" ",itemListBounds[3] - #name - 8) .. "|" .. 
					string.rep(" ",5-#number) .. number.." ";
			term.write(line);
		else
			term.write(string.rep(" ", itemListBounds[3]));
		end
	end
	term.setCursorPos(itemListBounds[1]+1,itemListBounds[2]+itemListBounds[4]+1);
	term.setBackgroundColour(boxColours[2-itemListBounds[4]%2]);
	term.write(emptySlots.total.."/"..totalSlots.total.." spaces");
	term.setCursorPos(oldCursor[1],oldCursor[2]);
end

function addRequirement(item,number,otherReqirements)
	otherReqirements = otherReqirements or {};
	if(otherReqirements[item] ~= nil)then
		number = number + otherReqirements[item];
	end
	local dictItem = items[item];
	if(dictItem == nil) then
		otherReqirements[item] = number;
		return true;
	end
	if(number <= dictItem.total) then
		otherReqirements[item] = number;
		return otherReqirements;
	end
	number = number - dictItem.total;
	if(dictItem.craft ~= nil) then
		otherReqirements[item] = dictItem.total;
		local craftmethod = dictItem.craft;
		local crafts = math.ceil(number/craftmethod.output);
		local left = craftmethod.output-((number-1) % craftmethod.output)-1;
		for itemId, number in pairs(craftmethod.ingredients) do
			addRequirement(itemId,number,otherReqirements);
		end
		return otherReqirements;
	end
	return false, number;
end

function craftItems(item, number)
	local needed, missing = addRequirement(item,number);
	if(needed == false) then
		return false, missing;
	end
end

function numberToText(num)
	if(num < 1e4) then		--up to 9999
		return (num) .. " ";
	elseif(num < 1e7) then	--up to 9999K
		return math.floor(num/1000).."K";
	elseif(num < 1e10) then	--up to 9999M 
		return math.floor(num/1e6 ).."M";
	elseif(num < 1e13) then	--up to 9999B
		return math.floor(num/1e9 ).."B";
	elseif(num < 1e16) then	--up to 9999T
		return math.floor(num/1e12).."T";
	elseif(num < 1e19) then	--up to 9999Q
		return math.floor(num/1e15).."Q";
	end
	return "many";
end

local keyActions = {
	[keys.enter] = function()
		if(focusedInput == 1 and filteredItems[selectedIndex] ~= nil and #numberText > 0) then
			FetchItem(resultChest,filteredItems[selectedIndex].key,tonumber(numberText));
			drawItemList()
		end
	end,
	[keys.backspace] = function()
		if(focusedInput == 0) then
			if(#searchText > 0) then
				searchText = searchText:sub(1,-2);
				textRemoved = true;
				updateFilter();
			end
		elseif(focusedInput == 1) then
			if(#numberText > 0) then
				numberText = numberText:sub(1,-2);
			end
		end
		drawInputBoxText();
	end,
	[keys.right] = function() 
		focusedInput = (focusedInput + 1) %inputCount;
		drawInputBoxText();
	end,
	[keys.left] = function() 
		focusedInput = (inputCount + focusedInput - 1) %inputCount;
		drawInputBoxText();
	end,
	[keys.down] = function()
		selectedIndex = selectedIndex +1;
		if(selectedIndex>#filteredItems) then
			selectedIndex = #filteredItems;
		else
			drawItemList();
		end
	end,
	[keys.up] = function()
		selectedIndex = selectedIndex -1;
		if(selectedIndex<1) then
			selectedIndex = 1;
		else
			drawItemList();
		end
	end,
	[keys.pageUp] = function()
		selectedIndex = selectedIndex - itemListBounds[4];
		if(selectedIndex<1) then
			selectedIndex = 1;
		end
		drawItemList();
	end,
	[keys.pageDown] = function()
		selectedIndex = selectedIndex + itemListBounds[4];
		if(selectedIndex>#filteredItems) then
			selectedIndex = #filteredItems;
		end
		drawItemList();
	end,
	[keys.home] = function()
		selectedIndex = 1;
		drawItemList();
	end, -- home
	[keys["end"]] = function()
		selectedIndex = #filteredItems;
		drawItemList();
	end, -- end
	[340] = nil, -- shift
	[341] = nil, -- control
	
};


function updateFilter()
	local selectedId = nil;
	if(#filteredItems >= selectedIndex) then
		selectedId = filteredItems[selectedIndex].key;
	end
	selectedIndex = 1;
	local lowerSearchText = searchText:lower();
	local unsorted = false;
	local maxVal = nil;
	if(textRemoved) then
		filteredItems = {};
		for k,v in pairs(items) do
			if(v.total>0 and v.displayName:lower():find(lowerSearchText)) then
				filteredItems[#filteredItems +1] = {key = k, item = v}
				if(k == selectedId) then
					selectedIndex = #filteredItems;
				end
			end
			if(maxVal ~= nil and maxVal>v.total)then
				unsorted = true;
			end
			maxVal = v.total;
		end
	else
		local newFiltered = {}
		for k,v in ipairs(filteredItems) do
			if(v.item.total>0 and v.item.displayName:lower():find(lowerSearchText)) then
				newFiltered[#newFiltered +1] = v;
			end
			if(k == selectedId) then
				selectedIndex = #filteredItems;
			end
			if(maxVal ~= nil and maxVal>v.total)then
				unsorted = true;
			end
			maxVal = v.total;
		end
		filteredItems = newFiltered;
	end
	if(unsorted) then
		table.sort(filteredItems,function(a,b) return a.item.total > b.item.total; end);
	end
	printDebug("Filtering "..searchText);
	if(#filteredItems == 0 and #searchText == 0) then
		return;
	end
	drawItemList();
	textUpdateTimer = nil;
	textRemoved = false;
end

local modemMessages = {
	["List"] = function(filter)
		local returnData = {["Empty"]=emptySlots.total,["Total"]=totalSlots.total};
		local count = 0;
		printDebug("Parsed command: List filter="..(filter or "None"));
		for id,data in pairs(items) do
			if(filter == nil or id:find(filter) or data.displayName:lower():find(filter)) then
				returnData[id] = {
					displayName = data.displayName;
					count = data.total;
				}
				count = count + 1;
			end
		end
		printDebug("Found "..count.." items");
		return returnData;
	end,
	["Fetch"] = function(item,count)
		count = tonumber(count);
		if(item == nil or count == nil) then
			return "false";
		end
		printDebug("Parsed command: Fetch "..(item or "Nothing").." * "..(count or 0));
		if(outputInventory) then
			return FetchItem("player",item,count);
		else
			return false;
		end
	end,
	["Store"] = function(slot)
		slot = tonumber(slot);
		if(slot == nil) then
			return "false";
		end
		printDebug("Parsed command: Store from "..(slot or "Nowhere"));
		if(outputInventory) then
			return StoreItem("player",slot);
		else
			return false;
		end
	end,
	["Ping"] = function()
		return "Pong"
	end
}

local runActions = {
	["mouse_click"] = function(ev,peripheral,x,y)
		printDebug("Pressed: "..x..","..y);
		if(y>=4 and y<=terminalSize[2]-2) then
			selectedIndex = math.min(y + scrollOffset - 3,#filteredItems);
			drawItemList();
		elseif(y<4) then
			focusedInput = 0;
		elseif(x<5) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(resultChest,filteredItems[selectedIndex].key,1);
				drawItemList();
			end
		elseif(x<9) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(resultChest,filteredItems[selectedIndex].key,4);
				drawItemList();
			end
		elseif(x<14) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(resultChest,filteredItems[selectedIndex].key,10);
				drawItemList();
			end
		elseif(x<19) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(resultChest,filteredItems[selectedIndex].key,64);
				drawItemList();
			end
		elseif(x<terminalSize[1] - 12) then
			if(filteredItems[selectedIndex] ~= nil and #numberText > 0) then
				FetchItem(resultChest,filteredItems[selectedIndex].key,tonumber(numberText));
				drawItemList();
			end
		else
			focusedInput = 1;
		end
	end,
	["char"] = function(ev,character)
		if(focusedInput == 0) then
			searchText = searchText..character;
			updateFilter();
		elseif(focusedInput == 1) then
			if(tonumber(character)) then
				numberText = numberText..character;
			end
			if(#numberText > 4) then
				numberText = "9999";
			end
		end
		drawInputBoxText();
	end,
	["key"] = function(ev,key,held)
		if(keyActions[key] ~= nil) then
			keyActions[key]();
		end
	end,
	["mouse_scroll"] = function(ev,distance)
		selectedIndex = selectedIndex + distance;
		if(selectedIndex>#filteredItems) then
			selectedIndex = #filteredItems;
		elseif(selectedIndex<1) then
			selectedIndex = 1;
		end
		drawItemList();
	end,
	["paste"] = function(ev,pasted)
		if(focusedInput == 0) then
			searchText = searchText..pasted;
			updateFilter();
		elseif(focusedInput == 1) then
			if(tonumber(pasted)) then
				numberText = numberText..pasted;
			end
			if(#numberText > 4) then
				numberText = "9999";
			end
		end
	end,
	["peripheral"] = function(ev,name)
		local newPeripheral = peripheral.wrap(name);
		if(newPeripheral.pullItems) then
			addConnectedInventory(name);
		end
	end,
	["peripheral_detach"] = function(ev, name)
		if(storageChests[name]) then
			removeConnectedInventory(name);
		end
	end,
	["modem_message"] = function(ev, side, channel, replyChannel, message, distance)
		printDebug("Recieved Request: "..message)
		local method = message:match("^[^!]+");
		local submessages = {};
		for submessage in message:gmatch("!([^!]+)") do
			submessages[#submessages +1] = submessage;
			printDebug("arg["..#submessages.."]: "..submessage);
		end
		if(modemMessages[method]) then
			local returnData = nil;
			if(#submessages) then
				returnData =modemMessages[method](table.unpack(submessages))
			else
				returnData = modemMessages[method]();
			end
			if(type(returnData)=="table") then
				returnData = textutils.serialise(returnData,{ compact = true });
			end
			peripheral.call(side,"transmit",replyChannel,channel,returnData);
		end
	end
};

term.setBackgroundColour(colours.white);
term.clear();
drawItemList();
drawInputBoxText();
drawButtons();

function eventLoop()
	while true do
		local ev = {os.pullEvent()};
		if(runActions[ev[1]] ~= nil) then
			runActions[ev[1]](table.unpack(ev));
		end
	end
end

function updateLoop()
	while true do
		local moved = false
		for key, chest in pairs(userInterfaceChests) do
			local items = chest.list();
			local chestSize = chest.size();
			for i = 1,(2*chestSize/3) do
				if(items[i] ~= nil) then
					StoreItem(key,i);
					moved = true;
				end
			end
		end
		if(moved) then
			drawItemList();
			os.sleep(5);
		else
			os.sleep(5);
		end
	end
end

parallel.waitForAny(updateLoop,eventLoop);
