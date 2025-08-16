--[[
  Universal ESP + Team + Health + Tracers + Hitbox (5 teams)
  By Conghau — 2025-08-16

  Features:
    - ESP with up to 5 team colors (auto-detect from Player.Team / TeamColor / Name)
    - Name + Health (and distance) above head
    - Tracer lines (Drawing API) from bottom-center of screen to player head
    - Auto-updates: player join/leave, character spawn/death/respawn
    - Hitbox toggle: enlarge HumanoidRootPart (HRP) on ON, restore on OFF
    - Simple draggable menu with toggles

  Notes:
    - Tracers need an executor with Drawing API. If not available, tracers auto-disable.
    - Hitbox is client-side only.
    - LocalPlayer is ignored.
]]

--------------------------
-- CONFIG
--------------------------
local TEAM_COLORS = {
    Color3.fromRGB(255, 75, 75),   -- Team 1 (Red)
    Color3.fromRGB(75, 150, 255),  -- Team 2 (Blue)
    Color3.fromRGB(100, 255, 120), -- Team 3 (Green)
    Color3.fromRGB(255, 210, 70),  -- Team 4 (Yellow)
    Color3.fromRGB(200, 120, 255), -- Team 5 (Purple)
}
local HITBOX_SIZE = Vector3.new(6, 6, 6)  -- HRP size when hitbox is enabled
local SHOW_DISTANCE = true                -- show distance in the label

--------------------------
-- SERVICES / SHORTCUTS
--------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--------------------------
-- GLOBAL STATE
--------------------------
local State = {
    espEnabled = false,
    tracerEnabled = false,
    hitboxEnabled = false,
}

local HasDrawing = pcall(function()
    return Drawing and typeof(Drawing.new) == "function"
end)

-- Player -> container with created objects & connections
-- container = {conns={}, character=Model, gui=BillboardGui, label=TextLabel, highlight=Highlight, box=BoxHandleAdornment, tracer=DrawingLine?, originals={hrpSize, hrpCollide, hrpMassless}}
local ESPMap = {}

-- Team mapping: any unique team key -> 1..5 index
local TeamIndexMap = {}

--------------------------
-- UTILS
--------------------------
local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

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
        -- assign next slot 1..5 (cycling if >5 distinct keys)
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

--------------------------
-- UI (simple draggable menu)
--------------------------
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UniversalESP_Menu"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(220, 150)
    frame.Position = UDim2.new(0, 20, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
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
        return btn
    end

    makeToggle(40, "ESP", function() return State.espEnabled end, function(v) State.espEnabled = v end)
    makeToggle(75, "Tracer", function() return State.tracerEnabled end, function(v) State.tracerEnabled = v end)
    makeToggle(110,"Hitbox", function() return State.hitboxEnabled end, function(v) State.hitboxEnabled = v end)

    local note = Instance.new("TextLabel")
    note.Size = UDim2.new(1, -10, 0, 18)
    note.Position = UDim2.fromOffset(10, 140)
    note.BackgroundTransparency = 1
    note.Text = HasDrawing and "Drawing API: YES (tracers enabled)" or "Drawing API: NO (tracers disabled)"
    note.Font = Enum.Font.Gotham
    note.TextSize = 12
    note.TextColor3 = Color3.fromRGB(200,200,200)
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.Parent = frame
end

--------------------------
-- ESP BUILDERS
--------------------------
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

--------------------------
-- APPLY / REMOVE HELPERS
--------------------------
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

local function applyHitbox(character, enable, store)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if enable then
        if store then
            store.hrpSize = hrp.Size
            store.hrpCollide = hrp.CanCollide
            store.hrpMassless = hrp.Massless
        end
        pcall(function()
            hrp.Size = HITBOX_SIZE
            hrp.Massless = true
            hrp.CanCollide = false
        end)
    else
        if store and store.hrpSize then
            pcall(function()
                hrp.Size = store.hrpSize
                hrp.CanCollide = store.hrpCollide
                hrp.Massless = store.hrpMassless
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

        -- build parts
        local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        local bb, label = makeBillboard(char, p)
        container.gui = bb
        container.label = label

        container.highlight = makeHighlight(char, p)
        container.box = makeBoxAdornment(char, p)
        container.tracer = makeTracer(char, p)

        -- update health label
        if humanoid then
            table.insert(container.conns, humanoid.HealthChanged:Connect(function()
                updateNameplateText(label, p, humanoid, char)
            end))
            updateNameplateText(label, p, humanoid, char)
        end

        -- set visibility by state
        local visible = State.espEnabled
        if container.gui then container.gui.Enabled = visible end
        if container.highlight then container.highlight.Enabled = visible end
        if container.box then container.box.Visible = visible end
        if container.tracer then container.tracer.Visible = (visible and State.tracerEnabled) end

        -- apply hitbox if enabled
        applyHitbox(char, State.hitboxEnabled, container.originals)
    end

    -- hook current or future character
    if p.Character then
        onCharacter(p.Character)
    end
    table.insert(container.conns, p.CharacterAdded:Connect(function(c)
        -- clean old tracer
        if container.tracer then pcall(function() container.tracer.Visible=false; container.tracer:Remove() end) end
        container.tracer = nil
        onCharacter(c)
    end))
end

local function removeESPForPlayer(p)
    local container = ESPMap[p]
    if not container then return end

    -- restore hitbox if changed
    if container.character then
        applyHitbox(container.character, false, container.originals)
    end

    -- disconnect signals
    for _,c in ipairs(container.conns) do safeDisconnect(c) end

    -- destroy visuals
    if container.gui then pcall(function() container.gui:Destroy() end) end
    if container.highlight then pcall(function() container.highlight:Destroy() end) end
    if container.box then pcall(function() container.box:Destroy() end) end
    if container.tracer then pcall(function() container.tracer.Visible=false; container.tracer:Remove() end) end

    ESPMap[p] = nil
end

--------------------------
-- GLOBAL APPLY
--------------------------
local function applyEspVisibility()
    for _,container in pairs(ESPMap) do
        if container.gui then container.gui.Enabled = State.espEnabled end
        if container.highlight then container.highlight.Enabled = State.espEnabled end
        if container.box then container.box.Visible = State.espEnabled end
        if container.tracer then container.tracer.Visible = (State.espEnabled and State.tracerEnabled) end
    end
end

local function applyHitboxAll()
    for _,container in pairs(ESPMap) do
        if container.character then
            applyHitbox(container.character, State.hitboxEnabled, container.originals)
        end
    end
end

--------------------------
-- TRACER UPDATE LOOP
--------------------------
RunService.RenderStepped:Connect(function()
    if not State.espEnabled or not State.tracerEnabled or not HasDrawing then
        for _,ct in pairs(ESPMap) do
            if ct.tracer then ct.tracer.Visible = false end
        end
        return
    end

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
end)

--------------------------
-- PLAYERS HOOK
--------------------------
-- initialize current players
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

--------------------------
-- MENU + FEEDBACK
--------------------------
createUI()

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Universal ESP",
        Text = string.format("Drawing: %s | Teams: %d", HasDrawing and "YES" or "NO", #TEAM_COLORS),
        Duration = 6
    })
end)

-- reactive apply when toggles change
task.spawn(function()
    local last = {esp=false, tracer=false, hit=false}
    while true do
        if State.espEnabled ~= last.esp or State.tracerEnabled ~= last.tracer then
            applyEspVisibility()
            last.esp = State.espEnabled
            last.tracer = State.tracerEnabled
        end
        if State.hitboxEnabled ~= last.hit then
            applyHitboxAll()
            last.hit = State.hitboxEnabled
        end
        task.wait(0.25)
    end
end)
