-- Universal Hitblox ESP Menu (All Roblox Maps/Games, Mobile-friendly, Remote Load Compatible)
-- Toggle: Line, Name, Bone ESP | Custom Name | Adjustable Head Hitbox | Auto Update | Open/Close Menu

local gui=Instance.new("ScreenGui",game.CoreGui)
local frame=Instance.new("Frame",gui) frame.Size=UDim2.new(0,210,0,220) frame.Position=UDim2.new(1,-220,0,100) frame.BackgroundColor3=Color3.new(.1,.1,.15) frame.Visible=false frame.BorderSizePixel=2
local openBtn=Instance.new("TextButton",gui) openBtn.Size=UDim2.new(0,60,0,40) openBtn.Position=UDim2.new(1,-70,0,40) openBtn.Text="ESP Menu" openBtn.BackgroundColor3=Color3.new(.2,0,0) openBtn.TextColor3=Color3.new(1,1,1) openBtn.TextScaled=true
local closeBtn=Instance.new("TextButton",frame) closeBtn.Size=UDim2.new(0,40,0,40) closeBtn.Position=UDim2.new(1,-40,0,0) closeBtn.Text="X" closeBtn.BackgroundColor3=Color3.new(.3,.1,.1) closeBtn.TextColor3=Color3.new(1,1,1) closeBtn.TextScaled=true

-- Toggle buttons
local toggles={Line=false,Name=true,Bone=false}
local togBtns={}
for i,info in ipairs({"Line","Name","Bone"}) do
    local b=Instance.new("TextButton",frame)
    b.Size=UDim2.new(0,90,0,34) b.Position=UDim2.new(0,10,0,10+(i-1)*38)
    b.Text=info.." ESP: OFF" b.BackgroundColor3=Color3.new(.2,.2,.2) b.TextColor3=Color3.new(1,1,1) b.TextScaled=true
    togBtns[info]=b
    b.MouseButton1Click:Connect(function()
        toggles[info]=not toggles[info]
        b.Text=info.." ESP: "..(toggles[info] and "ON" or "OFF")
        updateAll()
    end)
end

-- Custom player name input
local nameLbl=Instance.new("TextLabel",frame) nameLbl.Size=UDim2.new(0,88,0,26) nameLbl.Position=UDim2.new(0,110,0,12) nameLbl.BackgroundTransparency=1 nameLbl.Text="Custom Name:" nameLbl.TextColor3=Color3.new(1,1,1) nameLbl.TextScaled=true
local nameBox=Instance.new("TextBox",frame) nameBox.Size=UDim2.new(0,88,0,26) nameBox.Position=UDim2.new(0,110,0,42) nameBox.PlaceholderText="Type name..." nameBox.TextColor3=Color3.new(.8,.9,1) nameBox.TextScaled=true nameBox.BackgroundColor3=Color3.new(.15,.15,.18)
local customName=""
nameBox.FocusLost:Connect(function() customName=nameBox.Text updateAll() end)

-- Head hitbox size slider
local sizeLbl=Instance.new("TextLabel",frame) sizeLbl.Size=UDim2.new(0,190,0,24) sizeLbl.Position=UDim2.new(0,10,0,140)
sizeLbl.BackgroundTransparency=1 sizeLbl.Text="Head Hitbox Size: 5" sizeLbl.TextColor3=Color3.new(1,1,1) sizeLbl.TextScaled=true
local sizeBar=Instance.new("Frame",frame) sizeBar.Size=UDim2.new(0,180,0,8) sizeBar.Position=UDim2.new(0,15,0,170) sizeBar.BackgroundColor3=Color3.new(.3,.3,.3)
local sizeKnob=Instance.new("Frame",sizeBar) sizeKnob.Size=UDim2.new(0,16,0,16) sizeKnob.Position=UDim2.new(0,0,0,-4) sizeKnob.BackgroundColor3=Color3.new(.8,.2,.2)
local hitboxSize=5

sizeKnob.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        local UIS=game:GetService("UserInputService")
        local conn
        conn=UIS.InputChanged:Connect(function(inp)
            if inp.Position then
                local px=math.clamp(inp.Position.X-sizeBar.AbsolutePosition.X,0,sizeBar.AbsoluteSize.X)
                hitboxSize=math.floor(5+(px/sizeBar.AbsoluteSize.X)*45)
                sizeKnob.Position=UDim2.new(px/sizeBar.AbsoluteSize.X,0,0,-4)
                sizeLbl.Text="Head Hitbox Size: "..hitboxSize
                updateAll()
            end
        end)
        local function endDrag(_)
            if conn then conn:Disconnect() end
        end
        UIS.InputEnded:Connect(endDrag)
    end
end)

-- Menu open/close
openBtn.MouseButton1Click:Connect(function() frame.Visible=true openBtn.Visible=false end)
closeBtn.MouseButton1Click:Connect(function() frame.Visible=false openBtn.Visible=true end)

-- ESP Drawing
local function drawBone(pchar)
    for _,v in pairs(pchar:GetChildren()) do
        if v:IsA("BasePart") then
            local b=Instance.new("BoxHandleAdornment",v)
            b.Size=v.Size
            b.Color3=Color3.new(0,1,1)
            b.Transparency=.7 b.AlwaysOnTop=true b.ZIndex=10
        end
    end
end
local function removeBone(pchar)
    for _,v in pairs(pchar:GetDescendants()) do
        if v:IsA("BoxHandleAdornment") then v:Destroy() end
    end
end

local function clearESP(pchar)
    for _,v in pairs(pchar:GetChildren()) do
        if v:IsA("BillboardGui") and v.Name:match("^ESP") then v:Destroy() end
        if v:IsA("Beam") and v.Name=="ESPLINE" then v:Destroy() end
    end
    removeBone(pchar)
end

local function drawESP(plr)
    if plr==game.Players.LocalPlayer or not plr.Character then return end
    local pchar=plr.Character
    clearESP(pchar)
    local head=pchar:FindFirstChild("Head")
    local root=pchar:FindFirstChild("HumanoidRootPart") or pchar:FindFirstChildWhichIsA("BasePart")
    if head then
        -- Head hitbox
        head.Size=Vector3.new(hitboxSize,hitboxSize,hitboxSize)
        head.Transparency=0.6
        head.Color=Color3.new(.8,.1,.1)
        head.Material=Enum.Material.Neon
        -- Name ESP
        if toggles.Name then
            local esp=Instance.new("BillboardGui",head)
            esp.Name="ESPName"
            esp.Size=UDim2.new(4,0,.7,0)
            esp.AlwaysOnTop=true
            local tl=Instance.new("TextLabel",esp)
            tl.Size=UDim2.new(1,0,1,0)
            tl.BackgroundTransparency=1
            tl.Text=customName~="" and customName or plr.Name
            tl.TextColor3=Color3.new(1,1,0)
            tl.TextScaled=true
        end
        -- Line ESP
        if toggles.Line and root and head~=root then
            local beam=Instance.new("Beam",head)
            beam.Name="ESPLINE"
            local a0=Instance.new("Attachment",root)
            local a1=Instance.new("Attachment",head)
            beam.Attachment0=a0 beam.Attachment1=a1
            beam.Color=ColorSequence.new(Color3.new(1,0,0))
            beam.Width0=0.15 beam.Width1=0.15 beam.FaceCamera=true
            beam.Transparency=NumberSequence.new(.2)
        end
        -- Bone ESP
        if toggles.Bone then
            drawBone(pchar)
        end
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
for _,plr in ipairs(game.Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function() drawESP(plr) end)
end

updateAll()
print("Universal Hitblox ESP menu loaded!")
