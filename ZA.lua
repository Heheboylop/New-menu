--[[
  Universal ESP + Hitbox Menu (Optimized)
  - Nút tròn (ảnh rồng) bật/đóng menu
  - 5 team màu tự xoay, hiện tên/đội/HP + khoảng cách
  - Tracer (Beam), Hitbox (BoxHandleAdornment)
  - Cập nhật hiệu quả (event + timer), không spam mỗi frame
  - Sạch rò rỉ: xóa Beam kèm Attachment
  By: you + review
]]

local DRAGON_IMG = "rbxassetid://13762382490"

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

-- ==== Team color mapping (5 màu xoay vòng) ====
local TEAM_COLORS = {
    Color3.fromRGB(255, 75, 75),
    Color3.fromRGB(75, 150, 255),
    Color3.fromRGB(100, 255, 120),
    Color3.fromRGB(255, 210, 70),
    Color3.fromRGB(200, 120, 255),
}
local TeamIndex = {}
local function teamKey(p)
    return (p.Team and ("T:"..p.Team.Name)) or "NoTeam"
end
local function getTeamColor(p)
    local key = teamKey(p)
    if not TeamIndex[key] then
        local count = 0
        for _ in pairs(TeamIndex) do count += 1 end
        TeamIndex[key] = (count % #TEAM_COLORS) + 1
    end
    return TEAM_COLORS[TeamIndex[key]]
end

-- ==== GUI ====
local guiParent = LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESPMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 240)
frame.Position = UDim2.new(1, -260, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Text = "Universal ESP"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.Position = UDim2.new(1,-42,0,6)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(120,30,30)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

local dragonBtn = Instance.new("ImageButton")
dragonBtn.Name = "DragonMenuBtn"
dragonBtn.Size = UDim2.fromOffset(60,60)
dragonBtn.Position = UDim2.new(1,-90,0,28)
dragonBtn.BackgroundTransparency = 1
dragonBtn.Image = DRAGON_IMG
dragonBtn.Parent = gui
Instance.new("UICorner", dragonBtn).CornerRadius = UDim.new(1,0)

dragonBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    dragonBtn.Visible = false
end)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    dragonBtn.Visible = true
end)

-- ==== Toggles ====
local Tog = { ESP = true, Line = false, ShowHP = true, ShowTeam = true, Hitbox = false }
local function makeToggle(idx, key, label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(200, 34)
    b.Position = UDim2.fromOffset(20, 50 + (idx-1)*38)
    b.BackgroundColor3 = Color3.fromRGB(45,45,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 16
    b.AutoButtonColor = true
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local function refresh()
        b.Text = (Tog[key] and "ON  | " or "OFF | ") .. label
        b.BackgroundColor3 = Tog[key] and Color3.fromRGB(35,120,70) or Color3.fromRGB(90,35,35)
    end
    b.MouseButton1Click:Connect(function()
        Tog[key] = not Tog[key]
        refresh()
        -- áp lại cho tất cả
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then applyForPlayer(plr) end
        end
    end)
    refresh()
end

-- tạo trước applyForPlayer để toggle gọi được
function applyForPlayer(_) end

makeToggle(1,"ESP","ESP")
makeToggle(2,"Line","Tracer (Line)")
makeToggle(3,"ShowHP","Show HP")
makeToggle(4,"ShowTeam","Show Team")
makeToggle(5,"Hitbox","Head Hitbox")

-- ==== ESP storage per player ====
local Map = {} -- [player] = {char, conns, nameGui, label, beam, a0, a1, hitbox}

local function destroy(v)
    if v then pcall(function() v:Destroy() end) end
end
local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function clearOne(p)
    local box = Map[p]
    if not box then return end
    -- connections
    for _,c in ipairs(box.conns) do disconnect(c) end
    box.conns = {}
    -- visuals
    destroy(box.nameGui)
    destroy(box.beam)
    destroy(box.a0)
    destroy(box.a1)
    destroy(box.hitbox)
    Map[p] = nil
end

-- format + distance
local function formatInt(n) n = math.floor(n or 0); return n >= 1000 and string.format("%.1fk", n/1000) or tostring(n) end
local function updateLabel(p)
    local box = Map[p]; if not box or not box.label then return end
    if not Tog.ESP then box.label.Text = "" return end
    local hum = box.hum
    local hp = hum and hum.Health or 0
    local maxHp = hum and hum.MaxHealth or 100
    local txt = p.Name
    if Tog.ShowTeam then
        local tname = (p.Team and p.Team.Name) or "NoTeam"
        txt = string.format("%s [%s]", txt, tname)
    end
    if Tog.ShowHP then
        txt = string.format("%s | HP: %s/%s", txt, formatInt(hp), formatInt(maxHp))
    end
    -- distance (nếu có HRP)
    local hrp = box.char and box.char:FindFirstChild("HumanoidRootPart")
    local myhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myhrp then
        local d = (hrp.Position - myhrp.Position).Magnitude
        txt = string.format("%s | %dm", txt, math.floor(d + 0.5))
    end
    box.label.Text = txt
end

-- tạo nameplate
local function ensureNameplate(p, char)
    local head = char:FindFirstChild("Head"); if not head then return end
    local bb = Map[p].nameGui
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "ESP_Nameplate"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 220, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Adornee = head
        bb.Parent = char
        local tl = Instance.new("TextLabel")
        tl.BackgroundTransparency = 1
        tl.Size = UDim2.new(1,0,1,0)
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 14
        tl.TextColor3 = getTeamColor(p)
        tl.TextStrokeTransparency = 0.5
        tl.Parent = bb
        Map[p].nameGui = bb
        Map[p].label = tl
    else
        bb.Adornee = head
    end
    bb.Enabled = Tog.ESP
end

-- tạo/xóa tracer
local function setTracer(p, char)
    local box = Map[p]
    if not Tog.Line then
        destroy(box.beam); box.beam=nil
        destroy(box.a0);   box.a0=nil
        destroy(box.a1);   box.a1=nil
        return
    end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if not (head and root) then return end
    if not box.beam then
        box.a0 = Instance.new("Attachment")
        box.a0.Name = "ESPLINE_A0"
        box.a0.Parent = root
        box.a1 = Instance.new("Attachment")
        box.a1.Name = "ESPLINE_A1"
        box.a1.Parent = head

        local beam = Instance.new("Beam")
        beam.Name = "ESPLINE"
        beam.Attachment0 = box.a0
        beam.Attachment1 = box.a1
        beam.Color = ColorSequence.new(getTeamColor(p))
        beam.Transparency = NumberSequence.new(0.3)
        beam.Width0 = 0.15; beam.Width1 = 0.15
        beam.FaceCamera = true
        beam.Parent = head
        box.beam = beam
    else
        -- refresh color/targets
        box.a0.Parent = root
        box.a1.Parent = head
        box.beam.Color = ColorSequence.new(getTeamColor(p))
    end
end

-- tạo/xóa hitbox
local function setHitbox(p, char)
    local box = Map[p]
    if not Tog.Hitbox then destroy(box.hitbox); box.hitbox=nil; return end
    local head = char:FindFirstChild("Head"); if not head then return end
    if not box.hitbox then
        local hb = Instance.new("BoxHandleAdornment")
        hb.Name = "HitboxESP"
        hb.Adornee = head
        hb.Size = Vector3.new(6,6,6)
        hb.Color3 = Color3.new(.8,.2,.2)
        hb.Transparency = .6
        hb.AlwaysOnTop = true
        hb.ZIndex = 15
        hb.Parent = head
        box.hitbox = hb
    end
end

-- áp cho 1 player (tạo nếu thiếu, cập nhật nếu có)
function applyForPlayer(p)
    if p == LocalPlayer then return end
    local char = p.Character
    if not char then return end

    Map[p] = Map[p] or { conns = {}, char = char }
    Map[p].char = char
    Map[p].hum  = char:FindFirstChildOfClass("Humanoid")

    ensureNameplate(p, char)
    setTracer(p, char)
    setHitbox(p, char)
    updateLabel(p)
end

-- set hook character/team/health
local function hookPlayer(p)
    if p == LocalPlayer then return end
    clearOne(p)

    local function onChar(c)
        clearOne(p)
        Map[p] = { conns = {}, char = c }
        -- health change
        local hum = c:FindFirstChildOfClass("Humanoid") or c:WaitForChild("Humanoid", 10)
        Map[p].hum = hum
        if hum then
            table.insert(Map[p].conns, hum.HealthChanged:Connect(function()
                updateLabel(p)
            end))
        end
        applyForPlayer(p)
    end

    if p.Character then onChar(p.Character) end
    table.insert(Map[p] and Map[p].conns or {}, p.CharacterAdded:Connect(onChar))
    table.insert(Map[p] and Map[p].conns or {}, p:GetPropertyChangedSignal("Team"):Connect(function()
        -- cập nhật màu theo team mới
        if Map[p] and Map[p].label then
            Map[p].label.TextColor3 = getTeamColor(p)
        end
        if Map[p] and Map[p].beam then
            Map[p].beam.Color = ColorSequence.new(getTeamColor(p))
        end
        updateLabel(p)
    end))
end

-- players existing + future
for _,pl in ipairs(Players:GetPlayers()) do hookPlayer(pl) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p) clearOne(p) end)

-- update distance nhẹ nhàng
task.spawn(function()
    while true do
        for p,_ in pairs(Map) do updateLabel(p) end
        task.wait(0.25)
    end
end)

print("Universal ESP/Hitbox menu (optimized) loaded.")
