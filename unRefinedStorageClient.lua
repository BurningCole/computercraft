local modem = peripheral.find("modem") or error("No modem attached", 0);
local transmitId = 40513;
local responseId = 40513 + os.getComputerID();

modem.open(responseId);

local debugScreen = peripheral.find("monitor");
local items = {};

if(debugScreen) then
	debugScreen.setTextScale(0.5)
end

function printDebug(str)
	if(debugScreen ~= nil) then
		debugScreen.scroll(1);
		local _, ySize = debugScreen.getSize();
		debugScreen.setCursorPos(1,ySize);
		debugScreen.write(str);
	end
end

function FetchItem(item,count)
	modem.transmit(transmitId,responseId,"Fetch!"..item.."!"..count);
	while true do
		local evt,_,_,newTransmitId,response=os.pullEvent()
		if evt == "modem_message" then
			transmitId = newTransmitId;
			RefreshItem(item)
			return response == "true";
		end
	end
end

function StoreItem(slot)
	modem.transmit(transmitId,responseId,"Store!"..slot);
	while true do
		local evt,_,_,newTransmitId,response=os.pullEvent()
		if evt == "modem_message" then
			transmitId = newTransmitId;
			RefreshItems()
			return response == "true";
		end
	end
end

function RefreshItems()
	modem.transmit(transmitId,responseId,"List");
	while true do
		local evt,_,_,newTransmitId,response=os.pullEvent()
		if evt == "modem_message" then
			transmitId = newTransmitId;
			if(response == "false") then
				error("Error refreshing");
			end
			items = textutils.unserialise(response);
			return items;
		end
	end
	if(#filteredItems > 0) then
		updateFilter();
	end
end

function RefreshItem(item)
	modem.transmit(transmitId,responseId,"List!"..item);
	while true do
		local evt,_,_,newTransmitId,response=os.pullEvent()
		if evt == "modem_message" then
			if(response == "false") then
				error("Error refreshing");
			end
			local serverItems = textutils.unserialise(response);
			for k,v in pairs(serverItems) do
				items[k] = v;
			end
			if(items[item] ~= nil and serverItems[item] == nil) then
				items[item] = nil;
			end
			return items;
		end
	end
	if(#filteredItems > 0) then
		updateFilter();
	end
end
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

RefreshItems();

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
			local number = numberToText(item.count)
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
	term.write((items["Empty"] or "????").."/"..(items["Total"] or "????").." spaces");
	term.setCursorPos(oldCursor[1],oldCursor[2]);
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
			FetchItem(filteredItems[selectedIndex].key,tonumber(numberText));
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
			if(type(v) == "table") then 
			if(v.count>0 and v.displayName:lower():find(lowerSearchText)) then
				filteredItems[#filteredItems +1] = {key = k, item = v}
				if(k == selectedId) then
					selectedIndex = #filteredItems;
				end
			end
			if(maxVal ~= nil and maxVal>v.count)then
				unsorted = true;
			end
			maxVal = v.count;
			end
		end
	else
		local newFiltered = {}
		for k,v in ipairs(filteredItems) do
			if(v.item.count>0 and v.item.displayName:lower():find(lowerSearchText)) then
				newFiltered[#newFiltered +1] = v;
			end
			if(k == selectedId) then
				selectedIndex = #filteredItems;
			end
			if(maxVal ~= nil and maxVal>v.count)then
				unsorted = true;
			end
			maxVal = v.count;
		end
		filteredItems = newFiltered;
	end
	if(#filteredItems == 0 and #searchText == 0) then
		return;
	end
	if(unsorted) then
		table.sort(filteredItems,function(a,b) return a.item.count > b.item.count; end);
	end
	printDebug("Filtering "..searchText);
	drawItemList();
	textUpdateTimer = nil;
	textRemoved = false;
end

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
				FetchItem(filteredItems[selectedIndex].key,1);
				drawItemList();
			end
		elseif(x<9) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(filteredItems[selectedIndex].key,4);
				drawItemList();
			end
		elseif(x<14) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(filteredItems[selectedIndex].key,10);
				drawItemList();
			end
		elseif(x<19) then
			if(filteredItems[selectedIndex] ~= nil) then
				FetchItem(filteredItems[selectedIndex].key,64);
				drawItemList();
			end
		elseif(x<terminalSize[1] - 12) then
			if(filteredItems[selectedIndex] ~= nil and #numberText > 0) then
				FetchItem(filteredItems[selectedIndex].key,tonumber(numberText));
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
	end
};

term.setBackgroundColour(colours.white);
term.clear();
RefreshItems();
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

eventLoop();