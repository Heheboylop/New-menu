--// Load Orion UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "ESP & Hitbox by CongHau",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "CongHauESP"
})

OrionLib:MakeNotification({
    Name = "Welcome",
    Content = "Script Loaded Successfully!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

--// Variables
local ESPEnabled = false
local HitboxEnabled = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

--// Functions
local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "CongHauESP"

local function ClearESP()
    for _, v in pairs(ESPFolder:GetChildren()) do
        v:Destroy()
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP_" .. player.Name
    Billboard.Adornee = player.Character:WaitForChild("Head")
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 2, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = ESPFolder

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.TextSize = 16
    TextLabel.TextStrokeTransparency = 0.5
    TextLabel.Parent = Billboard

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character:FindFirstChild("Humanoid")
            TextLabel.Text = "[" .. player.Team.Name .. "] " .. player.Name .. " | HP: " .. math.floor(hum.Health)
            if hum.Health <= 0 then
                Billboard.Enabled = false
            else
                Billboard.Enabled = ESPEnabled
            end
        else
            Billboard.Enabled = false
        end
    end)
end

local function EnableESP()
    ClearESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            wait(1)
            CreateESP(player)
        end)
    end)
end

--// Hitbox Function
local function SetHitbox(state)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local HRP = player.Character.HumanoidRootPart
            if state then
                HRP.Size = Vector3.new(10, 10, 10) -- Bigger Hitbox
                HRP.Transparency = 0.7
                HRP.BrickColor = BrickColor.new("Really red")
                HRP.Material = Enum.Material.Neon
                HRP.CanCollide = false
            else
                HRP.Size = Vector3.new(2, 2, 1)
                HRP.Transparency = 1
            end
        end
    end
end

--// Menu Tab
local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- ESP Toggle
Tab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        ESPEnabled = Value
        if ESPEnabled then
            EnableESP()
        else
            ClearESP()
        end
    end
})

-- Hitbox Toggle
Tab:AddToggle({
    Name = "Enable Hitbox",
    Default = false,
    Callback = function(Value)
        HitboxEnabled = Value
        if HitboxEnabled then
            SetHitbox(true)
        else
            SetHitbox(false)
        end
    end
})

OrionLib:Init()
