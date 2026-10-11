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

    Model = "https://raw.githubusercontent.com/Ilikerobloxdoors/Ripper-OLDEST/main/Ripper%20FIX%20Oldest.rbxm",

    Speed = 240,
    DelayTime = 9.5,
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

    -- Custom jumpscare is handled below.
    Jumpscare = {
        false,
        {},
    },

    CustomDialog = {
        "You died to Ripper...",
        "Its presence is known by the red lights...",
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

local function getRipperPart(entityTable)
    local model = entityTable and entityTable.Model

    if typeof(model) ~= "Instance" then
        warn("Ripper model reference was not found.")
        return nil
    end

    if model:IsA("BasePart") then
        return model
    end

    if model:IsA("Model") then
        return model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart", true)
    end

    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function playJumpscare(ripperPart)
    if jumpscareRunning then
        return
    end

    local character = player.Character
    local humanoid = character
        and character:FindFirstChildWhichIsA("Humanoid")
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or not root then
        return
    end

    if humanoid.Health <= 0 or character:GetAttribute("Hiding") then
        return
    end

    jumpscareRunning = true

    local camera = workspace.CurrentCamera
    local oldType = camera.CameraType
    local oldSubject = camera.CameraSubject
    local oldCFrame = camera.CFrame

    local gui = Instance.new("ScreenGui")
    gui.Name = "RipperJumpscare"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = player:WaitForChild("PlayerGui")
    jumpscareGui = gui

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    background.BackgroundTransparency = 0.15
    background.BorderSizePixel = 0
    background.Parent = gui

    local face = Instance.new("ImageLabel")
    face.Name = "RipperGlitch"
    face.Size = UDim2.fromScale(1, 1)
    face.BackgroundTransparency = 1
    face.ScaleType = Enum.ScaleType.Stretch
    face.Parent = gui

    camera.CameraType = Enum.CameraType.Scriptable

    staticSound:Stop()
    staticSound.TimePosition = 0
    staticSound:Play()

    local started = os.clock()
    local duration = 3
    local nextGlitch = 0

    cameraConnection = RunService.RenderStepped:Connect(function()
        if not gui.Parent then
            return
        end

        if ripperPart and ripperPart.Parent then
            camera.CFrame = CFrame.lookAt(
                oldCFrame.Position,
                ripperPart.Position
            )
        end

        local elapsed = os.clock() - started

        if elapsed >= nextGlitch then
            nextGlitch = elapsed + 0.06

            face.Image = glitchImages[
                math.random(1, #glitchImages)
            ]

            background.BackgroundColor3 =
                math.random(1, 2) == 1
                and Color3.fromRGB(255, 0, 0)
                or Color3.fromRGB(0, 0, 0)

            background.BackgroundTransparency =
                math.random(0, 5) / 10

            face.Position = UDim2.fromOffset(
                math.random(-15, 15),
                math.random(-15, 15)
            )
        end
    end)

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

    camera.CameraType = oldType
    camera.CameraSubject = oldSubject

    if humanoid.Parent and humanoid.Health > 0 then
        camera.CFrame = oldCFrame
        humanoid.Health = 0
    end

    jumpscareRunning = false
end

--------------------------------------------------
-- CATCH DETECTION
--------------------------------------------------

local function monitorRipper(entityTable)
    local ripperPart = getRipperPart(entityTable)

    if not ripperPart then
        warn("Could not locate Ripper's BasePart.")
        return
    end

    print("Ripper catch detection started.")

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

        local distance = (ripperPart.Position - root.Position).Magnitude

        if distance <= 40 then
            print("Ripper caught the player!")

            task.spawn(function()
                playJumpscare(ripperPart)
            end)

            break
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
