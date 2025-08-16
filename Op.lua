-- Universal ESP + Hitbox Menu, Team/HP/Distance, Auto Update
local Teams = {"Red", "Blue", "Green", "Yellow", "Purple"} -- Thay bằng tên team của game nếu cần

local gui=Instance.new("ScreenGui",game.CoreGui)
gui.Name = "UniversalESPMenu"

local frame=Instance.new("Frame",gui)
frame.Size=UDim2.new(0,250,0,370)
frame.Position=UDim2.new(1,-260,0,100)
frame.BackgroundColor3=Color3.new(.1,.1,.15)
frame.Visible=false
frame.BorderSizePixel=2

local openBtn=Instance.new("TextButton",gui)
openBtn.Size=UDim2.new(0,80,0,40)
openBtn.Position=UDim2.new(1,-90,0,40)
openBtn.Text="ESP Menu"
openBtn.BackgroundColor3=Color3.new(.2,0,0)
openBtn.TextColor3=Color3.new(1,1,1)
openBtn.TextScaled=true

local closeBtn=Instance.new("TextButton",frame)
closeBtn.Size=UDim2.new(0,40,0,40)
closeBtn.Position=UDim2.new(1,-40,0,0)
closeBtn.Text="X"
closeBtn.BackgroundColor3=Color3.new(.3,.1,.1)
closeBtn.TextColor3=Color3.new(1,1,1)
closeBtn.TextScaled=true

-- Toggle buttons
local toggles={ESP=false,Line=false,ShowHP=true,ShowTeam=true,ShowDist=false,Hitbox=false}
local togBtns={}
local opts = {"ESP","Line","ShowHP","ShowTeam","ShowDist","Hitbox"}
for i,info in ipairs(opts) do
    local b=Instance.new("TextButton",frame)
    b.Size=UDim2.new(0,190,0,34)
    b.Position=UDim2.new(0,25,0,50+(i-1)*38)
    b.Text=info..": "..(toggles[info] and "ON" or "OFF")
    b.BackgroundColor3=Color3.new(.2,.2,.2)
    b.TextColor3=Color3.new(1,1,1)
    b.TextScaled=true
    togBtns[info]=b
    b.MouseButton1Click:Connect(function()
        toggles[info]=not toggles[info]
        b.Text=info..": "..(toggles[info] and "ON" or "OFF")
        updateAll()
    end)
end

openBtn.MouseButton1Click:Connect(function()
    frame.Visible=true
    openBtn.Visible=false
end)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible=false
    openBtn.Visible=true
end)

-- ESP Functions
local function clearESP(pchar)
    for _,v in pairs(pchar:GetChildren()) do
        if v:IsA("BillboardGui") and v.Name:match("^ESP") then v:Destroy() end
        if v:IsA("Beam") and v.Name=="ESPLINE" then v:Destroy() end
        if v:IsA("BoxHandleAdornment") and v.Name=="HitboxESP" then v:Destroy() end
    end
end

local function getTeamColor(teamname)
    local col = {
        Red=Color3.new(1,0,0),
        Blue=Color3.new(0,0,1),
        Green=Color3.new(0,1,0),
        Yellow=Color3.new(1,1,0),
        Purple=Color3.new(0.5,0,0.8)
    }
    return col[teamname] or Color3.new(1,1,1)
end

local function drawESP(plr)
    if plr==game.Players.LocalPlayer or not plr.Character then return end
    local pchar=plr.Character
    clearESP(pchar)
    if not toggles.ESP then return end
    local head=pchar:FindFirstChild("Head")
    local root=pchar:FindFirstChild("HumanoidRootPart") or pchar:FindFirstChildWhichIsA("BasePart")
    local humanoid=pchar:FindFirstChildOfClass("Humanoid")
    -- Team
    local teamname = plr.Team and plr.Team.Name or "NoTeam"
    local tcolor = getTeamColor(teamname)
    -- ESP Name/HP/Team/Distance
    if head then
        local esp=Instance.new("BillboardGui",head)
        esp.Name="ESPName"
        esp.Size=UDim2.new(4,0,.8,0)
        esp.AlwaysOnTop=true
        local tl=Instance.new("TextLabel",esp)
        tl.Size=UDim2.new(1,0,1,0)
        tl.BackgroundTransparency=1
        tl.Text=plr.Name
        tl.TextColor3=tcolor
        tl.TextScaled=true
        tl.Font=Enum.Font.GothamBold
        if toggles.ShowTeam then
            tl.Text = tl.Text .. " ["..teamname.."]"
        end
        if toggles.ShowHP and humanoid then
            tl.Text = tl.Text .. " | HP: "..math.floor(humanoid.Health)
        end
        if toggles.ShowDist and root then
            local localRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if localRoot then
                local dist = (localRoot.Position - root.Position).Magnitude
                tl.Text = tl.Text .. string.format(" | %.1fm", dist)
            end
        end
    end
    -- Line ESP
    if toggles.Line and root and head and root~=head then
        local beam=Instance.new("Beam",head)
        beam.Name="ESPLINE"
        local a0=Instance.new("Attachment",root)
        local a1=Instance.new("Attachment",head)
        beam.Attachment0=a0 beam.Attachment1=a1
        beam.Color=ColorSequence.new(tcolor)
        beam.Width0=0.15 beam.Width1=0.15 beam.FaceCamera=true
        beam.Transparency=NumberSequence.new(.3)
    end
    -- Hitbox
    if toggles.Hitbox and head then
        local hitbox=Instance.new("BoxHandleAdornment",head)
        hitbox.Name="HitboxESP"
        hitbox.Size=Vector3.new(6,6,6)
        hitbox.Color3=Color3.new(.8,.2,.2)
        hitbox.Transparency=.6 hitbox.AlwaysOnTop=true hitbox.ZIndex=15
    end
end

function updateAll()
    for _,plr in ipairs(game.Players:GetPlayers()) do
        if plr.Character then drawESP(plr) end
    end
end

game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() drawESP(plr) end)
end)
game.Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then clearESP(plr.Character) end
end)
for _,plr in ipairs(game.Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function() drawESP(plr) end)
    if plr.Character then drawESP(plr) end
end

-- Auto update HP/Team/Distance
game:GetService("RunService").RenderStepped:Connect(function()
    updateAll()
end)

print("Universal ESP/Hitbox menu loaded!")
