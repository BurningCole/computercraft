--A*

local Astar = {
	lastRoutePlanned = false;
	detected = {};
	move = {
		forward = function() print("forward"); end,
		back =	  function() print("back"); end,
		up =      function() print("up"); end,
		down =    function() print("down"); end,
		setDir =  function() print("turn"); end
	},
	util = {
		print = print
	}
}

local routePlanned;
local nodes = {count = 0};
local visited = {}

local nodeIndexes = {};

function Block(x,y,z)
	Astar.detected[x..","..y..","..z] = true;
	print(x..","..y..","..z.." b=true")
end

function Clear(x,y,z)
	Astar.detected[x..","..y..","..z] = false;
	print(x..","..y..","..z.." b=false")
end

function SetBlockStatus(x,y,z,isBlocked)
	Astar.detected[x..","..y..","..z] = isBlocked;
	print(x..","..y..","..z.." b="..(isBlocked and "true" or "false"))
end

Astar.block = Block;
Astar.clear = Clear;
Astar.setBlocked = SetBlockStatus;

function CountKeys(myTable)
	numItems = 0
	for k,v in pairs(myTable) do
		numItems = numItems + 1
	end
	return numItems;
end

function AddNewNode(x,y,z,dir,fromNode,routeData)
	local locCode = x..","..y..","..z;
	if(Astar.detected[locCode]) then
		return false
	end
	local node = visited[locCode..","..dir];
	if(node ~= nil) then
		if(node.open) then
			return false;
		end
		if(node.d <= fromNode.d)then
			return false;
		end
		local subNodes = nodes[node.c + node.d];
		for k,v in ipairs(subNodes) do
			if(v == node) then
				subNodes[k] = subNodes[#subNodes];
				subNodes[#subNodes] = nil;
				break;
			end
		end
		local oldFromToNodes = node.from.to;
		for k,v in ipairs(oldFromToNodes) do
			if(v == node) then
				oldFromToNodes[k] = oldFromToNodes[#oldFromToNodes];
				oldFromToNodes[#oldFromToNodes] = nil;
				break;
			end
		end
		node.from = fromNode;
		node.d = fromNode.d+1;
	else
		if(fromNode.d == nil)then fromNode.d = -1;
		if((nodes.count%2000) == 1999)then print((nodes.count +1).." nodes, resting");sleep(0.1); end
		local start = routeData.start;
		node = {x=x,y=y,z=z,dir=dir,d=fromNode.d+1,c=CalculateDistance(start[1],start[2],start[3],x,y,z,dir), from =fromNode, to = {}, open = true};
		nodes.count = nodes.count + 1;
		visited[locCode..","..dir] = node;
	end
	if(fromNode.to == nil)then fromNode.to = {}; end
````local fromNodeTo = fromNode.to or ;
	fromNodeTo[#fromNodeTo+1] = node;
	if(nodes[node.c + node.d]) then
		local nodeArr = nodes[node.c + node.d];
		nodeArr[#nodeArr+1] = node;
	else
		nodes[node.c + node.d] = {node};
	end
	return node;
end

function CalculateDistance(sx,sy,sz,ex,ey,ez,dir)
	local distance = math.abs(sx-ex)+math.abs(sy-ey)+math.abs(sz-ez);
	if((dir==0 and sz~=ez)or(dir==1 and sx ~= ex)) then
		distance = distance +1;
	end
	return distance;
end

function PopNode()
	if(nodes.min == nil or nodes[nodes.min]==nil)then
		local minVal = 9999999;
		for k,v in pairs(nodes) do
			if(type(k) == "number" and k<minVal)then
				minVal = k;
			end
		end
		if(minVal>999999)then
			return false,"no nodes";
		end
		nodes.min = minVal;
	end
	local minArray = nodes[nodes.min];
	local popped = minArray[#minArray];
	minArray[#minArray] = nil;
	if(#minArray == 0)then
		nodes[nodes.min] = nil;
		nodes.min = nil;
	end
	nodes.count = nodes.count -1;
	return popped;
end

function UpdateRoute(routePlanned)

	local maxNodes = routePlanned.maxNodes;
	local sx,sy,sz = unpack(routePlanned.start);
	if(visited[sx..","..sy..","..sz..",1"]) then
		Astar.util.print("Destination Exists");
		routePlanned.path = visited[sx..","..sy..","..sz..",1"];
		return routePlanned;
	end
	if(visited[sx..","..sy..","..sz..",0"]) then
		Astar.util.print("Destination Exists");
		routePlanned.path = visited[sx..","..sy..","..sz..",0"];
		return routePlanned;
	end
	while(true) do
		if(nodes.count > maxNodes) then 
			Astar.util.print("Route too long");
			return false,"route too long"; 
		end
		local node = PopNode();

		node.open = false;
		
		if(node.from.y ~= node.y-1)then
			AddNewNode(node.x,node.y-1,node.z,node.dir,node, routePlanned);
		end
		if(node.from.y ~= node.y+1)then
			AddNewNode(node.x,node.y+1,node.z,node.dir,node, routePlanned);
		end
		
		if(node.dir == 0) then
			if(node.from.x ~= node.x-1)then
				AddNewNode(node.x-1,node.y,node.z,node.dir,node, routePlanned);
			end
			if(node.from.x ~= node.x+1)then
				AddNewNode(node.x+1,node.y,node.z,node.dir,node, routePlanned);
			end
		else
			if(node.from.z ~= node.z-1)then
				AddNewNode(node.x,node.y,node.z-1,node.dir,node, routePlanned);
			end
			if(node.from.z ~= node.z+1)then
				AddNewNode(node.x,node.y,node.z+1,node.dir,node, routePlanned);
			end
		end
		if(node.from.dir == node.dir)then
			local rotatedDir = 1-node.dir;
			AddNewNode(node.x,node.y,node.z,rotatedDir,node, routePlanned);
		end

		if(node.c == 0)then
			complete = true;
			local visitedNum = CountKeys(visited);
			Astar.util.print("Nodes: "..visitedNum-nodes.count.."/"..visitedNum);
			Astar.util.print("Distance: "..node.d);
			routePlanned.path = node;
			return routePlanned;
		end
		if(nodes.count == 0) then 
			Astar.util.print("Destination inaccessable");
			return false,"Destination inaccessable"; 
		end
	end
end

function CalculateRoute(sx,sy,sz,ex,ey,ez)
	Astar.util.print(sx,sy,sz,"to",ex,ey,ez);
	local routePlanned = {target = {ex,ey,ez},start={sx,sy,sz}};
	nodes = {count = 0};
	AddNewNode(ex,ey,ez,0,{},routePlanned);
	AddNewNode(ex,ey,ez,1,{},routePlanned);
	routePlanned.maxNodes = 30000;--,3*math.abs(sx-ex)*math.abs(sy-ey)*math.abs(sz-ez));
	nodeIndexes = {};
	visited = {};
	return UpdateRoute(routePlanned);
end

function RecalculateNodeDists(routeData)
	local newNodes = {};
	local bestNode = 999999;
	local count = 0;
	local x,y,z = unpack(routeData.start);
	for _,group in pairs(nodes) do
		if(type(group) == "table") then
			for _,node in ipairs(group) do
				node.c = CalculateDistance(x,y,z,node.x,node.y,node.z,node.dir);
				if(newNodes[node.c+node.d] == nil) then newNodes[node.c+node.d] = {} end
				local nodeGroup = newNodes[node.c+node.d];
				nodeGroup[#nodeGroup +1] = node;
				if(node.c+node.d<bestNode) then bestNode = node.c+node.d; end
				count = count+1;
			end
		end
	end
	newNodes.min = bestNode;
	newNodes.count = count;
	nodes = newNodes;
end

function RemoveBranch(node,routeData,depth)
	if(node == nil) then return; end
	local nodeCode = node.x..","..node.y..","..node.z..","..node.dir;
	visited[nodeCode] = nil;
	if(#node.to == 0)then
		local nodeGroup = nodes[node.d+node.c];
		for k,v in ipairs(nodeGroup) do
			if(v == node) then
				nodeGroup[k] = nodeGroup[#nodeGroup];
				nodeCode[#nodeGroup] = nil;
				if(#nodeGroup == 0)then
					nodes[node.d+node.c] = nil;
				end
				return;
			end
		end
	end
	if(depth == 0) then
		local fromto = node.from.to;
		for k,v in ipairs(fromto) do
			if(v == node)then
				fromto[k] = fromto[#fromto];
				fromto[#fromto] = nil;
				break;
			end
		end
	end
	
	for k,v in ipairs(node.to) do
		RemoveBranch(v,routeData,1);
	end
	node.to = nil;
	
	local decx = detected[node.x];
	if(decx ~= nil) then
		local decxy = decx[node.y];
		if(decxy ~= nil and decxy[node.z]==true) then
			return;
		end
	end
	
	local bestNeighbour;
	local bestDistance = 9999999;
	local neighbour = visited[node.x..","..(node.y-1)..","..node.z..","..node.dir];
	if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
		bestNeighbour = neighbour;
		bestDistance = neighbour.d;
	end
	neighbour = visited[node.x..","..(node.y+1)..","..node.z..","..node.dir];
	if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
		bestNeighbour = neighbour
		bestDistance = neighbour.d;
	end
	if(node.dir == 0) then
		neighbour = visited[(node.x-1)..","..node.y..","..node.z..","..node.dir];
		if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
		bestDistance = neighbour.d;
		end
		neighbour = visited[(node.x+1)..","..node.y..","..node.z..","..node.dir];
		if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end
	else
		neighbour = visited[node.x..","..node.y..","..(node.z-1)..","..node.dir];
		if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end
		neighbour = visited[node.x..","..node.y..","..(node.z+1)..","..node.dir];
		if(neighbour ~= undefined and neisghbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end
	end
	neighbour = visited[node.x..","..node.y..","..node.z..","..(1-node.dir)];
	if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
		bestNeighbour = neighbour
	end
	if(bestNeighbour ~= nil) then
		AddNewNode(node.x,node.y,node.z,node.dir,bestNeighbour,routeData);
	end
end

Astar.calculateRoute = CalculateRoute;
	
function FollowRoute(route)
	route = route or routePlanned;
	local curNode = routePlanned.path;
	local nextNode = curNode.from;
	Astar.move.setDir(curNode.dir);
	while nextNode do
		local moved = true;
		if(nextNode.dir ~= curNode.dir) then
			Astar.move.setDir(nextNode.dir);
		elseif(nextNode.y ~= curNode.y) then
			if(nextNode.y>curNode.y) then 
				moved = Astar.move.up();
			else 
				moved = Astar.move.down();
			end
		else
			if(nextNode.x+nextNode.z>curNode.y+curNode.z) then 
				moved = Astar.move.forward();
			else 
				moved = Astar.move.back();
			end
		end
		if(moved) then
			Astar.util.print(curNode.x..","..curNode.y..","..curNode.z..","..curNode.dir..","..curNode.d)
			curNode = nextNode;
			nextNode = curNode.from;
			if(curNode.d == 0) then return true; end
		else
			if(nextNode.d == 0) then return true; end
			Astar.util.print("Blocked node found, Recalculating.");
			Astar.util.print(nextNode.x..","..nextNode.y..","..nextNode.z.." blocked");
			Block(nextNode.x,nextNode.y,nextNode.z);
			route.start = {curNode.x,curNode.y,curNode.z};
			
			local rotatedNodeCode = nextNode.x..","..nextNode.y..","..nextNode.z..","..(1-nextNode.dir);		
			RemoveBranch(nextNode,route,0);
			RemoveBranch(backNodes[rotatedNodeCode],route,0);
			
			RecalculateNodeDists(route);
			route,reason = UpdateRoute(route);
			if(not route)then
				Astar.util.print(reason);
				return false,reason
			end
			curNode = routePlanned.path;
			nextNode = curNode.from;
			--RemoveTrailingNodes(curNode.d+10,curNode.x,curNode.y,curNode.z);
			Astar.move.setDir(curNode.dir);
		end
	end
	return true;
end

Astar.follow = FollowRoute;

return Astar;