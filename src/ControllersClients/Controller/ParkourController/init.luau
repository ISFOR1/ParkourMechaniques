local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ParkourController = Knit.CreateController({ Name = "ParkourController" })

local defaultWalkSpeed = 16
local sprintSpeed = 32
local player = Players.LocalPlayer
local humanoid
local hrp
local rayParams = RaycastParams.new()
-- Initial state
ParkourController.state = "Idle"
ParkourController.moveVector = Vector2.new(0, 0)

local isSprinting = false
local lastState = "Idle"

local function onHeartbeat(dt)
	if not humanoid or not hrp then
		return
	end

	local newState = "Idle"

	local humanoidState = humanoid:GetState()

	local localMoveDir = hrp.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

	local isMoving = localMoveDir.Magnitude > 0.1

	ParkourController.moveVector = Vector2.new(localMoveDir.X, localMoveDir.Z)

	if humanoidState == Enum.HumanoidStateType.Jumping then
		newState = "Jumping"
	elseif humanoidState == Enum.HumanoidStateType.Freefall then
		newState = "Falling"
	elseif humanoidState == Enum.HumanoidStateType.Landed then
		newState = "Landed"
	elseif humanoidState == Enum.HumanoidStateType.Running then
		if isMoving and isSprinting then
			newState = "Sprinting"
		elseif isMoving and not isSprinting then
			newState = "Walking"
		else
			newState = "Idle"
		end
	end

	if newState == "Landed" and lastState == "Landed" then
		newState = "Idle"
	end

	ParkourController.state = newState

	lastState = newState
end

local function handleInput(input, gameProcessed)
	if gameProcessed then
		return
	end

	if not humanoid then
		return
	end

	local inputType = input.UserInputType

	local inputState = input.UserInputState

	local keyCode = input.KeyCode

	if keyCode == Enum.KeyCode.LeftShift then
		if inputState == Enum.UserInputState.Begin then
			humanoid.WalkSpeed = sprintSpeed

			isSprinting = true
		elseif inputState == Enum.UserInputState.End then
			humanoid.WalkSpeed = defaultWalkSpeed

			isSprinting = false
		end
	elseif keyCode == Enum.KeyCode.Space and inputState == Enum.UserInputState.Begin then
		if

			ParkourController.state == "Idle"
			or ParkourController.state == "Walking"
			or ParkourController.state == "Sprinting"
		then
			humanoid.Jump = true
		end
	end
end

local function setupCharacter(char)
	humanoid = char:WaitForChild("Humanoid")

	hrp = char:WaitForChild("HumanoidRootPart")

	humanoid.AutoRotate = false

	humanoid.WalkSpeed = defaultWalkSpeed

	isSprinting = false

	ParkourController.state = "Idle"

	lastState = "Idle"

	ParkourController.moveVector = Vector2.new(0, 0)

	rayParams.FilterDescendantsInstances = { char }
end

function ParkourController:KnitStart()
	RunService.Heartbeat:Connect(onHeartbeat)

	UserInputService.InputBegan:Connect(handleInput)

	UserInputService.InputEnded:Connect(handleInput)

	player.CharacterAdded:Connect(setupCharacter)

	if player.Character then
		setupCharacter(player.Character)
	end
end

return ParkourController
