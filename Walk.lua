-- Global var
_G.PlayerArrivedCar = false

-- Player
local Players = game:GetService("Players")
local player  = Players.LocalPlayer

-- Path Finding
local PathfindingService = game:GetService("PathfindingService")
local path = PathfindingService:CreatePath()

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local GOAL_REACHED = false
local WAIT_INTERVAL = .5
local DESTINATION_CAR = game.Workspace.Jeep.DriveSeat.Position
local DESTINATION_SCHOOL = game.Workspace.School.DrinkingFountain.Fountain.Position
local DESTINATION_PLAYGROUND_SWING = game.Workspace.Playground.SwingSet.Swing.Seat.Position

local showWaypointGUI = false

local function setDestination(dest) 
	destination = dest
end

local function walk(character, destination)
	print("Player walk without using ComputeAsync() API")
	-- if character:isA("Humanoid") then
	if character then
		character.Humanoid:MoveTo(destination)
		return true
	else
		return false
	end
end

local function teleport(character, destination)
	print("Player teleport without using MoveTo() API")
	local teleportPosition = destination
	if teleportPosition == nil then
		print("TeleportPosition is empty")
		return false
	else
		character:SetPrimaryPartCFrame(CFrame.new(teleportPosition))
		print("Teleport player to the destination")
		GOAL_REACHED = true	
		return true
	end
end

local function followPath(character, destination)
	-- Compute the path
	local success, errorMessage = pcall( function()
		path:ComputeAsync(character.PrimaryPart.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = path:GetWaypoints()
		if showWaypointGUI == true then
			-- Loop through waypoints (Display waypoints)
			for cnt, waypoint in pairs(waypoints) do
				local ball = Instance.new("Part")
				ball.Shape = "Ball"
				ball.Material = "Neon"
				ball.Size = Vector3.new(0.6, 0.6, 0.6)
				ball.Position = waypoint.Position
				ball.Anchored = true
				ball.CanCollide = false
				ball.Parent = game.Workspace
				-- Enum.PathWaypointAction values: Walk value 0, Jump value 1
				if waypoints[1].Action == Enum.PathWaypointAction.Jump then 
					print("Waypoints: " .. cnt .. ", Jump")
				end
				if waypoints[1].Action == Enum.PathWaypointAction.Walk then
					print("Waypoints: " .. cnt .. ", Walk")
				end
				cnt += 1
			end
		end
		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				followPath(character, destination)
			end
		end)
		-- Detect when movement to next waypoint is complete
		if reachedConnection ==  false then
			reachedConnection = character.Humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					character.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					print("GOAL_REACHED = true	")
					GOAL_REACHED = true	
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		character.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)

		-- Check Waypoints Jump Action
		if waypoints.Action == Enum.PathWaypointAction.Jump then
			character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	else
		warn("Path not computed!", errorMessage)
		if GOAL_REACHED == false then
			if teleport(character, destination) == false then
				print("Teleport not available")
			end
		end
		
		if GOAL_REACHED == false then
			if walk(character, destination) == false then
				print("Skip walking...")
			end
		end
	end
end

local function move(character, destination)
	if character then
		-- check character position
		local hRootPart = character:FindFirstChild("HumanoidRootPart")
		if hRootPart then
			local hPosition = hRootPart.Position
			-- print("Current player position " .. tostring(hPosition))
			-- 1. teleporting method
			-- character:SetPrimaryPartCFrame(CFrame.new(destination)) 

			-- 2. player runs to destination, but needs to jump to the drive seat
			-- character.Humanoid:MoveTo(destination) 

			-- 3. use path finding and comput path to avoid obstacles 
			followPath(character, destination)			
			return true
		end
	end
	return false
end

local function movePlayers(destination)
	if Players:GetPlayers() == nil then
		print("Players:GetPlayers() is not ready")
		return false
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if move(character, destination) then
			return true
		end
	end
	return false
end

local function PlayerWalk() 
	-- set destination
	setDestination(DESTINATION_CAR)
	while GOAL_REACHED == false do
		wait(WAIT_INTERVAL)
		if movePlayers(destination) then
			print("player walking")
		else
			warn("player not walking")
		end
	end
	_G.PlayerArrivedCar = true
	print("PlayerArrivedCar = " .. tostring(_G.PlayerArrivedCar))
end

-- start game
PlayerWalk()
