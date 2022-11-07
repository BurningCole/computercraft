print('Turtle farmer V1.3')
waitTime=30 -- time between finishing and starting again(s)
maxSeedsHeld=8
x=tonumber(arg[1]) or 14
y=tonumber(arg[2]) 
--  	  _________
-- 		 [         ]
-- 		 [         ]
-- 		y[         ]
-- 		 [         ]
-- 		#[_________]   #=Turtle, plants along x axis, planting area must have space around it
--            x
seeds=7
--Turtle inventory
--[1234] 0=keep empty
--[5678] 1=main seed(will fill empty rows)
--[0000] 2+= optional extra seeds (seeds must go to lowest value)
--[0000] the turtle will keep one of each seed placed inside
seedsOnRow={1,2,3,4,5,6,7,1,1,1,1,1} --seeds on each row add more values for a larger y

told = #seedsOnRow
if told < y then
 for s=1,(y - told) do
  table.insert(seedsOnRow, 1, 1)
 end
end
forward=function()
 while not turtle.forward() do
  sleep(2)
 end
end
doRow=function(count)
 for n=1,count do
  forward()
  local inspect, data = turtle.inspectDown()
  if inspect then
   if data.state.age==7 then
    turtle.digDown()
   end
  end
  numb=turtle.getItemCount()
  if numb > 1 then
   turtle.placeDown()
  end
  if numb > 60 then
   turtle.dropDown(numb-60)
  end
 end
end 
while true do
 for i=1,y do
  turtle.select(seedsOnRow[i])
  doRow(x)
  forward()
  turtle.turnRight()
  turtle.turnRight()
  doRow(x)
  forward()
  turtle.turnRight()
  forward()
  turtle.turnRight()
 end
 turtle.turnRight()
 for drop=1,seeds do
  turtle.select(drop)
  numb=turtle.getItemCount()
  if numb>maxSeedsHeld then
   turtle.dropDown(numb-maxSeedsHeld)
   end
  end
 for i=1,y do
  forward()
 end
 turtle.turnLeft()
 for drop=(seeds+1),16 do
  turtle.select(drop)
  turtle.dropDown()
 end
 sleep(waitTime)
end
