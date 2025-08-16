--[[
  Universal ESP Menu (fixed left, round button for show/hide, no □)
  By Conghau — 2025-08-16
]]

local TEAM_COLORS = {
    Color3.fromRGB(255, 75, 75),
    Color3.fromRGB(75, 150, 255),
    Color3.fromRGB(100, 255, 120),
    Color3.fromRGB(255, 210, 70),
    Color3.fromRGB(200, 120, 255),
}
local SHOW_DISTANCE = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local State = {
    espEnabled = true,
    tracerEnabled = false,
    hitboxEnabled = false,
    headHitboxSize = 5,
    menuVisible = false  -- Mặc định chỉ hiện nút tròn, menu ẩn
}

local HasDrawing = pcall(function()
    return Drawing and typeof(Drawing.new) == "function"
end)

local ESPMap = {}
local TeamIndexMap = {}

--------------------------
-- UI
--------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP_Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút hình tròn cố định bên trái trên cùng
local openBtn = Instance.new("ImageButton")
openBtn.Size = UDim2.new(0,48,0,48)
openBtn.Position = UDim2.new(0, 32, 0, 18)
openBtn.BackgroundTransparency = 1
openBtn.Image = "rbxassetid://13762382490"
openBtn.Parent = gui
openBtn.Visible = true
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1,0)

-- Khi bấm vào nút tròn, hiện menu
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    State.menuVisible = true
    openBtn.Visible = false
end)

-- Menu ESP cố định bên trái, mặc định ẩn
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 200)
frame.Position = UDim2.new(0, 32, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 28)
title.Position = UDim2.fromOffset(10, 6)
title.BackgroundTransparency = 1
title.Text = "Universal ESP"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function makeToggle(y, label, getFn, setFn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.fromOffset(10, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.AutoButtonColor = true
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function refresh()
        local on = getFn()
        btn.Text = (on and "ON  | " or "OFF | ") .. label
        btn.BackgroundColor3 = on and Color3.fromRGB(35, 120, 70) or Color3.fromRGB(90, 35, 35)
    end

    btn.MouseButton1Click:Connect(function()
        setFn(not getFn())
        refresh()
    end)
    refresh()
end

makeToggle(40, "ESP", function() return State.espEnabled end, function(v) State.espEnabled = v end)
makeToggle(75, "Tracer", function() return State.tracerEnabled end, function(v) State.tracerEnabled = v end)
makeToggle(110,"Hitbox", function() return State.hitboxEnabled end, function(v) State.hitboxEnabled = v end)

-- Slider Head Hitbox
local headSliderLabel = Instance.new("TextLabel")
headSliderLabel.Size = UDim2.new(1, -20, 0, 18)
headSliderLabel.Position = UDim2.fromOffset(12, 145)
headSliderLabel.BackgroundTransparency = 1
headSliderLabel.Text = "Head Hitbox Size: " .. State.headHitboxSize
headSliderLabel.Font = Enum.Font.Gotham
headSliderLabel.TextSize = 14
headSliderLabel.TextColor3 = Color3.fromRGB(200,200,200)
headSliderLabel.TextXAlignment = Enum.TextXAlignment.Left
headSliderLabel.Parent = frame

local headSliderFrame = Instance.new("Frame")
headSliderFrame.Size = UDim2.new(1, -40, 0, 20)
headSliderFrame.Position = UDim2.fromOffset(20, 168)
headSliderFrame.BackgroundColor3 = Color3.fromRGB(55,55,55)
headSliderFrame.Parent = frame
Instance.new("UICorner", headSliderFrame).CornerRadius = UDim.new(1,0)

local headKnob = Instance.new("Frame")
headKnob.Size = UDim2.fromOffset(18, 28)
headKnob.Position = UDim2.new((State.headHitboxSize-5)/15,0,0,-4)
headKnob.BackgroundColor3 = Color3.fromRGB(110,55,55)
headKnob.Parent = headSliderFrame
Instance.new("UICorner", headKnob).CornerRadius = UDim.new(1,0)

headKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local UIS = game:GetService("UserInputService")
        local move
        move = UIS.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                local x = math.clamp(input2.Position.X - headSliderFrame.AbsolutePosition.X, 0, headSliderFrame.AbsoluteSize.X)
                local size = math.floor(5 + (x/headSliderFrame.AbsoluteSize.X)*15)
                State.headHitboxSize = size
                headKnob.Position = UDim2.new((size-5)/15,0,0,-4)
                headSliderLabel.Text = "Head Hitbox Size: " .. size
            end
        end)
        local function endDrag()
            if move then move:Disconnect() end
        end
        UIS.InputEnded:Connect(endDrag)
    end
end)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -10, 0, 18)
note.Position = UDim2.fromOffset(10, 195)
note.BackgroundTransparency = 1
note.Text = HasDrawing and "Drawing API: YES (tracers enabled)" or "Drawing API: NO (tracers disabled)"
note.Font = Enum.Font.Gotham
note.TextSize = 12
note.TextColor3 = Color3.fromRGB(200,200,200)
note.TextXAlignment = Enum.TextXAlignment.Left
note.Parent = frame

-- Nút tắt menu (✕)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,32,0,32)
closeBtn.Position = UDim2.new(1,-42,0,8)
closeBtn.BackgroundColor3 = Color3.fromRGB(120,30,30)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    State.menuVisible = false
    openBtn.Visible = true
end)

--------------------------
-- ESP CODE (auto update, features toggled by menu)
--------------------------
local function formatNum(n)
    n = math.floor(n or 0)
    if n >= 1000 then
        return string.format("%.1fk", n/1000)
    end
    return tostring(n)
end

local function getTeamKey(p)
    if p.Team ~= nil then
        return "T:" .. (p.Team.Name or "Unknown")
    elseif p.TeamColor ~= nil then
        return "C:" .. tostring(p.TeamColor)
    else
        return "N:" .. p.Name
    end
end

local function getTeamColor(p)
    local key = getTeamKey(p)
    if not TeamIndexMap[key] then
        local count = 0
        for _ in pairs(TeamIndexMap) do count += 1 end
        local idx = (count % 5) + 1
        TeamIndexMap[key] = idx
    end
    return TEAM_COLORS[TeamIndexMap[key]] or TEAM_COLORS[1]
end

local function worldToScreen(v3)
    local v, onScreen = Camera:WorldToViewportPoint(v3)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function makeBillboard(character, player)
    local head = character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Nameplate"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Adornee = head
    bb.Parent = character

    local tl = Instance.new("TextLabel")
    tl.Name = "Label"
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.TextColor3 = getTeamColor(player)
    tl.TextStrokeTransparency = 0.5
    tl.TextYAlignment = Enum.TextYAlignment.Center
    tl.Parent = bb

    return bb, tl
end

local function makeHighlight(character, player)
    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = getTeamColor(player)
    h.Adornee = character
    h.Parent = character
    return h
end

local function makeBoxAdornment(character, player)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box"
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.7
    box.Color3 = getTeamColor(player)
    box.Size = hrp.Size
    box.Parent = hrp
    return box
end

local function makeTracer(character, player)
    if not HasDrawing then return nil end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = false
    line.Color = getTeamColor(player)
    return line
end

local function updateNameplateText(tl, player, humanoid, character)
    if not tl or not tl.Parent then return end
    local hp = (humanoid and humanoid.Health) or 0
    local maxHp = (humanoid and humanoid.MaxHealth) or 100
    local percent = (maxHp > 0) and math.clamp(hp / maxHp * 100, 0, 999) or 0
    local dist = ""
    if SHOW_DISTANCE then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            dist = string.format(" | %dm", math.floor(d + 0.5))
        end
    end
    tl.Text = string.format("%s | HP: %s/%s (%.0f%%%s)", player.Name, formatNum(hp), formatNum(maxHp), percent, dist)
end

local function applyHeadHitbox(character, enable, store)
    local head = character:FindFirstChild("Head")
    if not head then return end
    if enable then
        if store then
            store.headSize = head.Size
        end
        pcall(function()
            head.Size = Vector3.new(State.headHitboxSize, State.headHitboxSize, State.headHitboxSize)
        end)
    else
        if store and store.headSize then
            pcall(function()
                head.Size = store.headSize
            end)
        end
    end
end

local function createESPForPlayer(p)
    if p == LocalPlayer then return end
    local container = { conns = {}, originals = {} }
    ESPMap[p] = container

    local function onCharacter(char)
        container.character = char

        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        local bb, label = makeBillboard(char, p)
        container.gui = bb
        container.label = label

        container.highlight = makeHighlight(char, p)
        container.box = makeBoxAdornment(char, p)
        container.tracer = makeTracer(char, p)

        if humanoid then
            table.insert(container.conns, humanoid.HealthChanged:Connect(function()
                updateNameplateText(label, p, humanoid, char)
            end))
            updateNameplateText(label, p, humanoid, char)
        end

        local visible = State.espEnabled
        if container.gui then container.gui.Enabled = visible end
        if container.highlight then container.highlight.Enabled = visible end
        if container.box then container.box.Visible = visible end
        if container.tracer then container.tracer.Visible = (visible and State.tracerEnabled) end

        applyHeadHitbox(char, State.hitboxEnabled, container.originals)
    end

    if p.Character then
        onCharacter(p.Character)
    end
    table.insert(container.conns, p.CharacterAdded:Connect(function(c)
        if container.tracer then pcall(function() container.tracer.Visible=false; container.tracer:Remove() end) end
        container.tracer = nil
        onCharacter(c)
    end))
end

local function removeESPForPlayer(p)
    local container = ESPMap[p]
    if not container then return end

    if container.character then
        applyHeadHitbox(container.character, false, container.originals)
    end

    for _,c in ipairs(container.conns) do
        pcall(function() c:Disconnect() end)
    end

    if container.gui then pcall(function() container.gui:Destroy() end) end
    if container.highlight then pcall(function() container.highlight:Destroy() end) end
    if container.box then pcall(function() container.box:Destroy() end) end
    if container.tracer then pcall(function() container.tracer.Visible=false; container.tracer:Remove() end) end

    ESPMap[p] = nil
end

local function applyEspVisibility()
    for _,container in pairs(ESPMap) do
        if container.gui then container.gui.Enabled = State.espEnabled end
        if container.highlight then container.highlight.Enabled = State.espEnabled end
        if container.box then container.box.Visible = State.espEnabled end
        if container.tracer then container.tracer.Visible = (State.espEnabled and State.tracerEnabled) end
    end
end

local function applyHeadHitboxAll()
    for _,container in pairs(ESPMap) do
        if container.character then
            applyHeadHitbox(container.character, State.hitboxEnabled, container.originals)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not State.espEnabled or not State.tracerEnabled or not HasDrawing then
        for _,ct in pairs(ESPMap) do
            if ct.tracer then ct.tracer.Visible = false end
        end
    else
        local screenBottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y - 2)
        for _,ct in pairs(ESPMap) do
            local char = ct.character
            local tracer = ct.tracer
            if tracer and char and char.Parent then
                local head = char:FindFirstChild("Head")
                if head then
                    local pos2D, onScreen = worldToScreen(head.Position)
                    if onScreen then
                        tracer.From = screenBottom
                        tracer.To = pos2D
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                else
                    tracer.Visible = false
                end
            end
        end
    end
    -- Cập nhật liên tục khoảng cách trên label
    for _,container in pairs(ESPMap) do
        if container.label and container.character then
            local humanoid = container.character:FindFirstChildOfClass("Humanoid")
            updateNameplateText(container.label, Players:GetPlayerFromCharacter(container.character), humanoid, container.character)
        end
    end
end)

for _,p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createESPForPlayer(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        createESPForPlayer(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    removeESPForPlayer(p)
end)

task.spawn(function()
    local last = {esp=false, tracer=false, hit=false, size=5}
    while true do
        if State.espEnabled ~= last.esp or State.tracerEnabled ~= last.tracer then
            applyEspVisibility()
            last.esp = State.espEnabled
            last.tracer = State.tracerEnabled
        end
        if State.hitboxEnabled ~= last.hit or State.headHitboxSize ~= last.size then
            applyHeadHitboxAll()
            last.hit = State.hitboxEnabled
            last.size = State.headHitboxSize
        end
        task.wait(0.25)
    end
end)
