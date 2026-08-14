-- ============================================================
-- RXZ ANTI BAT (ON / OFF Status Minimal UI)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- File saving for keybind persistence
local keybindFile = "RXZAntiBat_Keybind.txt"

-- Variables
local AntiBatEnabled = false
local InfiniteJumpEnabled = false     -- Opțiunea Normală

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local AntiBatConn = nil
local AntiRagdollConn = nil
local isMinimized = false

-- Keybinds
local CurrentKeybind = Enum.KeyCode.K
local WaitingForKeybind = false

-- ============================================================
-- PALETĂ MODIFICATĂ – ACCENT BLEU NÉON
-- ============================================================
local NEON_BLUE     = Color3.fromRGB(0, 160, 255)         -- Bleu néon vif
local MAIN_TEXT     = Color3.fromRGB(255, 255, 255)       -- Alb pur
local MUTED_TEXT    = Color3.fromRGB(210, 225, 245)       -- Text secundar deschis
local STATUS_GREEN  = Color3.fromRGB(0, 255, 140)         -- Verde neon activ
local STATUS_RED    = Color3.fromRGB(255, 70, 100)        -- Roșu neon inactiv
local GLASS_COLOR   = Color3.fromRGB(12, 8, 20)           -- Tenta de sticlă închisă

-- Load saved keybind
local function loadKeybind()
    if isfile and isfile(keybindFile) then
        local success, savedData = pcall(function()
            return readfile(keybindFile)
        end)
        if success and savedData then
            for _, enum in ipairs(Enum.KeyCode:GetEnumItems()) do
                if enum.Name == savedData then
                    CurrentKeybind = enum
                    break
                end
            end
        end
    end
end

local function saveKeybind()
    if writefile then
        pcall(function()
            writefile(keybindFile, CurrentKeybind.Name)
        end)
    end
end

loadKeybind()

-- ==================== ANTI BAT CORE ====================
local function startAntiBat()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if AntiBatConn then AntiBatConn:Disconnect() end
    AntiBatConn = RunService.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        root.Velocity = Vector3.new(1000, root.Velocity.Y, 1000)
        RunService.RenderStepped:Wait()
        root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)
    end)
end

local function stopAntiBat()
    if AntiBatConn then
        AntiBatConn:Disconnect()
        AntiBatConn = nil
    end
end

-- ==================== INFINITE JUMP LOGIC ====================
UserInputService.JumpRequest:Connect(function()
    if not InfiniteJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
    end
end)

-- ==================== ANTI RAGDOLL ====================
local function startAntiRagdoll()
    if AntiRagdollConn then return end
    AntiRagdollConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum2 then
            local st = hum2:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum2:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum2
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if AntiRagdollConn then
        AntiRagdollConn:Disconnect()
        AntiRagdollConn = nil
    end
end

-- Curățare UI vechi
pcall(function()
    for _, old in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
        if old.Name == "BananaHubAntiBat" or old.Name == "EternalHubAntiBat" or old.Name == "EthernalHubAntiBat" or old.Name == "RXZAntiBat" then
            old:Destroy()
        end
    end
end)

-- ==================== MAIN GLASS UI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "RXZAntiBat"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local PW, PH = 225, 200
local MINI_H = 44

local dp = Instance.new("ImageLabel", gui)
dp.Name = "MainFrame"
dp.Size = UDim2.new(0, PW, 0, PH)
dp.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
dp.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
dp.Image = "rbxassetid://132826602147402"
dp.ScaleType = Enum.ScaleType.Crop
dp.Active = true
dp.ClipsDescendants = true
Instance.new("UICorner", dp).CornerRadius = UDim.new(0, 16)

local dpSt = Instance.new("UIStroke", dp)
dpSt.Color = NEON_BLUE
dpSt.Thickness = 1.8

-- Drag System
local dragging, dragStart, startPos
dp.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = dp.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        dp.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- HEADER
local header = Instance.new("Frame", dp)
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundTransparency = 1

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "RXZ ANTI BAT"
titleLbl.TextColor3 = MAIN_TEXT
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -36, 0.5, -13)
minimizeBtn.BackgroundColor3 = GLASS_COLOR
minimizeBtn.BackgroundTransparency = 0.5
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = MAIN_TEXT
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)
local minStr = Instance.new("UIStroke", minimizeBtn)
minStr.Color = NEON_BLUE
minStr.Thickness = 1

-- CONTAINER PRINCIPAL ELEMENTE
local content = Instance.new("Frame", dp)
content.Size = UDim2.new(1, -32, 1, -56)
content.Position = UDim2.new(0, 16, 0, 44)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)

-- Generator de rânduri (accent bleu)
local function createVisibleRow(height)
    local r = Instance.new("Frame", content)
    r.Size = UDim2.new(1, 0, 0, height or 32)
    r.BackgroundColor3 = GLASS_COLOR
    r.BackgroundTransparency = 0.55
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)
    
    local str = Instance.new("UIStroke", r)
    str.Color = Color3.fromRGB(80, 150, 255)  -- Bleu pour les bordures
    str.Thickness = 1.2
    return r, str
end

-- 1. Status Simplu
local statusRow = Instance.new("Frame", content)
statusRow.Size = UDim2.new(1, 0, 0, 18)
statusRow.BackgroundTransparency = 1

local statusTxt = Instance.new("TextLabel", statusRow)
statusTxt.Size = UDim2.new(1, 0, 1, 0)
statusTxt.BackgroundTransparency = 1
statusTxt.Text = "STATUS: OFF"
statusTxt.TextColor3 = STATUS_RED
statusTxt.Font = Enum.Font.GothamBlack
statusTxt.TextSize = 12
statusTxt.TextXAlignment = Enum.TextXAlignment.Left

-- 2. Buton Principal Anti Bat
local mainRow, toggleBtnStroke = createVisibleRow(38)
local toggleBtn = Instance.new("TextButton", mainRow)
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = "ACTIVATE ANTI BAT"
toggleBtn.TextColor3 = MAIN_TEXT
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 11

-- 3. Rând Infinite Jump NORMAL
local jumpRowFrame, jumpStroke = createVisibleRow(32)

local jumpLabel = Instance.new("TextLabel", jumpRowFrame)
jumpLabel.Size = UDim2.new(0.6, 0, 1, 0)
jumpLabel.Position = UDim2.new(0, 12, 0, 0)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "Inf Jump (Normal)"
jumpLabel.TextColor3 = MAIN_TEXT
jumpLabel.Font = Enum.Font.GothamBold
jumpLabel.TextSize = 11
jumpLabel.TextXAlignment = Enum.TextXAlignment.Left

local jumpPill = Instance.new("Frame", jumpRowFrame)
jumpPill.Size = UDim2.new(0, 38, 0, 18)
jumpPill.Position = UDim2.new(1, -50, 0.5, -9)
jumpPill.BackgroundColor3 = Color3.fromRGB(5, 3, 10)
jumpPill.BackgroundTransparency = 0.3
Instance.new("UICorner", jumpPill).CornerRadius = UDim.new(0, 9)
local pillStroke = Instance.new("UIStroke", jumpPill)
pillStroke.Color = NEON_BLUE
pillStroke.Thickness = 1.2

local jumpDot = Instance.new("Frame", jumpPill)
jumpDot.Size = UDim2.new(0, 12, 0, 12)
jumpDot.Position = UDim2.new(0, 3, 0.5, -6)
jumpDot.BackgroundColor3 = MUTED_TEXT
Instance.new("UICorner", jumpDot).CornerRadius = UDim.new(0, 6)

local jumpToggleClick = Instance.new("TextButton", jumpRowFrame)
jumpToggleClick.Size = UDim2.new(1, 0, 1, 0)
jumpToggleClick.BackgroundTransparency = 1
jumpToggleClick.Text = ""

-- 4. Rând Keybind
local kbRowFrame, kbStroke = createVisibleRow(32)

local kbLabel = Instance.new("TextLabel", kbRowFrame)
kbLabel.Size = UDim2.new(0.5, 0, 1, 0)
kbLabel.Position = UDim2.new(0, 12, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Interaction Key"
kbLabel.Font = Enum.Font.GothamBold
kbLabel.TextSize = 11
kbLabel.TextColor3 = MAIN_TEXT
kbLabel.TextXAlignment = Enum.TextXAlignment.Left

local keybindBox = Instance.new("TextButton", kbRowFrame)
keybindBox.Size = UDim2.new(0, 75, 0, 20)
keybindBox.Position = UDim2.new(1, -87, 0.5, -10)
keybindBox.BackgroundColor3 = Color3.fromRGB(5, 3, 10)
keybindBox.BackgroundTransparency = 0.2
keybindBox.Text = "[ " .. CurrentKeybind.Name .. " ]"
keybindBox.TextColor3 = NEON_BLUE
keybindBox.Font = Enum.Font.GothamBlack
keybindBox.TextSize = 10
Instance.new("UICorner", keybindBox).CornerRadius = UDim.new(0, 5)
local kbBoxStr = Instance.new("UIStroke", keybindBox)
kbBoxStr.Color = NEON_BLUE
kbBoxStr.Thickness = 1

-- Footer text
local footer = Instance.new("TextLabel", content)
footer.Size = UDim2.new(1, 0, 0, 16)
footer.BackgroundTransparency = 1
footer.Text = "RXZ ANTI BAT"
footer.Font = Enum.Font.Code
footer.TextSize = 10
footer.TextColor3 = MUTED_TEXT

-- ==================== MINIMIZE SYSTEM ====================
local function toggleMinimize()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and MINI_H or PH
    TweenService:Create(dp, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, PW, 0, targetHeight)}):Play()
    content.Visible = not isMinimized
    minimizeBtn.Text = isMinimized and "+" or "−"
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

-- ==================== VISUAL GRAPHICS LOGIC ====================
local function setVisuals(dot, pillStr, enabled)
    TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = enabled and STATUS_GREEN or MUTED_TEXT
    }):Play()
    TweenService:Create(pillStr, TweenInfo.new(0.2), {
        Color = enabled and STATUS_GREEN or NEON_BLUE
    }):Play()
end

local function updateUI()
    if AntiBatEnabled then
        toggleBtnStroke.Color = STATUS_GREEN
        toggleBtn.Text = "DEACTIVATE ANTI BAT"
        statusTxt.Text = "STATUS: ON"
        statusTxt.TextColor3 = STATUS_GREEN
    else
        toggleBtnStroke.Color = NEON_BLUE
        toggleBtn.Text = "ACTIVATE ANTI BAT"
        statusTxt.Text = "STATUS: OFF"
        statusTxt.TextColor3 = STATUS_RED
    end
    keybindBox.Text = WaitingForKeybind and "[ ... ]" or "[ " .. CurrentKeybind.Name .. " ]"
end

-- ==================== CONNECTIONS ====================
toggleBtn.MouseButton1Click:Connect(function()
    AntiBatEnabled = not AntiBatEnabled
    if AntiBatEnabled then startAntiBat() else stopAntiBat() end
    updateUI()
    saveKeybind()
end)

-- Toggle Jump Normal
jumpToggleClick.MouseButton1Click:Connect(function()
    InfiniteJumpEnabled = not InfiniteJumpEnabled
    setVisuals(jumpDot, pillStroke, InfiniteJumpEnabled)
end)

keybindBox.MouseButton1Click:Connect(function()
    if WaitingForKeybind then return end
    WaitingForKeybind = true
    updateUI()
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if WaitingForKeybind and inp.UserInputType == Enum.UserInputType.Keyboard then
        CurrentKeybind = inp.KeyCode
        WaitingForKeybind = false
        updateUI()
        saveKeybind()
    elseif not WaitingForKeybind and inp.UserInputType == Enum.UserInputType.Keyboard then
        if inp.KeyCode == CurrentKeybind then
            AntiBatEnabled = not AntiBatEnabled
            if AntiBatEnabled then startAntiBat() else stopAntiBat() end
            updateUI()
            saveKeybind()
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    Humanoid = newChar:WaitForChild("Humanoid")
    if AntiBatEnabled then
        task.wait(0.3)
        startAntiBat()
    end
    task.wait(0.5)
    startAntiRagdoll()
end)

-- Init
startAntiRagdoll()
updateUI()
setVisuals(jumpDot, pillStroke, InfiniteJumpEnabled)

print("RXZ ANTI BAT - Loaded!")