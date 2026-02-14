-- Services  
local Players = game:GetService("Players")  
local RunService = game:GetService("RunService")  
local Workspace = game:GetService("Workspace")  
local VirtualUser = game:GetService("VirtualUser")  
  
-- Player and Teams  
local player = Players.LocalPlayer  
local RUNNER_TEAM = "Runners"  
local BANANA_TEAM = "Banana"  
local MONEY_NAME = "Token"  
  
-- Variables  
local isScriptActive = false  
local currentMode = "None"  
local hasEscaped = false  
local roundStarted = false  
local myPlatform = nil  
local magnetConnection = nil  
local gameClock = nil  
local lastMagnet = 0  
  
-- GUI Colors  
local COLORS = {  
darkBG = Color3.fromRGB(26, 26, 26),  
strokeGray = Color3.fromRGB(58, 58, 58),  
white = Color3.fromRGB(255, 255, 255),  
greenNeon = Color3.fromRGB(0, 255, 102),  
redDark = Color3.fromRGB(139, 0, 0),  
yellow = Color3.fromRGB(255,255,0),  
cyan = Color3.fromRGB(0,255,255),  
gray = Color3.fromRGB(180,180,180)  
}  
  
-- GUI Setup  
local screenGui = Instance.new("ScreenGui")  
screenGui.Name = "BananaFarmGUI"  
screenGui.ResetOnSpawn = false  
screenGui.Parent = player:WaitForChild("PlayerGui")  
  
local mainFrame = Instance.new("Frame")  
mainFrame.Size = UDim2.new(0, 260, 0, 160)  
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -80)  
mainFrame.BackgroundColor3 = COLORS.darkBG  
mainFrame.BorderSizePixel = 0  
mainFrame.Active = true  
mainFrame.Draggable = true  
mainFrame.Parent = screenGui  
  
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,10)  
  
local stroke = Instance.new("UIStroke")  
stroke.Color = COLORS.strokeGray  
stroke.Thickness = 1.5  
stroke.Parent = mainFrame  
  
local title = Instance.new("TextLabel")  
title.Size = UDim2.new(1, -20, 0, 28)  
title.Position = UDim2.new(0, 10, 0, 6)  
title.BackgroundTransparency = 1  
title.Text = "BANANA EATS FARM V2"  
title.Font = Enum.Font.GothamBold  
title.TextColor3 = COLORS.white  
title.TextSize = 18  
title.TextXAlignment = Enum.TextXAlignment.Left  
title.Parent = mainFrame  
  
local separator = Instance.new("Frame")  
separator.Size = UDim2.new(1, -20, 0, 2)  
separator.Position = UDim2.new(0, 10, 0, 34)  
separator.BackgroundColor3 = COLORS.strokeGray  
separator.BorderSizePixel = 0  
separator.Parent = mainFrame  
  
local statusLabel = Instance.new("TextLabel")  
statusLabel.Size = UDim2.new(1, -20, 0, 24)  
statusLabel.Position = UDim2.new(0, 10, 0, 40)  
statusLabel.BackgroundTransparency = 1  
statusLabel.Text = "Status: OFF"  
statusLabel.Font = Enum.Font.GothamBold  
statusLabel.TextColor3 = COLORS.white  
statusLabel.TextSize = 14  
statusLabel.TextXAlignment = Enum.TextXAlignment.Left  
statusLabel.Parent = mainFrame  
  
local toggleBtn = Instance.new("TextButton")  
toggleBtn.Size = UDim2.new(0, 110, 0, 38)  
toggleBtn.Position = UDim2.new(0, 10, 1, -50)  
toggleBtn.BackgroundColor3 = COLORS.greenNeon  
toggleBtn.Text = "Start"  
toggleBtn.Font = Enum.Font.GothamBold  
toggleBtn.TextColor3 = COLORS.white  
toggleBtn.TextSize = 18  
toggleBtn.Parent = mainFrame  
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)  
  
local hideBtn = Instance.new("TextButton")  
hideBtn.Size = UDim2.new(0, 110, 0, 28)  
hideBtn.Position = UDim2.new(1, -120, 1, -45)  
hideBtn.BackgroundColor3 = COLORS.strokeGray  
hideBtn.Text = "Hide UI"  
hideBtn.Font = Enum.Font.GothamBold  
hideBtn.TextColor3 = COLORS.white  
hideBtn.TextSize = 14  
hideBtn.Parent = mainFrame  
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0,8)  
  
-- Hide/Show UI  
local uiVisible = true  
hideBtn.MouseButton1Click:Connect(function()  
uiVisible = not uiVisible  
mainFrame.Visible = uiVisible  
hideBtn.Text = uiVisible and "Hide UI" or "Show UI"  
end)  
  
-- Anti AFK  
player.Idled:Connect(function()  
if isScriptActive then  
VirtualUser:CaptureController()  
VirtualUser:ClickButton2(Vector2.new())  
end  
end)  
  
-- Status Update  
local function UpdateStatus()  
if not isScriptActive then  
statusLabel.Text = "Status: Off"  
statusLabel.TextColor3 = Color3.fromRGB(255,255,255)  
return  
end  
  
if currentMode == "Lobby" then      
    statusLabel.Text = "Status: Lobby (Waiting…)"      
    statusLabel.TextColor3 = Color3.fromRGB(200,200,200)      
    return      
end      
  
if currentMode == "Banana" then      
    statusLabel.Text = "Status: Banana (Resetting…)"      
    statusLabel.TextColor3 = Color3.fromRGB(255,120,0)      
    return      
end      
  
if currentMode == "Runner" then      
    if hasEscaped then      
        statusLabel.Text = "Status: Escaped"    
        statusLabel.TextColor3 = Color3.fromRGB(0,255,255)      
    elseif roundStarted and gameClock and gameClock.Value <= 60 then      
        statusLabel.Text = "Status: Escaping…"    
        statusLabel.TextColor3 = Color3.fromRGB(255,255,0)      
    else      
        statusLabel.Text = "Status: Runner (Farming)"    
        statusLabel.TextColor3 = Color3.fromRGB(0,255,0)      
    end      
end  
  
end  
  
-- Cleanup  
local function CleanUp()  
if magnetConnection then  
magnetConnection:Disconnect()  
magnetConnection = nil  
end  
  
if myPlatform then    
    myPlatform:Destroy()    
    myPlatform = nil    
end    
  
local char = player.Character    
if char then    
    local hum = char:FindFirstChildOfClass("Humanoid")    
    if hum then    
        hum.PlatformStand = false    
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)    
    end    
end    
  
hasEscaped = false    
roundStarted = false    
UpdateStatus()  
  
end  
  
-- Closest exit  
local function getClosestExit()  
local gk = Workspace:FindFirstChild("GameKeeper")  
if not gk then return nil end  
local exits = gk:FindFirstChild("Exits")  
if not exits then return nil end  
  
local char = player.Character    
if not char then return nil end    
local root = char:FindFirstChild("HumanoidRootPart")    
if not root then return nil end    
  
local closest, dist = nil, math.huge    
for _, v in pairs(exits:GetChildren()) do    
    if v.Name == "EscapeDoor" then    
        local part = v:FindFirstChild("Root") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")    
        if part then    
            local d = (root.Position - part.Position).Magnitude    
            if d < dist then    
                dist = d    
                closest = part    
            end    
        end    
    end    
end    
return closest  
  
end  
  
-- Runner Setup  
local function SetupRunner()  
CleanUp()  
hasEscaped = false  
task.wait(3)  
  
local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")    
if not root then return end    
  
-- Create platform    
myPlatform = Instance.new("Part")    
myPlatform.Size = Vector3.new(50,1,50)    
myPlatform.Anchored = true    
myPlatform.CanCollide = true    
myPlatform.Transparency = 0.6    
myPlatform.Material = Enum.Material.Plastic    
myPlatform.Color = Color3.fromRGB(180,180,180)    
myPlatform.CFrame = CFrame.new(root.Position + Vector3.new(0,60,0))    
myPlatform.Parent = Workspace    
  
-- Move player above platform    
task.spawn(function()    
    local start = tick()    
    while tick() - start < 1 do    
        root.CFrame = myPlatform.CFrame + Vector3.new(0,3,0)    
        root.AssemblyLinearVelocity = Vector3.zero    
        RunService.Heartbeat:Wait()    
    end    
end)    
  
local hum = player.Character:FindFirstChild("Humanoid")    
if hum then hum.PlatformStand = true end    
  
-- Start round after 7s    
task.delay(7, function()    
    if currentMode == "Runner" and isScriptActive then    
        roundStarted = true    
        UpdateStatus()    
    end    
end)    
  
-- Magnet loop (ottimizzato e controllabile)    
local tokensFolder = workspace:WaitForChild("GameKeeper"):WaitForChild("Map"):WaitForChild("Tokens")    
lastMagnet = 0    
  
if magnetConnection then    
    magnetConnection:Disconnect()    
    magnetConnection = nil    
end    
  
magnetConnection = RunService.Heartbeat:Connect(function()    
    if not isScriptActive or currentMode ~= "Runner" then return end    
    if tick() - lastMagnet < 0.4 then return end    
    lastMagnet = tick()    
  
    local char = player.Character    
    if not char then return end    
    local root = char:FindFirstChild("HumanoidRootPart")    
    if not root then return end    
  
for _, obj in ipairs(tokensFolder:GetChildren()) do  
    if obj:IsA("BasePart") and obj.Name == MONEY_NAME then  -- prende solo i token veri  
        obj.CanCollide = false  
obj.CFrame = root.CFrame + Vector3.new(0,2,0)  
    end  
end    
end)    
  
UpdateStatus()  
  
end  
  
-- Escape loop  
RunService.Heartbeat:Connect(function()  
if not isScriptActive or currentMode ~= "Runner" or not roundStarted or hasEscaped then return end  
if not gameClock then  
local gp = Workspace:FindFirstChild("GameProperties")  
if gp then gameClock = gp:FindFirstChild("GameClock") end  
end  
if not gameClock or gameClock.Value > 60 then return end  
  
UpdateStatus()    
local char = player.Character    
if not char then return end    
local root = char:FindFirstChild("HumanoidRootPart")    
if not root then return end    
  
local target = getClosestExit()    
if not target then return end    
  
-- Disable collisions temporarily    
local disabledParts = {}    
for _, v in pairs(char:GetDescendants()) do    
    if v:IsA("BasePart") then    
        if v.CanCollide == true then table.insert(disabledParts, v) end    
        v.CanCollide = false    
    end    
end    
task.delay(3, function()    
    for _, part in pairs(disabledParts) do    
        if part and part.Parent then    
            part.CanCollide = true    
        end    
    end    
end)    
  
-- Move toward exit    
task.spawn(function()    
    local start = tick()    
    while tick() - start < 55 and root.Parent do    
        root.CFrame = target.CFrame + Vector3.new(0,5,0)    
        root.AssemblyLinearVelocity = Vector3.zero    
        RunService.Heartbeat:Wait()    
    end    
    hasEscaped = true    
    UpdateStatus()    
end)  
  
end)  
  
-- Team change  
local function OnTeamChanged()  
if not isScriptActive then return end  
  
local teamName = player.Team and player.Team.Name or "None"    
  
if teamName == RUNNER_TEAM then    
    currentMode = "Runner"    
    SetupRunner()    
elseif teamName == BANANA_TEAM then    
    currentMode = "Banana"    
    CleanUp()    
    task.wait(0.5)    
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")    
    if hum then hum.Health = 0 end    
else    
    currentMode = "Lobby"    
    CleanUp()    
end    
  
UpdateStatus()  
  
end  
  
player:GetPropertyChangedSignal("Team"):Connect(OnTeamChanged)  
  
-- Toggle script  
toggleBtn.MouseButton1Click:Connect(function()  
isScriptActive = not isScriptActive  
if isScriptActive then  
toggleBtn.Text = "Stop"  
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)  
OnTeamChanged()  
else  
toggleBtn.Text = "Start"  
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,255,102)  
currentMode = "None"  
CleanUp()  
UpdateStatus()  
end  
end)  
  
player.CharacterAdded:Connect(function()  
if isScriptActive then  
task.delay(0.5, OnTeamChanged)  
end  
end)
