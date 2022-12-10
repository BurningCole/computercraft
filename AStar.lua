--A*

local Astar = {
	lastRoutePlanned = false;
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
local backNodes = {count = 0};
local forwardNodes = {count = 0};
local visited = {};
local detected = {};

local nodeIndexes = {};

function Block(x,y,z)
	local dec = detected;
	if(dec[x] == nil) then dec[x] = {[y]={[z]=true}}; return; end
	local decx = dec[x];
	if(decx[y] == nil) then decx[y] = {[z]=true}; return; end
	local decxy = decx[y];
	decxy[z] = true;
	print(x..","..y..","..z.." b=true")
end

function Clear(x,y,z)
	local decx = detected[x];
	if decx == nil then return true; end
	local decxy = decx[y];
	if decxy == nil then return true; end
	decxy[z] = false;
	return true;
end

function SetBlockStatus(x,y,z,isBlocked)
	local dec = detected;
	if(dec[x] == nil) then dec[x] = {[y]={[z]=isBlocked}}; return; end
	local decx = dec[x];
	if(decx[y] == nil) then decx[y] = {[z]=isBlocked}; return; end
	local decxy = decx[y];
	decxy[z] = isBlocked;
	print(x..","..y..","..z.." b="..(isBlocked and "true" or "false"))
end

function GetBlockStatus(x,y,z)
	local decx = detected[x];
	if(decx == nil) then return false; end
	local decxy = decx[y];
	if(decxy == nil) then return false; end
	return decxy[z] or false;
end

Astar.block = Block;
Astar.clear = Clear;
Astar.setBlocked = SetBlockStatus;
Astar.isBlocked = GetBlockStatus;

function CountKeys(myTable)
	numItems = 0
	for k,v in pairs(myTable) do
		numItems = numItems + 1
	end
	return numItems;
end

function AddNewNode(x,y,z,dir,fromNode,routeData)
	local decx = detected[x];
	if(decx ~= nil) then
		local decxy = decx[y];
		if(decxy ~= nil and decxy[z]==true) then
			return false
		end
	end
	local node = nil;
	
	local visitedx = visited[x];
	local visitedxy = nil;
	local visitedxyz = nil;
	if(visitedx ~= nil) then
	visitedxy = visitedx[y];
	if(visitedxy ~= nil) then
	visitedxyz = visitedxy[z];
	if(visitedxyz ~= nil) then
	node = visitedxyz[dir];
	end end end
	
	if(node ~= nil) then
		if(node.open) then
			return false;
		end
		if(node.d <= fromNode.d)then
			return false;
		end
		local subNodes = backNodes[node.c + node.d];
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
		if(fromNode.d == nil)then fromNode.d = -1; end
		local start = routeData.start;
		node = {x=x,y=y,z=z,dir=dir,d=fromNode.d+1,c=CalculateDistance(start[1],start[2],start[3],x,y,z,dir), from =fromNode, to = {}, open = true};
		backNodes.count = backNodes.count + 1;
		if(visitedxyz ~= nil) then visitedxyz[dir] = node;
		else
			local dirpair = {nil,nil};
			dirpair[dir] = node;
			if(visitedxy ~= nil) then visitedxy[z] = dirpair;
			elseif(visitedx ~= nil) then visitedx[y] = {[z]=dirpair};
			else visited[x] = {y={[z]=dirpair}}; end
		end
	end
	if(fromNode.to == nil)then fromNode.to = {}; end
	local fromNodeTo = fromNode.to or ;
	fromNodeTo[#fromNodeTo+1] = node;
	if(backNodes[node.c + node.d]) then
		local nodeArr = backNodes[node.c + node.d];
		nodeArr[#nodeArr+1] = node;
	else
		backNodes[node.c + node.d] = {node};
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
	if(backNodes.min == nil or backNodes[backNodes.min]==nil)then
		local minVal = 9999999;
		for k,v in pairs(backNodes) do
			if(type(k) == "number" and k<minVal)then
				minVal = k;
			end
		end
		if(minVal>999999)then
			return false,"no backNodes";
		end
		backNodes.min = minVal;
	end
	local minArray = backNodes[backNodes.min];
	local popped = minArray[#minArray];
	minArray[#minArray] = nil;
	if(#minArray == 0)then
		backNodes[backNodes.min] = nil;
		backNodes.min = nil;
	end
	backNodes.count = backNodes.count -1;
	return popped;
end

local iter = 0;
function UpdateRoute(routePlanned)

	local maxNodes = routePlanned.maxNodes;
	local sx,sy,sz = unpack(routePlanned.start);
	
	local visitedx = visited[sx];
	local visitedxy = nil;
	local visitedxyz = nil;
	if(visitedx ~= nil) then
	visitedxy = visitedx[sy];
	if(visitedxy ~= nil) then
	visitedxyz = visitedxy[sz];
	end end
	
	if(visitedxyz[1]) then
		Astar.util.print("Destination Exists");
		routePlanned.path = visitedxyz[1];
		return routePlanned;
	end
	if(visitedxyz[0]) then
		Astar.util.print("Destination Exists");
		routePlanned.path = visitedxyz[0];
		return routePlanned;
	end
	while(true) do
		if(backNodes.count > maxNodes) then 
			Astar.util.print("Route too long");
			return false,"route too long"; 
		end
		if(iter>2000)then 
			iter = 0;
			print((backNodes.count +1).." backNodes, resting");
			coroutine.yield();
		end

		local node = PopNode();

		node.open = false;
		
		if(node.from.y ~= node.y-1)then
			AddNewNode(node.x,node.y-1,node.z,node.dir,node, routePlanned);
		end
		if(node.from.y ~= node.y+1)then
			AddNewNode(node.x,node.y+1,node.z,node.dir,node, routePlanned);
		end
		
		if(node.dir == 2) then
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
			local rotatedDir = 3-node.dir;
			AddNewNode(node.x,node.y,node.z,rotatedDir,node, routePlanned);
		end

		if(node.c == 0)then
			complete = true;
			local visitedNum = CountKeys(visited);
			Astar.util.print("Nodes: "..visitedNum-backNodes.count.."/"..visitedNum);
			Astar.util.print("Distance: "..node.d);
			routePlanned.path = node;
			return routePlanned;
		end
		if(backNodes.count == 0) then 
			Astar.util.print("Destination inaccessable");
			return false,"Destination inaccessable"; 
		end
	end
end

function CalculateRoute(sx,sy,sz,ex,ey,ez)
	Astar.util.print(sx,sy,sz,"to",ex,ey,ez);
	local routePlanned = {target = {ex,ey,ez},start={sx,sy,sz}};
	backNodes = {count = 0};
	AddNewNode(ex,ey,ez,2,{},routePlanned);
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
	for _,group in pairs(backNodes) do
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
	backNodes = newNodes;
end

function RemoveBranch(node,routeData,depth)
	if(node == nil) then return; end
	
	local visitedx = visited[node.x];
	local visitedxy = nil;
	local visitedxyz = nil;
	if(visitedx ~= nil) then
	visitedxy = visitedx[node.y];
	if(visitedxy ~= nil) then
	visitedxyz = visitedxy[node.z];
	if(visitedxyz ~= nil) then
	visitedxyz[node.dir]=nil;
	end end end
	
	if(#node.to == 0)then
		local nodeGroup = backNodes[node.d+node.c];
		for k,v in ipairs(nodeGroup) do
			if(v == node) then
				nodeGroup[k] = nodeGroup[#nodeGroup];
				if(#nodeGroup == 0)then
					backNodes[node.d+node.c] = nil;
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
	if(visitedx ~= nil) then
		local visitedxyp = visitedx[node.y+1];
		if(visitedxyp ~= nil) then
		local visitedxypz = visitedxyp[node.z];
		if(visitedxypz ~= nil) then
		local neighbour = visitedxypz[node.dir];
		if(neighbour ~= nil and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour;
			bestDistance = neighbour.d;
		end end end
		local visitedxym = visitedx[node.y-1];
		if(visitedxym ~= nil) then local visitedxymz = visitedxym[node.z];
		if(visitedxymz ~= nil) then 
		local neighbour = visitedxymz[node.dir];
		neighbour = visitedxymz[node.dir];
		if(neighbour ~= nil and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end end end
	end
	if(node.dir == 2) then
		local visitedxm = visited[node.x-1];
		if(visitedxm ~= nil) then local visitedxmy = visitedxm[node.y];
		if(visitedxmy ~= nil) then local visitedxmyz = visitedxmy[node.z];
		if(visitedxmyz ~= nil) then
		neighbour = visitedxmyz[node.dir];
		if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
		bestDistance = neighbour.d;
		end end end end
		local visitedxp = visited[node.x+1];
		if(visitedxp ~= nil) then local visitedxpy = visitedxp[node.y];
		if(visitedxpy ~= nil) then local visitedxpyz = visitedxpy[node.z];
		if(visitedxpyz ~= nil) then
		neighbour = visitedxpyz[node.dir];
		if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end end end end
	elseif(visitedxy ~= nil)
		local visitedxyzm = visitedxy[node.z-1];
		if(visitedxyzm ~= nil) then
		neighbour = visitedxyzm[node.dir];
		if(neighbour ~= nil and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end end
		local visitedxyzp = visitedxy[node.z+1];
		if(visitedxyzp ~= nil) then
		neighbour = visitedxyzp[node.dir];
		if(neighbour ~= nil and neighbour.d<bestDistance and #neighbour.to > 0) then
			bestNeighbour = neighbour
			bestDistance = neighbour.d;
		end end
	end
	if(visitedxyz ~= nil)
	neighbour = visitedxyz[3-node.dir];
	if(neighbour ~= undefined and neighbour.d<bestDistance and #neighbour.to > 0) then
		bestNeighbour = neighbour
	end
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
	Astar.move.setDir(2-curNode.dir);
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
			
			local rotatedNodeCode = nextNode.x..","..nextNode.y..","..nextNode.z..","..(3-nextNode.dir);		
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