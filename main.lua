getgenv().Croowz = {
    ["Keybinds"] = {
        ['CombatKeyBind'] = "C",
        ['MacroKeyBind'] = "X",
        ['AutoBuyKeybind'] = "Z"
    },
    ["Combat"] = { -- AimBot
        ['Enabled'] = true,
        ['Prediction'] = 0.125241,
        ['Smoothness'] = 0.5,
        ['HitPart'] = "HumanoidRootPart",
        ["Shake"] = {
            ["Enabled"] = false,
            ['ShakeValue'] = 1, -- SHAKE (USES X,Y,Z)
        },
    },
    ["Silent"] = {
        ["Enabled"] = true,
        ['HitPart'] = "Head",
        ['Predict'] = true,
        ['Prediction'] = 0.125241,
        ['NearestPart'] = false,
        ["FieldOfView"] = {
            ["Visible"] = true,
            ['Thickness'] = 1,
            ['Color'] = Color3.new(255, 255, 255),
            ['Size'] = 35
        },
    },
    ["GlobalChecks"] = {
        ["WallCheck"] = true,
        ["KnockedChecks"] = true
    },
    ["MouseTeleportation"] = {
        ["Enabled"] = true,
        ['Part'] = "false",
        ['Smothness'] = 1
    },
    ["Macro"] = {
        ["Enabled"] = true,
        ['Type'] = "Electron", -- ['Electron']
    },
    ["AutoBuyArea"] = {
        ['Distance'] = 10,
    },
    ["Miscellaneous"] = {
        ["UpdateNotification"] = true,
    },
}
if getgenv().Loaded == true then
	if Croowz.Miscellaneous.UpdateNotification == true then
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Config Updated Cuh",
			Text = "Updated Script Settings.",
			Duration = 0.0000001,
		})
	end
	return
end

for _, v in ipairs(getconnections(game:GetService("LogService").MessageOut)) do
    pcall(function()
        v:Disable()
    end)
end

local nigger = game:GetService("ReplicatedStorage")
if nigger:FindFirstChild("OpenAC Replicated Folder") then
    pcall(function()
        nigger["OpenAC Replicated Folder"]:Destroy()
    end)
end



task.wait(2.5)

print("Bypass Loaded Successfully")

local players = game:GetService("Players")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

local isLocking, targetPlayer = false, nil
local Prey = nil -- For silent Combat targeting

-- Generate random shake offset for Combat shake effect
local function getShakeOffset()
    local shakeAmount = Croowz.Combat.Shake.ShakeValue
    local offset = Vector3.new(
        math.random(-shakeAmount, shakeAmount) / 1,
        math.random(-shakeAmount, shakeAmount) / 1,
        math.random(-shakeAmount, shakeAmount) / 1
    )
    return offset
end

local function isPlayerAlive(player)
    local character = player.Character
    return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end

local function getClosestPlayerToCursor(radius)
    local shortestDistance = radius
    local closestPlayer = nil
    local mousePosition = inputService:GetMouseLocation()
    local part = Croowz.Combat.HitPart

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer and isPlayerAlive(player) then
            local character = player.Character
            local targetPart = character:FindFirstChild(part)
            if targetPart then
                local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude

                if distance < shortestDistance and onScreen then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Update the FOV Circle for silent Combat targeting
local Circle = Drawing.new("Circle")
Circle.Color = Croowz.Silent.FieldOfView.Color
Circle.Thickness = Croowz.Silent.FieldOfView.Thickness

local function UpdateFOV()
    if not Circle then return end
    local silentFOV = Croowz.Silent.FieldOfView
    Circle.Visible = silentFOV.Visible
    Circle.Radius = silentFOV.Size * 3
    Circle.Position = Vector2.new(mouse.X, mouse.Y + (game:GetService("GuiService"):GetGuiInset().Y))
    return Circle
end

runService.Heartbeat:Connect(UpdateFOV)

local function GetClosestBodyPart(character)
    local ClosestPart = nil
    local ClosestDistance = math.huge
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Parent == character then
            local screenPos = camera:WorldToScreenPoint(part.Position)
            local distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if distance < ClosestDistance then
                ClosestDistance = distance
                ClosestPart = part
            end
        end
    end
    return ClosestPart
end

-- Mouse Teleportation
runService.Heartbeat:Connect(function(deltaTime)
    if isLocking and targetPlayer and targetPlayer.Character then
        local character = targetPlayer.Character
        local humanoid = character:FindFirstChild("Humanoid")

        if humanoid then
            -- Check if the target is jumping or in freefall
            local isJumpingOrFalling = humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping

            -- Use Mouse Teleportation if enabled and the target is jumping or in freefall
            if Croowz.MouseTeleportation.Enabled and isJumpingOrFalling then
                local MouseTeleportationPart = character:FindFirstChild(Croowz.MouseTeleportation.Part)
                if MouseTeleportationPart then
                    local alpha = Croowz.MouseTeleportation.Smothness
                    local goalCFrame = CFrame.new(camera.CFrame.Position, MouseTeleportationPart.Position)
                    camera.CFrame = camera.CFrame:Lerp(goalCFrame, alpha)
                end
            end
        end
    end
end)

-- Function to lock Combat on the closest player
runService.Heartbeat:Connect(function()
    if isLocking and targetPlayer and targetPlayer.Character then
        local character = targetPlayer.Character
        local targetPart = character:FindFirstChild(Croowz.Combat.HitPart)
        if targetPart then
            local goalPosition = targetPart.Position + targetPart.Velocity * Croowz.Combat.Prediction

            -- Apply shake if enabled
            if Croowz.Combat.Shake.Enabled then
                goalPosition = goalPosition + getShakeOffset()
            end

            local goal = CFrame.new(camera.CFrame.Position, goalPosition)
            camera.CFrame = camera.CFrame:Lerp(goal, Croowz.Combat.Smoothness)
        end
    end
end)

-- Toggle Combat with keybind
inputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode[Croowz.Keybinds.CombatKeyBind] then
        isLocking = not isLocking
        targetPlayer = isLocking and getClosestPlayerToCursor(math.huge) or nil
    end
end)

-- Silent Combat targeting logic
local grmt = getrawmetatable(game)
local backupindex = grmt.__index
setreadonly(grmt, false)

grmt.__index = newcclosure(function(self, v)
    if (Croowz.Silent.Enabled and mouse and tostring(v) == "Hit") then
        if Prey and Prey.Character then
            local targetPart = Croowz.Silent.HitPart
            -- If NearestPart is enabled, dynamically target the nearest part
            if Croowz.Silent.NearestPart then
                local closestPart = GetClosestBodyPart(Prey.Character)
                if closestPart then
                    targetPart = closestPart.Name
                end
            end

            local endpoint = Prey.Character[targetPart].CFrame
            if Croowz.Silent.Predict then
                endpoint = endpoint + (Prey.Character[targetPart].Velocity * Croowz.Silent.Prediction)
            end
            return endpoint
        end
    end
    return backupindex(self, v)
end)

runService.Heartbeat:Connect(function()
    if Croowz.Silent.Enabled and Prey and Prey.Character then
        pcall(function()
            local TargetVel = Prey.Character[Croowz.Silent.HitPart]
            TargetVel.Velocity = Vector3.new(0, 0, 0)
            TargetVel.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        if Croowz.Silent.Enabled then
            Prey = getClosestPlayerToCursor(Croowz.Silent.FieldOfView.Size * 3) -- Using FOV size for radius
        end
    end
end)

local speedGlitching = false
local virtualInputManager = game:GetService("VirtualInputManager")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local function twait(milliseconds)
    local targetTime = milliseconds / 1000
    local startTime = tick()
    repeat
        runService.Heartbeat:Wait()
    until tick() - startTime >= targetTime
end

local function getEnumKeyCode(keyBind)
    return Enum.KeyCode[string.upper(keyBind)]
end

userInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end

    if input.KeyCode == getEnumKeyCode(Croowz.Keybinds.MacroKeyBind) and Croowz.Macro.Enabled then
        speedGlitching = not speedGlitching

        if speedGlitching then
            local waittime = 0.1
            local selectedMacroType = Croowz.Macro.Type

            if selectedMacroType == "Electron" then
                spawn(function()
                    repeat
                        runService.Heartbeat:Wait()
                        keypress(0x49)  -- Key 'I'
                        runService.Heartbeat:Wait()
                        keypress(0x4F)  -- Key 'O'
                        runService.Heartbeat:Wait()
                        keyrelease(0x49) -- Release 'I'
                        runService.Heartbeat:Wait()
                        keyrelease(0x4F) -- Release 'O'
                    until not speedGlitching
                end)
            end
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if not Croowz.Macro.Enabled then
        speedGlitching = false
    end
end)

local UserInputService = game:GetService("UserInputService")

local proximityDistance = getgenv().Croowz.AutoBuyArea.Distance or 10

local targetPositions = {
    Vector3.new(-635.77001953125, 18.855512619018555, -119.34500122070312),
    Vector3.new(-1046.2003173828125, 18.851364135742188, -256.449951171875),
    Vector3.new(492.8777160644531, 45.112525939941406, -620.4310913085938),
    Vector3.new(533.6549682617188, 1.7305126190185547, -257.5400085449219),
    Vector3.new(32.894508361816406, 22.60923194885254, -845.3250122070312)
}

-- Corresponding item names
local targetItems = {
    "12 [Revolver Ammo] - $80",
    "18 [Double-Barrel SG Ammo] - $64",
    "20 [TacticalShotgun Ammo] - $64",
    "12 [Revolver Ammo] - $53",
    "18 [Double-Barrel SG Ammo] - $53"
}

local isLoopActive = false

local function checkProximityAndClick()
    while isLoopActive do
        -- Ensure character exists
        local character = game.Players.LocalPlayer.Character
        if not character then
            wait(0.1)
            continue
        end

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            wait(0.1)  -- Small delay if HumanoidRootPart is not yet available
            continue
        end

        for index, targetPosition in ipairs(targetPositions) do
            local distance = (humanoidRootPart.Position - targetPosition).Magnitude

            if distance <= proximityDistance then
                local shopFolder = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Shop")
                
                if shopFolder then
                    local targetItem = shopFolder:FindFirstChild(targetItems[index])
                    
                    if targetItem then
                        local clickDetector = targetItem:FindFirstChild("ClickDetector")
                        if clickDetector then
                            fireclickdetector(clickDetector)
                        end
                    end
                end
                
                break
            end
        end

        wait(0.2)
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if not isProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        local currentHoldKey = Enum.KeyCode[getgenv().Croowz.Keybinds.AutoBuyKeybind]
        
        if input.KeyCode == currentHoldKey then
            isLoopActive = true
            spawn(checkProximityAndClick)
        end
    end
end)


UserInputService.InputEnded:Connect(function(input, isProcessed)
    if not isProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        local currentHoldKey = Enum.KeyCode[getgenv().Croowz.Keybinds.AutoBuyKeybind]
        
        if input.KeyCode == currentHoldKey then
            isLoopActive = false
        end
    end
end)

local function setAutobuyKeybind(key)
    if Enum.KeyCode[key] then
        getgenv().Croowz.Keybinds.AutoBuyKeybind = key
    end
end

getgenv().UpdateNotification = true
getgenv().Loaded = true
