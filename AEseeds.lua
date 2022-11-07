sleeptime=30
drop=false
docheck=function()
	turtle.select(1)
	for i=1,12 do
		turtle.suckDown(60)
	end
	for i=1,4 do
		turtle.select(i)
		numb=turtle.getItemCount()
		turtle.dropUp(numb-1)
	end
	turtle.select(5)
	if turtle.getItemCount()==0 then
		drop=false
	else
		for i=5,16 do
			turtle.select(i)
			turtle.dropDown()
		end
	end
end
while true do
	turtle.select(5)
	numb=turtle.getItemCount()
	if numb>0 then
		drop=true
		for i=5,16 do
			turtle.select(i)
			turtle.dropDown()
		end
	end
	while drop==true do
		redstone.setOutput("front",true)
		print('Growing')
		sleep(sleeptime)
		docheck()
	end
	redstone.setOutput("front",false)
	print('Sleeping')
	sleep(30)
	term.clear()
 end