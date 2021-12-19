-- Car
local TweenService = game:GetService("TweenService")

local PathfindingService = game:GetService("PathfindingService")
local path = PathfindingService:CreatePath()
local usePathFindingService = true

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection
local destination

local GOAL_REACHED = false
local WAIT_INTERVAL = .5

local DESTINATION_CAR = game.Workspace.Jeep.DriveSeat.Position
local DESTINATION_SCHOOL = game.Workspace.School.DrinkingFountain.Fountain.Position
local DESTINATION_PLAYGROUND_SWING = game.Workspace.Playground.SwingSet.Swing.Seat.Position
local DESTINATION_GARAGE_DRIVEWAY = game.Workspace.GarageBuilding.Driveway.Position

local DELTA = 5
local DESTINATION_SIMPLE = Vector3.new(DESTINATION_CAR.X + DELTA, DESTINATION_CAR.Y + DELTA, DESTINATION_CAR.Z)

-- Variables for the car and destination, etc.
local jeepModel = game.Workspace.Jeep
-- local carprimary = game.Workspace.Jeep:GetBoundingBox()

local drive_cnt = 0

local function setDestination(dest) 
	destination = dest
end

local function teleportCar(model, destination)
	local teleportPosition2 = destination
	if teleportPosition2 == nil then
		print("TeleportPosition is empty")
		return false
	else
		model:SetPrimaryPartCFrame(CFrame.new(teleportPosition2))
		print("Teleport Car to the destination.")
		GOAL_REACHED = true	
		return true
	end
end

local function drivePath(model, destination)
	drive_cnt += 1
	-- Compute the path
	local success, errorMessage = pcall(function()
		local carPrimaryModel = model.PrimaryPart
		path:ComputeAsync(carPrimaryModel.Position, destination)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		local waypoints2 = path:GetWaypoints()

		-- Loop through waypoints (Display waypoints)
		for cnt, waypoint in pairs(waypoints2) do
			local ball = Instance.new("Part")
			ball.Shape = "Ball"
			ball.Material = "Neon"
			ball.Size = Vector3.new(0.6, 0.6, 0.6)
			ball.Position = waypoint.Position
			ball.Anchored = true
			ball.CanCollide = false
			ball.Parent = game.Workspace
			cnt += 1
		end

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				drivePath(model, destination)
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			-- TODO: check model
			reachedConnection = model.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					model:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					GOAL_REACHED = true	
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end

		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		model:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
		print("drive_cnt = " .. drive_cnt)

		if drive_cnt == 10 then
			-- Teleport Car if ComputeAsync() API not available
			if teleportCar(model, destination) == false then
				print("Teleport not available")
			end
		end
	end
end


function useCarModel_PrimaryPart(model, destination: CFrame, shouldDelete)
	if shouldDelete == nil then shouldDelete = true end
	local oldPrimary = model.PrimaryPart

	-- creates invisible bounding box as the primary part
	local box = Instance.new("Part", workspace)
	box.Transparency = 1
	box.Name = "modelBox"	
	box.CFrame, box.Size = model:GetBoundingBox()
	box.Parent = model
	model.PrimaryPart = box

	-- 1. Teleporting 
	-- model:SetPrimaryPartCFrame(destination)

	-- 2. PathFinding method
	drivePath(model, destination)

	-- deletes the invisible bounding box if u dont want it
	if shouldDelete then
		model.PrimaryPart = oldPrimary
		box:Destroy()
	end
end

local function useTweenService(model, destination)

	local oldPrimary = model.PrimaryPart

	while not GOAL_REACHED do

		--creates invisible bounding box as the primary part
		local box = Instance.new("Part", workspace)
		box.Transparency = 1
		box.Name = "modelBox"	
		box.CFrame, box.Size = jeepModel:GetBoundingBox()
		box.Parent = jeepModel

		jeepModel.PrimaryPart = box

		local shouldDeleteBox = true

		-- Compute the path
		local success, errorMessage = pcall(function()
			path:ComputeAsync(jeepModel.PrimaryPart.Position, destination)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			-- Get the path waypoints
			local waypoints3 = path:GetWaypoints()

			-- Loop through waypoints (Display waypoints)
			for cnt3, waypoint3 in pairs(waypoints3) do
				local part = Instance.new("Part")
				part.Shape = "Ball"
				part.Material = "Neon"
				part.Size = Vector3.new(0.6, 0.6, 0.6)
				part.Position = waypoint3.Position
				part.Anchored = true
				part.CanCollide = false
				part.Parent = game.Workspace

				local tween = TweenService:Create(jeepModel.PrimaryPart, TweenInfo.new(1), {
					Position3 = Vector3.new(waypoint3.Position)})

				tween:Play()
				-- wait(1)
				cnt3 += 1
			end

			-- Detect if path becomes blocked
			blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
				-- Check if the obstacle is further down the path
				if blockedWaypointIndex >= nextWaypointIndex then
					-- Stop detecting path blockage until path is re-computed
					blockedConnection:Disconnect()
					-- Call function to re-compute new path
					return false
				end
			end)

			-- Detect when movement to next waypoint is complete
			if not reachedConnection then
				reachedConnection = jeepModel.PrimaryPart.MoveToFinished:Connect(function(reached)
					if reached and nextWaypointIndex < #waypoints3 then
						-- Increase waypoint index and move to next waypoint
						nextWaypointIndex += 1
						jeepModel.PrimaryPart:MoveTo(waypoints3[nextWaypointIndex].Position)
					else
						GOAL_REACHED = true	
						reachedConnection:Disconnect()
						blockedConnection:Disconnect()
						return true
					end
				end)
			end

			-- Initially move to second waypoint (first waypoint is path start; skip it)
			nextWaypointIndex = 2
			jeepModel.PrimaryPart:MoveTo(waypoints3[nextWaypointIndex].Position)

		else
			warn("Path not computed!", errorMessage)
			return false
		end

		--deletes the invisible bounding box if u dont want it
		if GOAL_REACHED then
			if shouldDeleteBox then
				jeepModel.PrimaryPart = oldPrimary
				box:Destroy()
			end
		end 
	end
end

local function CarMove() 
	local car_moved = false
	-- set destination
	setDestination(DESTINATION_SIMPLE)
	while not GOAL_REACHED do
		
		print("3. PlayerArrivedCar = " .. tostring(_G.PlayerArrivedCar))

		if _G.PlayerArrivedCar then
			print("Player ready to drive the car.")

			wait(WAIT_INTERVAL)
			if useTweenService(jeepModel, destination) then
				print("Car moving")
				car_moved = true
			else
				print("Car not moving")
				car_moved = false
			end

			-- if usePathFindingService then
			if not car_moved then
				print("Car moving using Path Finding")
				useCarModel_PrimaryPart(jeepModel, destination)
			end
		else
			print("Car is ready, waiting for the player.")
		end
	end
end

-- start game
CarMove()


