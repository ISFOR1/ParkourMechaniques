local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local FullBodyCameraController = Knit.CreateController({ Name = "FullBodyCameraController" })

local ParkourController

-- tiny lerp helper
local function lerp(a, b, t)
	return a + (b - a) * t
end

-- tweakables
local sensitivity = 0.2
local smoothness = 0.35
local maxPitch = 80
local cameraOffset = 0.5
local defaultFov = 70
local sprintFov = 100
local fovSmoothness = 0.05
local targetAngleX, targetAngleY = 0, 0
local currentAngleX, currentAngleY = 0, 0

-- bobbing vars
local func1, func2, func3, func4 = 0, 0, 0, 0
local val, val2 = 0, 0
local int, int2 = 5, 5

local player = Players.LocalPlayer
local m = player:GetMouse()
local camera = workspace.CurrentCamera

local function onRenderStep(deltaTime)
	-- scale dt so lerps feel consistent across framerates
	deltaTime = deltaTime * 30
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChild("Humanoid")

	if not head or not hrp or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	-- smooth pitch/yaw
	currentAngleX = currentAngleX + (targetAngleX - currentAngleX) * smoothness
	local dist = targetAngleY - currentAngleY
	dist = (dist > 180 and dist - 360) or (dist < -180 and dist + 360) or dist
	currentAngleY = (currentAngleY + dist * smoothness) % 360

	-- make body face camera yaw
	local bodyRotation = CFrame.Angles(0, math.rad(currentAngleY), 0)
	hrp.CFrame = CFrame.new(hrp.Position) * bodyRotation

	-- camera offset from head forward a bit
	local headPos = head.Position
	local cameraPos = headPos + (bodyRotation.LookVector * cameraOffset)
	local primaryCFrame = CFrame.new(cameraPos) * bodyRotation * CFrame.Angles(math.rad(currentAngleX), 0, 0)

	-- make only the head invisible locally so it doesn't clip
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = (part.Name == "Head") and 1 or 0
		end
	end

	-- movement stuff for bobbing and FOV
	local rootMagnitude = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
	local calcRootMagnitude = math.min(rootMagnitude, 25)
	local isSprinting = ParkourController and ParkourController.movementState == "Sprinting"
	local targetFov = isSprinting and sprintFov or defaultFov
	camera.FieldOfView = lerp(camera.FieldOfView, targetFov, fovSmoothness * deltaTime)

	-- reset bob when dt huge (lag)
	if deltaTime > 1.5 then
		func1, func2 = 0, 0
	else
		func1 = lerp(
			func1,
			math.cos(tick() * 0.5 * math.random(5, 7.5)) * (math.random(2.5, 10) / 100) * deltaTime,
			0.05 * deltaTime
		)
		func2 = lerp(
			func2,
			math.cos(tick() * 0.5 * math.random(2.5, 5)) * (math.random(1, 5) / 100) * deltaTime,
			0.05 * deltaTime
		)
	end

	-- leaning based on velocity in local space
	val2 = math.clamp(
		lerp(
			val2,
			-primaryCFrame:VectorToObjectSpace(hrp.Velocity / math.max(humanoid.WalkSpeed, 0.01)).X * 0.04,
			0.1 * deltaTime
		),
		-0.12,
		0.1
	)

	-- mouse tilt + periodic stuff
	func3 = lerp(func3, math.clamp(UserInputService:GetMouseDelta().X, -2.5, 2.5), 0.25 * deltaTime)
	func4 = lerp(func4, math.sin(tick() * int) / 5 * math.min(1, int2 / 10), 0.25 * deltaTime)

	-- vertical bob depends on speed
	if rootMagnitude > 1 then
		val = lerp(val, math.cos(tick() * 0.5 * math.floor(int)) * (int / 200), 0.25 * deltaTime)
	else
		val = lerp(val, 0, 0.05 * deltaTime)
	end

	-- speed thresholds for bob intensity
	if rootMagnitude > 6 then
		int, int2 = 10, 9
	elseif rootMagnitude > 0.1 then
		int, int2 = 6, 7
	else
		int2 = 0
	end

	-- build final bob CFrame
	local bobbingCFrame = CFrame.fromEulerAnglesXYZ(0, 0, math.rad(func3))
		* CFrame.fromEulerAnglesXYZ(math.rad(func4 * deltaTime), math.rad(val * deltaTime), val2)
		* CFrame.Angles(0, 0, math.rad(func4 * deltaTime * (calcRootMagnitude / 5)))
		* CFrame.fromEulerAnglesXYZ(math.rad(func1), math.rad(func2), math.rad(func2 * 10))

	camera.CFrame = primaryCFrame * bobbingCFrame
end

local function onInputChanged(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		-- invert Y, clamp pitch, yaw wraps
		targetAngleX = math.clamp(targetAngleX - delta.Y * sensitivity, -maxPitch, maxPitch)
		targetAngleY = (targetAngleY - delta.X * sensitivity) % 360
	end
end

local function setupCharacter(char)
	camera.FieldOfView = defaultFov
	targetAngleX, targetAngleY = 0, 0
	currentAngleX, currentAngleY = 0, 0
end

function FullBodyCameraController:KnitStart()
	ParkourController = Knit.GetController("ParkourController")
	m.Icon = "http://www.roblox.com/asset/?id=569021388"
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = true
	camera.CameraType = Enum.CameraType.Scriptable

	RunService.RenderStepped:Connect(function(dt)
		onRenderStep(dt)
	end)
	UserInputService.InputChanged:Connect(onInputChanged)

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end
end

return FullBodyCameraController
