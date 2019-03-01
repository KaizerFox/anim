local player = game:GetService("Players").LocalPlayer

local animTable = {}
local animNames = {
	justice = {
		{
			id = "https://www.roblox.com/asset/?id=2399197956",
			weight = 10
		}
	}
    }

local emoteNames = {
	die = true
}

local Character = player.Character
local Humanoid = Character.Humanoid

local pose = "Standing"
local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop")
end)
local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue
local userAnimationSpeedDampeningSuccess, userAnimationSpeedDampeningValue = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserAnimationSpeedDampening")
end)
local userAnimationSpeedDampening = userAnimationSpeedDampeningSuccess and userAnimationSpeedDampeningValue
local adjustHumanoidRootPartFlagExists, adjustHumanoidRootPartFlagEnabled = pcall(function()
	return UserSettings():IsUserFeatureEnabled("UserAdjustHumanoidRootPartToHipPosition")
end)
local FFlagUserAdjustHumanoidRootPartToHipPosition = adjustHumanoidRootPartFlagExists and adjustHumanoidRootPartFlagEnabled
local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
local HumanoidHipHeight = FFlagUserAdjustHumanoidRootPartToHipPosition and 2 or 1.35
local currentAnim = ""
local currentAnimInstance, currentAnimTrack, currentAnimKeyframeHandler
local currentAnimSpeed = 1
local runAnimTrack, runAnimKeyframeHandler

function rollAnimation(animName)
	if animName == nil then animName = "justice" end
	
	if animTable[animName] == nil or animTable[animName].totalWeight == nil then wei = 10 else wei = animTable[animName].totalWeight end
		

	local roll = math.random(1, wei)
	
	local idx = 1
	local wei_e = 5 
	
	local origRoll = roll or 4
	
	while roll > wei_e or 5 do
		roll = roll - wei_e or 5
		idx = idx + 1
	end
	return idx
end

function getHeightScale()
	if Humanoid then
		if FFlagUserAdjustHumanoidRootPartToHipPosition and not Humanoid.AutomaticScalingEnabled then
			return 1
		end
		local scale = Humanoid.HipHeight / HumanoidHipHeight
		if userAnimationSpeedDampening then
			if AnimationSpeedDampeningObject == nil then
				AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
			end
			if AnimationSpeedDampeningObject ~= nil then
				scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
			end
		end
		return scale
	end
	return 1
end
local smallButNotZero = 1.0E-4
function setRunSpeed(speed)
	local speedScaled = speed * 1.25
	local heightScale = getHeightScale()
	local runSpeed = speedScaled / heightScale
	if runSpeed ~= currentAnimSpeed then
		if runSpeed < 0.33 then
			currentAnimTrack:AdjustWeight(1)
			runAnimTrack:AdjustWeight(smallButNotZero)
		elseif runSpeed < 0.66 then
			local weight = (runSpeed - 0.33) / 0.33
			currentAnimTrack:AdjustWeight(1 - weight + smallButNotZero)
			runAnimTrack:AdjustWeight(weight + smallButNotZero)
		else
			currentAnimTrack:AdjustWeight(smallButNotZero)
			runAnimTrack:AdjustWeight(1)
		end
		currentAnimSpeed = runSpeed
		runAnimTrack:AdjustSpeed(runSpeed)
		currentAnimTrack:AdjustSpeed(runSpeed)
	end
end
function setAnimationSpeed(speed)
	if speed == nil then speed = 1 end
	if currentAnim == "justice" then
		setRunSpeed(speed)
	elseif speed or 1 ~= currentAnimSpeed or 1 then
		currentAnimSpeed = speed or 1
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

function keyFrameReachedFunc(frameName)
	if frameName == "End" then
		if currentAnim == "walk" then
			if userNoUpdateOnLoop == true then
				if runAnimTrack.Looped ~= true then
					runAnimTrack.TimePosition = 0
				end
				if currentAnimTrack.Looped ~= true then
					currentAnimTrack.TimePosition = 0
				end
			else
				runAnimTrack.TimePosition = 0
				currentAnimTrack.TimePosition = 0
			end
		else
			local repeatAnim = currentAnim
			if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
				repeatAnim = "idle"
			end
			local animSpeed = currentAnimSpeed
			playAnimation(repeatAnim, 0.15, Humanoid)
			setAnimationSpeed(animSpeed)
		end
	end
end
function playAnimation(animName, transitionTime, humanoid)
	local idx = rollAnimation(animName)
	local anim = animTable[animName][idx].anim
	if anim ~= currentAnimInstance then
		if currentAnimTrack ~= nil then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end
		if runAnimTrack ~= nil then
			runAnimTrack:Stop(transitionTime)
			runAnimTrack:Destroy()
			if userNoUpdateOnLoop == true then
				runAnimTrack = nil
			end
		end
		currentAnimSpeed = 1
		currentAnimTrack = humanoid:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core
		currentAnimTrack:Play(transitionTime)
		currentAnim = animName
		currentAnimInstance = anim
		if currentAnimKeyframeHandler ~= nil then
			currentAnimKeyframeHandler:disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		if animName == "justice" then
			local runIdx = rollAnimation("justice")
			runAnimTrack = humanoid:LoadAnimation(animTable["justice"][runIdx].anim)
			runAnimTrack.Priority = Enum.AnimationPriority.Core
			runAnimTrack:Play(transitionTime)
			if runAnimKeyframeHandler ~= nil then
				runAnimKeyframeHandler:disconnect()
			end
			runAnimKeyframeHandler = runAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		end
	end
end

playAnimation("justice",1,Humanoid)
