local Creator = loadstring(game:HttpGet(
    "https://pastebin.com/raw/0fSnvfGt"
))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--------------------------------------------------
-- RIPPER CONFIGURATION
--------------------------------------------------

local entity = Creator.createEntity({
    CustomName = "Ripper",

    Model = "https://raw.githubusercontent.com/Ilikerobloxdoors/Ripper-OLDEST/main/Oldest%20ripper.rbxm",

    Speed = 240,
    DelayTime = 6.5,
    HeightOffset = 0,

    CanKill = true,
    KillRange = 40,
    BreakLights = false,
    BackwardsMovement = false,

    FlickerLights = {
        false,
        1,
    },

    Cycles = {
        Min = 1,
        Max = 1,
        WaitTime = 0.02,
    },

    CamShake = {
        true,
        {7.5, 7, 0.1, 1.3},
        100,
    },

    -- Custom jumpscare handled below
    Jumpscare = {
        false,
        {},
    },

    CustomDialog = {
        "You died to Ripper...",
        "It's presence is known by the red lights...",
        "Hide when this happens!",
    },
})

--------------------------------------------------
-- SOUND EFFECTS
--------------------------------------------------

local scream = Instance.new("Sound")
scream.Name = "RipperScream"
scream.SoundId = "rbxassetid://9125713501"
scream.Volume = 1
scream.PlaybackSpeed = 0.4
scream.Looped = false
scream.Parent = SoundService

local staticSound = Instance.new("Sound")
staticSound.Name = "RipperStatic"
staticSound.SoundId = "rbxassetid://372770465"
staticSound.Volume = 1
staticSound.PlaybackSpeed = 0.7
staticSound.Looped = false
staticSound.Parent = SoundService

--------------------------------------------------
-- RED ROOM EFFECT
--------------------------------------------------

local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

local redEffect = Instance.new("ColorCorrectionEffect")
redEffect.Name = "RipperRedEffect"
redEffect.TintColor = Color3.fromRGB(255, 30, 30)
redEffect.Brightness = -0.1
redEffect.Contrast = 0.3
redEffect.Enabled = false
redEffect.Parent = Lighting

local originalLightColors = {}
local originalFixtureColors = {}

local function turnRoomRed()
    local rooms = workspace:FindFirstChild("CurrentRooms")

    if rooms then
        for _, obj in ipairs(rooms:GetDescendants()) do
            if obj:IsA("PointLight")
                or obj:IsA("SpotLight")
                or obj:IsA("SurfaceLight") then

                if originalLightColors[obj] == nil then
                    originalLightColors[obj] = obj.Color
                end

                TweenService:Create(
                    obj,
                    TweenInfo.new(1),
                    {Color = Color3.fromRGB(255, 0, 0)}
                ):Play()

            elseif obj:IsA("BasePart")
                and obj.Name == "LightFixture" then

                if originalFixtureColors[obj] == nil then
                    originalFixtureColors[obj] = obj.Color
                end

                TweenService:Create(
                    obj,
                    TweenInfo.new(1),
                    {Color = Color3.fromRGB(255, 0, 0)}
                ):Play()
            end
        end
    end

    Lighting.Ambient = Color3.fromRGB(255, 0, 0)
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 0, 0)
    redEffect.Enabled = true
end

local function restoreRoom()
    for light, color in pairs(originalLightColors) do
        if light and light.Parent then
            TweenService:Create(
                light,
                TweenInfo.new(1),
                {Color = color}
            ):Play()
        end
    end

    for fixture, color in pairs(originalFixtureColors) do
        if fixture and fixture.Parent then
            TweenService:Create(
                fixture,
                TweenInfo.new(1),
                {Color = color}
            ):Play()
        end
    end

    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    redEffect.Enabled = false
end

--------------------------------------------------
-- GLITCH JUMPSCARE
--------------------------------------------------

local glitchImages = {
    "rbxassetid://8482795900",
    "rbxassetid://236542974",
    "rbxassetid://184251462",
    "rbxassetid://236777652",
}

local jumpscareRunning = false
local entitySpawned = false
local jumpscareGui
local cameraConnection

local function getEntityPart(entityTable)
    local model = entityTable and entityTable.Model

    if typeof(model) ~= "Instance" then
        return nil, nil
    end

    if model:IsA("BasePart") then
        return model, model
    elseif model:IsA("Model") then
        return model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart", true), model
    end

    return model:FindFirstChildWhichIsA("BasePart", true), model
end

local function playJumpscare(ripperPart, ripperModel)
    if jumpscareRunning or not player.Character then
        return
    end

    local character = player.Character
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end

    if character:GetAttribute("Hiding") then
        return
    end

    jumpscareRunning = true

    local camera = workspace.CurrentCamera
    local oldCameraType = camera.CameraType
    local oldCameraSubject = camera.CameraSubject
    local oldCameraCFrame = camera.CFrame

    local gui = Instance.new("ScreenGui")
    gui.Name = "RipperJumpscare"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = player:WaitForChild("PlayerGui")
    jumpscareGui = gui

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    background.BackgroundTransparency = 0.15
    background.BorderSizePixel = 0
    background.Parent = gui

    local image = Instance.new("ImageLabel")
    image.Name = "RipperGlitch"
    image.Size = UDim2.fromScale(1, 1)
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Stretch
    image.Parent = gui

    camera.CameraType = Enum.CameraType.Scriptable

    local startTime = os.clock()
    local duration = 3
    local lastImageChange = 0

    cameraConnection = RunService.RenderStepped:Connect(function()
        if not gui.Parent then
            return
        end

        if ripperPart and ripperPart.Parent then
            camera.CFrame = CFrame.lookAt(
                oldCameraCFrame.Position,
                ripperPart.Position
            )
        end

        local elapsed = os.clock() - startTime

        if elapsed - lastImageChange >= 0.07 then
            lastImageChange = elapsed

            image.Image = glitchImages[
                math.random(1, #glitchImages)
            ]

            background.BackgroundColor3 =
                math.random(1, 2) == 1
                and Color3.fromRGB(255, 0, 0)
                or Color3.fromRGB(0, 0, 0)

            background.BackgroundTransparency =
                math.random(0, 5) / 10
        end
    end)

    staticSound:Stop()
    staticSound.TimePosition = 0
    staticSound:Play()

    task.wait(duration)

    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    staticSound:Stop()

    if gui then
        gui:Destroy()
    end

    jumpscareGui = nil

    camera.CameraType = oldCameraType
    camera.CameraSubject = oldCameraSubject

    if humanoid.Health > 0 then
        camera.CFrame = oldCameraCFrame
        humanoid.Health = 0
    end

    jumpscareRunning = false
end

--------------------------------------------------
-- CATCH DETECTION
--------------------------------------------------

local function monitorRipper(entityTable)
    local ripperPart, ripperModel = getEntityPart(entityTable)

    if not ripperPart then
        warn("Ripper model has no usable BasePart.")
        return
    end

    while entitySpawned
        and ripperPart.Parent
        and not jumpscareRunning do

        task.wait(0.1)

        local character = player.Character
        local root = character
            and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character
            and character:FindFirstChildWhichIsA("Humanoid")

        if not root or not humanoid or humanoid.Health <= 0 then
            continue
        end

        if character:GetAttribute("Hiding") then
            continue
        end

        local direction = root.Position - ripperPart.Position

        if direction.Magnitude <= 40 then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {ripperModel}

            local result = workspace:Raycast(
                ripperPart.Position,
                direction,
                params
            )

            if result and result.Instance:IsDescendantOf(character) then
                task.spawn(function()
                    playJumpscare(ripperPart, ripperModel)
                end)

                break
            end
        end
    end
end

--------------------------------------------------
-- ENTITY EVENTS
--------------------------------------------------

entity.Debug.OnEntitySpawned = function(entityTable)
    print("Ripper spawned!")

    entitySpawned = true
    turnRoomRed()

    scream:Stop()
    scream.TimePosition = 0
    scream:Play()

    task.spawn(function()
        monitorRipper(entityTable)
    end)
end

entity.Debug.OnEntityDespawned = function(entityTable)
    print("Ripper despawned!")

    entitySpawned = false

    scream:Stop()
    staticSound:Stop()

    restoreRoom()

    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    if jumpscareGui then
        jumpscareGui:Destroy()
        jumpscareGui = nil
    end

    jumpscareRunning = false
end

entity.Debug.OnEntityStartMoving = function(entityTable)
    print("Ripper started moving:", entityTable.Model)
end

entity.Debug.OnEntityFinishedRebound = function(entityTable)
    print("Ripper finished rebound:", entityTable.Model)
end

entity.Debug.OnEntityEnteredRoom = function(entityTable, room)
    print("Ripper entered room:", room)
end

entity.Debug.OnLookAtEntity = function(entityTable)
    print("Player looked at Ripper:", entityTable.Model)
end

entity.Debug.OnDeath = function(entityTable)
    warn("Player died to Ripper.")
end

--------------------------------------------------
-- RUN RIPPER
--------------------------------------------------

Creator.runEntity(entity)
