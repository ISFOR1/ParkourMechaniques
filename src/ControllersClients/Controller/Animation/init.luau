local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local AnimationsIds = require(script.AnimationsIds)

local AnimationController = Knit.CreateController({ Name = "AnimationController" })

-- State
local ParkourController
local humanoid, animator
local animations = {}
local currentLoop
local currentState = "Idle"
local isTransitioning = false
local lastJumpLead = "R"
local lastRunStopLead = "R"
local lastRunWalkLead = "R"
local idleStartTime = 0

-- Helper Functions
local function loadAnimations(animTable, targetAnimator)
	for category, anims in pairs(animTable) do
		if type(anims) == "table" then
			loadAnimations(anims, targetAnimator)
		else
			local animInstance = Instance.new("Animation")
			animInstance.AnimationId = anims
			animations[category] = targetAnimator:LoadAnimation(animInstance)
			animInstance:Destroy()
		end
	end
end

local function stopAllTracks(fadeTime, exceptTrack)
	if not animator then
		return
	end
	fadeTime = fadeTime or 0.1

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= exceptTrack then
			track:Stop(fadeTime)
		end
	end

	currentLoop = nil
end

local function playTransition(trackName, fadeTime)
	isTransitioning = true
	local track = animations[trackName]
	if not track then
		isTransitioning = false
		return
	end

	stopAllTracks(fadeTime, track)
	track.Looped = false
	track:Play(fadeTime)
	track.Ended:Once(function()
		isTransitioning = false
	end)
end

local function playLoop(trackName, fadeTime)
	local track = animations[trackName]
	if not track or (currentLoop == track and currentLoop.IsPlaying) then
		return
	end

	stopAllTracks(fadeTime, track)
	track.Looped = true
	track:Play(fadeTime)
	currentLoop = track
end

local function getMovementAnimation(moveVec, stateName)
	local angle = math.atan2(moveVec.X, moveVec.Y) * (180 / math.pi)

	if angle > -45 and angle < 45 then
		return stateName
	elseif angle > 45 and angle < 135 then
		return stateName .. "_Side_R"
	elseif angle < -45 and angle > -135 then
		return stateName .. "_Side_L"
	else
		return "Back_" .. stateName
	end
end

-- Animation Update Logic
local function updateCharacterAnimation(dt)
	if not humanoid or not animator or not ParkourController then
		return
	end

	local parkourState = ParkourController.state
	local moveVec = ParkourController.moveVector

	if isTransitioning and parkourState ~= "Jumping" and parkourState ~= "Falling" then
		return
	end

	local handled = false

	if parkourState == "Jumping" then
		handled = true
		if currentState ~= "Jumping" then
			currentState = "Jumping"
			local jumpAnim = (lastJumpLead == "R") and "Jump_L" or "Jump_R"
			lastJumpLead = (lastJumpLead == "R") and "L" or "R"
			local track = animations[jumpAnim]
			stopAllTracks(0.1, track)
			track.Looped = false
			track:Play(0.1)
		end
	elseif parkourState == "Falling" then
		handled = true
		if currentState ~= "Falling" then
			currentState = "Falling"
			local fallAnim = (lastJumpLead == "R") and "Fall_L" or "Fall_R"
			playLoop(fallAnim, 0.2)
		end
	elseif parkourState == "Landed" then
		handled = true
		if currentState ~= "Landed" then
			currentState = "Landed"
			local track = animations["Land"]
			if track then
				stopAllTracks(0.05, track)
				track.Looped = false
				track:Play(0.05)
			end
		end
	elseif parkourState == "Sprinting" then
		handled = true
		currentState = "Sprinting"
		playLoop(getMovementAnimation(moveVec, "Run"), 0.2)
		idleStartTime = 0
	elseif parkourState == "Walking" then
		handled = true
		if currentState == "Sprinting" then
			currentState = "RunToWalk"
			local walkAnim = (lastRunWalkLead == "R") and "RunToWalk_L" or "RunToWalk_R"
			lastRunWalkLead = (lastRunWalkLead == "R") and "L" or "R"
			playTransition(walkAnim, 0.1)
		else
			currentState = "Walking"
			playLoop(getMovementAnimation(moveVec, "Walk"), 0.2)
		end
		idleStartTime = 0
	elseif parkourState == "Idle" then
		if currentState == "Sprinting" or currentState == "RunToWalk" then
			handled = true
			currentState = "RunToStop"
			local stopAnim = (lastRunStopLead == "R") and "RunEnd_L" or "RunEnd_R"
			lastRunStopLead = (lastRunStopLead == "R") and "L" or "R"
			playTransition(stopAnim, 0.1)
		elseif currentState == "Idle" and idleStartTime > 0 and (tick() - idleStartTime > 60) then
			handled = true
			currentState = "IdleLong"
			idleStartTime = 0
			playTransition("IdleLong", 0.5)
		end
	end

	if not handled and not isTransitioning then
		if currentState ~= "Idle" then
			currentState = "Idle"
			playLoop("Idle", 0.3)
			idleStartTime = tick()
		elseif currentState == "Idle" and (not currentLoop or not currentLoop.IsPlaying) then
			playLoop("Idle", 0.3)
		end
	end
end

-- Setup
local function setupCharacter(char)
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	local animateScript = char:WaitForChild("Animate", 5)
	if animateScript then
		animateScript.Disabled = true
	end

	for _, track in pairs(animations) do
		track:Destroy()
	end

	table.clear(animations)
	currentLoop = nil
	currentState = "Idle"
	isTransitioning = false
	idleStartTime = 0

	loadAnimations(AnimationsIds, animator)
end

function AnimationController:KnitStart()
	ParkourController = Knit.GetController("ParkourController")
	Players.LocalPlayer.CharacterAdded:Connect(setupCharacter)

	if Players.LocalPlayer.Character then
		setupCharacter(Players.LocalPlayer.Character)
	end

	RunService.Heartbeat:Connect(updateCharacterAnimation)
end

return AnimationController
