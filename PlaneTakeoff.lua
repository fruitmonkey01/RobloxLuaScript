--	This script was specially coded for the Plane Kit plane. It will not work with any other plane system

-- DO NOT EDIT ANYTHING HERE (unless you are willing to risk the plane breaking)

-- MainParts_MainSeat_Plane_Main2.lua

wait(0.1)	-- Yes, this is needed. If it's not here, the plane will only work once.

-- Welcome to the variable museum:
-- local player = script.Parent.Parent.Parent

local player = game.Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui") -- ref: Line 256

local plane,mainParts,info,main,move,gryo,seat,landingGear,accel,canCrash,crashForce,crashSpin,crashVisual,maxBank,maxSpeed,speedVary,stallSpeed,throttleInc,altRestrict,altMin,altMax,altSet
local desiredSpeed,currentSpeed,realSpeed = 0,0,0
local mouseSave
local gearParts = {}
local selected,flying,on,dead,gear,throttle = false,false,false,false,true,0
local gui = script.Parent.PlaneGui:clone()
local panel = gui.Panel
local lowestPoint = 0
local A = math.abs	-- Creating a shortcut for the function

local keys = {
	engine={key};
	landing={key};
	spdup={byte=0;down=false};
	spddwn={byte=0;down=false};
}

function waitFor(parent,array)	-- Backup system to wait for objects to 'load'
	if (array) then
		for _,name in pairs(array) do
			while (not parent:findFirstChild(name)) do wait() end	-- If the object is found right away, no time will be spent waiting. That's why 'while' loops work better than 'repeat' in this case
		end
	elseif (parent:IsA("ObjectValue")) then
		while (not parent.Value) do wait() end
	end
end

function fixVars()	-- Correct your mistakes to make sure the plane still flies correctly!
	maxBank = (maxBank < -90 and -90 or maxBank > 90 and 90 or maxBank)
	throttleInc = (throttleInc < 0.01 and 0.01 or throttleInc > 1 and 1 or throttleInc)
	stallSpeed = (stallSpeed > maxSpeed and maxSpeed or stallSpeed)
	accel = (accel < 0.01 and 0.01 or accel > maxSpeed and maxSpeed or accel)
	altMax = ((altMax-100) < altMin and (altMin+100) or altMax)
	altMax = (altSet and (altMax+main.Position.y) or altMax)
	altMin = (altSet and (altMin+main.Position.y) or altMin)
	-- key bindings
	keys.engine.key = (keys.engine.key == "" and "e" or keys.engine.key) -- "t" for taking off
	keys.landing.key = (keys.landing.key == "" and "g" or keys.landing.key)
	keys.spdup.byte = (keys.spdup.byte == 0 and 17 or keys.spdup.byte)
	keys.spddwn.byte = (keys.spddwn.byte == 0 and 18 or keys.spddwn.byte)
end

function getVars()	-- Since this plane kit is supposed to make you avoid scripting altogether, I have to go the extra mile and write a messy function to account for all those object variables
	plane = script.Parent.Plane.Value
	waitFor(plane,{"MainParts","OtherParts","EDIT_THESE","Dead"})
	mainParts,info = plane.MainParts,plane.EDIT_THESE
	waitFor(mainParts,{"Main","MainSeat","LandingGear"})
	main,seat,landingGear = mainParts.Main,mainParts.MainSeat,mainParts.LandingGear
	waitFor(main,{"Move","Gyro"})
	move,gyro = main.Move,main.Gyro
	accel,canCrash,crashForce,crashSpin,crashVisual,maxBank,maxSpeed,speedVary,stallSpeed,throttleInc,altRestrict,altMin,altMax,altSet =	-- Quickest way to assign tons of variables
		A(info.Acceleration.Value),info.CanCrash.Value,A(info.CanCrash.Force.Value),info.CanCrash.SpinSpeed.Value,info.CanCrash.VisualFX.Value,
		info.MaxBank.Value,A(info.MaxSpeed.Value),A(info.SpeedDifferential.Value),A(info.StallSpeed.Value),A(info.ThrottleIncrease.Value),
		info.AltitudeRestrictions.Value,info.AltitudeRestrictions.MinAltitude.Value,info.AltitudeRestrictions.MaxAltitude.Value,info.AltitudeRestrictions.SetByOrigin.Value
	keys.engine.key = info.Hotkeys.Engine.Value:gmatch("%a")():lower()
	keys.landing.key = info.Hotkeys.LandingGear.Value:gmatch("%a")():lower()
	local sU,sD = info.Hotkeys.SpeedUp.Value:lower(),info.Hotkeys.SpeedDown.Value:lower()
	keys.spdup.byte = (sU == "arrowkeyup" and 17 or sU == "arrowkeydown" and 18 or sU:gmatch("%a")():byte())	-- Ternary operations use logical figures to avoid 'if' statements
	keys.spddwn.byte = (sD == "arrowkeyup" and 17 or sD == "arrowkeydown" and 18 or sD:gmatch("%a")():byte())
	fixVars()
	plane.Dead.Changed:connect(function()
		print("Warning: Plane won't crash in the game")
		--[[
		-- Plane won't crash in the game
		if ((plane.Dead.Value) and (not dead)) then
			dead,flying,on = true,false,false
			main.Fire.Enabled,main.Smoke.Enabled = info.CanCrash.VisualFX.Value,info.CanCrash.VisualFX.Value
			move.maxForce = Vector3.new(0,0,0)
			gyro.D = 1e3
			while ((selected) and (not plane.Dead.Stop.Value)) do
				gyro.cframe = (gyro.cframe*CFrame.Angles(0,0,math.rad(crashSpin)))
				wait()
			end
			print()
		end
		]]
	end)
end

function getGear(parent)	-- Very common way to scan through every descendant of a model:
	for _,v in pairs(parent:GetChildren()) do
		if (v:IsA("BasePart")) then
			local t,r,c = Instance.new("NumberValue",v),Instance.new("NumberValue",v),Instance.new("BoolValue",v)	-- Saving original properties
			t.Name,r.Name,c.Name = "Trans","Ref","Collide"
			t.Value,r.Value,c.Value = v.Transparency,v.Reflectance,v.CanCollide
			table.insert(gearParts,v)
		end
		getGear(v)
	end
end

function getLowestPoint()	-- Plane will use LowestPoint to determine where to look to make sure the plane is either flying or on the ground
	if (#gearParts == 0) then
		lowestPoint = (main.Position.y+5+(main.Size.y/2))
		return
	end
	for _,v in pairs(gearParts) do	-- Not very efficient, but it basically does what I designed it to do:
		local _0 = (main.Position.y-(v.CFrame*CFrame.new((v.Size.x/2),0,0)).y)
		local _1 = (main.Position.y-(v.CFrame*CFrame.new(-(v.Size.x/2),0,0)).y)
		local _2 = (main.Position.y-(v.CFrame*CFrame.new(0,(v.Size.y/2),0)).y)
		local _3 = (main.Position.y-(v.CFrame*CFrame.new(0,-(v.Size.y/2),0)).y)
		local _4 = (main.Position.y-(v.CFrame*CFrame.new(0,0,(v.Size.z/2))).y)
		local _5 = (main.Position.y-(v.CFrame*CFrame.new(0,0,-(v.Size.z/2))).y)
		local n = (math.max(_0,_1,_2,_3,_4,_5)+5)
		lowestPoint = (n > lowestPoint and n or lowestPoint)
	end
end

function guiSetup()	-- Setting up the GUI buttons and such
	local cur = 0
	panel.Controls.Position = UDim2.new(0,-8,0,-(panel.Controls.AbsolutePosition.y+panel.Controls.AbsoluteSize.y))
	panel.ControlsButton.MouseButton1Click:connect(function()
		cur = (cur == 0 and 1 or 0)
		if (cur == 0) then
			panel.Controls:TweenPosition(UDim2.new(0,-8,0,-(panel.Controls.AbsolutePosition.y+panel.Controls.AbsoluteSize.y)),"In","Sine",0.35)
		else
			panel.Controls.Visible = true
			panel.Controls:TweenPosition(UDim2.new(0,-8,1,32),"Out","Back",0.5)
		end
	end)
	panel.Controls.c1.Value.Text = (keys.engine.key:upper() .. " Key")
	panel.Controls.c4.Value.Text = (keys.landing.key:upper() .. " Key")
	panel.Controls.c2.Value.Text = (keys.spdup.byte == 17 and "UP Arrow Key" or keys.spdup.byte == 18 and "DOWN Arrow Key" or (string.char(keys.spdup.byte):upper() .. " Key"))
	panel.Controls.c3.Value.Text = (keys.spddwn.byte == 17 and "UP Arrow Key" or keys.spddwn.byte == 18 and "DOWN Arrow Key" or (string.char(keys.spddwn.byte):upper() .. " Key"))
end

function changeGear()
	gear = (not gear)
	for _,v in pairs(gearParts) do
		v.Transparency,v.Reflectance,v.CanCollide = (gear and v.Trans.Value or 1),(gear and v.Ref.Value or 0),(gear and v.Collide.Value or false)	-- Learning how to code like this is extremely useful
	end
end

function updateGui(taxiing,stalling)
	panel.Title.Text = info.PlaneName.Value
	panel.Off.Visible = (not on)
	panel.Taxi.Visible,panel.Stall.Visible = taxiing,(not taxiing and stalling)
	if ((realSpeed > -10000) and (realSpeed < 10000)) then
		panel.Speed.Value.Text = tostring(math.floor(realSpeed+0.5))
	end
	panel.Altitude.Value.Text = tostring(math.floor(main.Position.y+0.5))
	panel.Throttle.Bar.Amount.Size = UDim2.new(throttle,0,1,0)
end

function taxi()	-- Check to see if the plane is on the ground or not
	return (currentSpeed <= stallSpeed and game.Workspace:findPartOnRay(Ray.new(main.Position,Vector3.new(0,-lowestPoint,0)),plane))	-- Make sure plane is on a surface
end

function stall()	-- Originally set as a giant ternary operation, but got WAY too complex, so I decided to break it down for my own sanity
	if ((altRestrict) and (main.Position.y > altMax)) then return true end
	local diff = ((realSpeed-stallSpeed)/200)
	diff = (diff > 0.9 and 0.9 or diff)
	local check = {	-- Table placed here so I could easily add new 'checks' at ease. If anything in this table is 'true,' then the plane will be considered to be taxiing
		(currentSpeed <= stallSpeed);
		(main.CFrame.lookVector.y > (realSpeed < stallSpeed and -1 or -diff));
	}
	for _,c in pairs(check) do
		if (not c) then return false end
	end
	return true
end

function fly(m)	-- Main function that controls all of the flying stuff. Very messy.
	flying = true
	local pos,t = main.Position,time()
	local lastStall = false
	-- while ((flying) and (not dead)) do -- NG
	while (flying) do
		realSpeed = ((pos-main.Position).magnitude/(time()-t))	-- Calculate "real" speed
		pos,t = main.Position,time()
		local max = (maxSpeed+(-main.CFrame.lookVector.y*speedVary))	-- Speed variety based on the pitch of the aircraft
		desiredSpeed = (max*(on and throttle or 0))	-- Find speed based on throttle
		local change = (desiredSpeed > currentSpeed and 1 or -1)	-- Decide between accelerating or decelerating
		currentSpeed = (currentSpeed+(accel*change))	-- Calculate new speed
--		local throttleNeeded = 
		local stallLine = ((stallSpeed/math.floor(currentSpeed+0.5))*(stallSpeed/max))
		stallLine = (stallLine > 1 and 1 or stallLine)
		panel.Throttle.Bar.StallLine.Position = UDim2.new(stallLine,0,0,0)
		panel.Throttle.Bar.StallLine.BackgroundColor3 = (stallLine > panel.Throttle.Bar.Amount.Size.X.Scale and Color3.new(1,0,0) or Color3.new(0,0,0))
		if (change == 1) then
			currentSpeed = (currentSpeed > desiredSpeed and desiredSpeed or currentSpeed)	-- Reduce "glitchy" speed
		else
			currentSpeed = (currentSpeed < desiredSpeed and desiredSpeed or currentSpeed)
		end
		local tax,stl = taxi(),stall()
		if ((lastStall) and (not stl) and (not tax)) then	-- Recovering from a stall:
			if ((realSpeed > -10000) and (realSpeed < 10000)) then
				currentSpeed = realSpeed
			else
				currentSpeed = (stallSpeed+1)
			end
		end
		lastStall = stl
		move.velocity = (main.CFrame.lookVector*currentSpeed)		-- Set speed to aircraft
		local bank = ((((m.ViewSizeX/2)-m.X)/(m.ViewSizeX/2))*maxBank)	-- My special equation to calculate the banking of the plane. It's pretty simple actually
		bank = (bank < -maxBank and -maxBank or bank > maxBank and maxBank or bank)
		if (tax) then
			if (currentSpeed < 2) then	-- Stop plane from moving/turning when idled on ground
				move.maxForce = Vector3.new(0,0,0)
				gyro.maxTorque = Vector3.new(0,0,0)
			else
				move.maxForce = Vector3.new(math.huge,0,math.huge)	-- Taxi
				gyro.maxTorque = Vector3.new(0,math.huge,0)
				gyro.cframe = CFrame.new(main.Position,m.Hit.p)
			end
		elseif (stl) then
			move.maxForce = Vector3.new(0,0,0)	-- Stall
			gyro.maxTorque = Vector3.new(math.huge,math.huge,math.huge)
			gyro.cframe = (m.Hit*CFrame.Angles(0,0,math.rad(bank)))
		else
			move.maxForce = Vector3.new(math.huge,math.huge,math.huge)	-- Fly
			gyro.maxTorque = Vector3.new(math.huge,math.huge,math.huge)
			gyro.cframe = (m.Hit*CFrame.Angles(0,0,math.rad(bank)))
		end
		if ((altRestrict) and (main.Position.y < altMin)) then	
			-- If you have altitude restrictions and are below the minimun altitude, send warning message
			-- plane.AutoCrash.Value = true -- NG
			print("Warning: altitude too low!")
		end
		updateGui(tax,stl)	-- Keep the pilot informed!
		main.Throttle.Value = throttle 
		wait()
	end
end

-- main function for taking off the plane
function takeOff() 
	waitFor(script.Parent,{"Plane","Deselect0","Deselect1","CurrentSelect"})
	waitFor(script.Parent.Plane)
	getVars()
	getGear(landingGear)
	getLowestPoint()

	guiSetup()
	if (script.Parent.Active) then
		script.Parent.Name = "RESELECT"
		while (script.Parent.Active) do wait() end
	end
	script.Parent.Name = "Plane"
	
	-- Todo: 
	-- 1. Move the Airplane from starting line (one end) of the runway
	-- 2. Wait for the pilot to arrive the MainSeat
	-- 3. Check lights turned on
	-- 4. Increase the throttle value and speed when the airplne is on the ground
	-- 5. Increase the altitude of the airplane and change the landing gear before taking off
	-- 6. Complete the above simplified procedure before the plane reaching the end of the runway
	

end

-- test here
takeOff() 



-- MainParts_MainSeat_Plane_Main.lua
script.Parent.Selected:connect(function(m)	-- Initial setup
	selected,script.Parent.CurrentSelect.Value = true,true
	mouseSave = m
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Attach
	m.Icon = "http://www.roblox.com/asset/?id=48801855"	-- Mouse icon used in Perilous Skies
	gui.Parent = player.PlayerGui
	
	print("Preparing for the plane to take off")
	
	delay(0,function() fly(m) end)	-- Basically a coroutine
	m.KeyDown:connect(function(k)
		if (not flying) then 
			print("Not flying")
			return 
		end
		k = k:lower()
		if (k == keys.engine.key) then
			on = (not on)
			main.On.Value = true 
			if (not on) then throttle = 0 
			main.On.Value = false
			end
		elseif (k == keys.landing.key) then
			changeGear()
		elseif (k:byte() == keys.spdup.byte) then
			keys.spdup.down = true
			delay(0,function()
				while ((keys.spdup.down) and (on) and (flying)) do
					throttle = (throttle+throttleInc)
					throttle = (throttle > 1 and 1 or throttle)
					wait()
				end
			end)
		elseif (k:byte() == keys.spddwn.byte) then
			keys.spddwn.down = true
			delay(0,function()
				while ((keys.spddwn.down) and (on) and (flying)) do
					throttle = (throttle-throttleInc)
					throttle = (throttle < 0 and 0 or throttle)
					wait()
				end
			end)
		end
	end)
	m.KeyUp:connect(function(k)
		if (k:byte() == keys.spdup.byte) then
			keys.spdup.down = false
		elseif (k:byte() == keys.spddwn.byte) then
			keys.spddwn.down = false
		end
	end)
end)

function deselected(forced)
	selected,script.Parent.CurrentSelect.Value = false,false
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	gui.Parent = nil
	flying = false
	pcall(function()
		move.maxForce = Vector3.new(0,0,0)
		if (taxi()) then
			gyro.maxTorque = Vector3.new(0,0,0)
		else
			-- plane.Dead.Value = true
			print("Warning: airplane not selected!")
		end
	end)
	if (forced) then
		if (mouseSave) then
			mouseSave.Icon = "rbxasset://textures\\ArrowCursor.png"	-- If you remove a tool without the actual deselect event, the icon will not go back to normal. This helps simulate it at the least
			wait()
		end
		script.Parent.Deselect1.Value = true	-- When this is triggered, the Handling script knows it is safe to remove the tool from the player
	end
end

-- MainParts_MainSeat_Plane_Main.lua
script.Parent.Deselected:connect(deselected)
script.Parent.Deselect0.Changed:connect(function()	-- When you get out of the seat while the tool is selected, Deselect0 is triggered to True
	if (script.Parent.Deselect0.Value) then
		deselected(true)
	end
end)







