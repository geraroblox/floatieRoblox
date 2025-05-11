-- Script to control a Floatie with a Seat in Roblox
local floatie = script.Parent -- The Floatie model
local seat = floatie:WaitForChild("Seat") -- The Seat object

-- Set the PrimaryPart (choose one MeshPart as the central part)
local primaryPart = floatie:WaitForChild("MeshPart") -- Replace "MeshPart" with your actual MeshPart name
floatie.PrimaryPart = primaryPart

-- Weld all parts to the PrimaryPart to keep the Floatie together
local function weldParts()
	for _, part in pairs(floatie:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primaryPart then
			-- Check if a weld already exists to avoid duplicates
			local existingWeld = part:FindFirstChildOfClass("Weld")
			if not existingWeld then
				local weld = Instance.new("Weld")
				weld.Part0 = primaryPart
				weld.Part1 = part
				weld.C0 = primaryPart.CFrame:Inverse() * part.CFrame
				weld.Parent = primaryPart
			end
		end
	end
end
weldParts() -- Weld the parts together

-- Apply buoyancy to make the Floatie float on water
for _, part in pairs(floatie:GetDescendants()) do
	if part:IsA("BasePart") then
		local density = 0.5    -- Less dense than water (1.0) to float
		local friction = 0.3
		local elasticity = 0.5
		local properties = PhysicalProperties.new(density, friction, elasticity)
		part.CustomPhysicalProperties = properties
		part.Anchored = false -- Ensure parts can move
	end
end

-- Create BodyGyro to keep the Floatie upright
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(10000, 0, 10000) -- Resist rotation around X and Z axes, allow Y-axis rotation
bodyGyro.P = 1000 -- Power of the gyro (adjust if needed)
bodyGyro.Parent = primaryPart

-- Movement settings
local MAX_SPEED = 20    -- Speed in studs per second
local ACCELERATION = 10 -- How quickly it speeds up/slows down

-- Create BodyVelocity for horizontal movement
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(10000, 0, 10000) -- Force in X and Z directions
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Parent = primaryPart

-- Function to get the player’s movement direction
local function getMovementDirection(player)
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if not humanoid then return Vector3.new(0, 0, 0) end
	return humanoid.MoveDirection
end

-- Main control loop
while true do
	-- Update BodyGyro to keep the Floatie upright while allowing Y-axis rotation
	local lookVector = primaryPart.CFrame.LookVector
	local desiredLookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit -- Project LookVector onto XZ plane
	bodyGyro.CFrame = CFrame.new(primaryPart.Position, primaryPart.Position + desiredLookVector)

	if seat.Occupant then
		local player = game.Players:GetPlayerFromCharacter(seat.Occupant.Parent)
		if player then
			local direction = getMovementDirection(player)
			local targetVelocity = direction * MAX_SPEED
			-- Smoothly adjust velocity
			bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVelocity, ACCELERATION * wait())
		end
	else
		-- Stop movement when no one is seated
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	end
	wait(0.1) -- Small delay to reduce lag
end
