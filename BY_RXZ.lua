-- ============================================================
-- BY RXZ
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local keybindFile = "BY_RXZ_Keybind.txt"

-- ==================== SETTINGS ====================
local AntiLoggerEnabled = false
local isMinimized = false

local CurrentKeybind = Enum.KeyCode.G
local WaitingForKeybind = false

-- ==================== COLORS ====================
local WHITE        = Color3.fromRGB(255, 255, 255)
local MAIN_TEXT    = Color3.fromRGB(255, 255, 255)
local MUTED_TEXT   = Color3.fromRGB(190, 190, 190)
local STATUS_GREEN = Color3.fromRGB(255, 255, 255)
local STATUS_RED   = Color3.fromRGB(120, 120, 120)
local GLASS_COLOR  = Color3.fromRGB(0, 0, 0)

local function loadKeybind()
    if isfile and isfile(keybindFile) then
        local ok, data = pcall(function() return readfile(keybindFile) end)
        if ok and data then
            for _, enum in ipairs(Enum.KeyCode:GetEnumItems()) do
                if enum.Name == data then CurrentKeybind = enum break end
            end
        end
    end
end

local function saveKeybind()
    if writefile then
        pcall(function() writefile(keybindFile, CurrentKeybind.Name) end)
    end
end

loadKeybind()

-- ==================== ANTI LOGGER CORE ====================
local function runAntiLogger()
    if not game:IsLoaded() then game.Loaded:Wait() end

    local cloneref = cloneref or function(o) return o end
    local getupvalues = (debug and debug.getupvalues) or getupvalues
    local getprotos = (debug and debug.getprotos) or getprotos
    if not getupvalues then return false, "NOT SUPPORTED" end

    local RS = cloneref(game:GetService("ReplicatedStorage"))
    local okNet, netFolder = pcall(function()
        return RS:WaitForChild("Packages", 10):WaitForChild("Net", 10)
    end)
    if not okNet or not netFolder then return false, "NET NOT FOUND" end

    local okMod, ctrl = pcall(function()
        return require(RS:WaitForChild("Controllers", 10):WaitForChild("TradeController", 10))
    end)
    if not okMod or type(ctrl) ~= "table" then return false, "NO CONTROLLER" end

    local remotes = {}
    do
        local seenFn, seenInst = {}, {}
        local function walk(fn)
            if type(fn) ~= "function" or seenFn[fn] then return end
            seenFn[fn] = true
            local ok, ups = pcall(getupvalues, fn)
            if ok and ups then
                for _, v in pairs(ups) do
                    if typeof(v) == "Instance" and v.Parent == netFolder
                        and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                        if not seenInst[v] then
                            seenInst[v] = true
                            remotes[#remotes + 1] = v
                        end
                    elseif type(v) == "function" then
                        walk(v)
                    end
                end
            end
            if getprotos then
                local ok2, ps = pcall(getprotos, fn)
                if ok2 and ps then for _, p in ipairs(ps) do walk(p) end end
            end
        end
        for _, fn in pairs(ctrl) do walk(fn) end
    end

    for _, r in ipairs(remotes) do
        pcall(function() r:Destroy() end)
    end

    return true, #remotes .. " REMOTES"
end

-- ==================== MAIN UI ====================
pcall(function()
    for _, old in ipairs(lp:WaitForChild("PlayerGui"):GetChildren()) do
        if old.Name == "BY_RXZ" then old:Destroy() end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BY_RXZ"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.IgnoreGuiInset = true
gui.Parent = lp:WaitForChild("PlayerGui")

local PW, PH = 240, 148
local MINI_H = 40

local dp = Instance.new("ImageLabel", gui)
dp.Name = "MainFrame"
dp.Size = UDim2.new(0, PW, 0, PH)
dp.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
dp.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dp.Image = "rbxassetid://132826602147402"
dp.ImageTransparency = 0.35
dp.ScaleType = Enum.ScaleType.Crop
dp.Active = true
dp.ClipsDescendants = true
Instance.new("UICorner", dp).CornerRadius = UDim.new(0, 14)
local dpSt = Instance.new("UIStroke", dp)
dpSt.Color = WHITE
dpSt.Thickness = 1.6

-- Drag
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

-- Header
local header = Instance.new("Frame", dp)
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundTransparency = 1

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -44, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BY RXZ"
titleLbl.TextColor3 = MAIN_TEXT
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -30, 0.5, -11)
minimizeBtn.BackgroundColor3 = GLASS_COLOR
minimizeBtn.BackgroundTransparency = 0.2
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = MAIN_TEXT
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 15
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)
local minStr = Instance.new("UIStroke", minimizeBtn)
minStr.Color = WHITE
minStr.Thickness = 1

-- Content
local content = Instance.new("Frame", dp)
content.Size = UDim2.new(1, -24, 1, -42)
content.Position = UDim2.new(0, 12, 0, 34)
content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)

local function createRow(height)
    local r = Instance.new("Frame", content)
    r.Size = UDim2.new(1, 0, 0, height or 30)
    r.BackgroundColor3 = GLASS_COLOR
    r.BackgroundTransparency = 0.25
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)
    local str = Instance.new("UIStroke", r)
    str.Color = WHITE
    str.Thickness = 1.2
    return r, str
end

-- Status
local statusRow = Instance.new("Frame", content)
statusRow.Size = UDim2.new(1, 0, 0, 16)
statusRow.BackgroundTransparency = 1
local statusTxt = Instance.new("TextLabel", statusRow)
statusTxt.Size = UDim2.new(1, 0, 1, 0)
statusTxt.BackgroundTransparency = 1
statusTxt.Text = "STATUS: OFF"
statusTxt.TextColor3 = STATUS_RED
statusTxt.Font = Enum.Font.GothamBlack
statusTxt.TextSize = 11
statusTxt.TextXAlignment = Enum.TextXAlignment.Left

-- Anti Logger button
local mainRow, toggleStroke = createRow(34)
local toggleBtn = Instance.new("TextButton", mainRow)
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = "ACTIVATE ANTI LOGGER"
toggleBtn.TextColor3 = MAIN_TEXT
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 11

-- Keybind row
local kbRow = createRow(28)
local kbLabel = Instance.new("TextLabel", kbRow)
kbLabel.Size = UDim2.new(0.5, 0, 1, 0)
kbLabel.Position = UDim2.new(0, 10, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Keybind"
kbLabel.Font = Enum.Font.GothamBold
kbLabel.TextSize = 11
kbLabel.TextColor3 = MAIN_TEXT
kbLabel.TextXAlignment = Enum.TextXAlignment.Left

local keybindBox = Instance.new("TextButton", kbRow)
keybindBox.Size = UDim2.new(0, 72, 0, 19)
keybindBox.Position = UDim2.new(1, -82, 0.5, -9.5)
keybindBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keybindBox.BackgroundTransparency = 0
keybindBox.Text = "[ " .. CurrentKeybind.Name .. " ]"
keybindBox.TextColor3 = WHITE
keybindBox.Font = Enum.Font.GothamBlack
keybindBox.TextSize = 10
Instance.new("UICorner", keybindBox).CornerRadius = UDim.new(0, 5)
local kbBoxStr = Instance.new("UIStroke", keybindBox)
kbBoxStr.Color = WHITE
kbBoxStr.Thickness = 1

-- ==================== MINIMIZE ====================
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local h = isMinimized and MINI_H or PH
    TweenService:Create(dp, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, PW, 0, h)}):Play()
    content.Visible = not isMinimized
    minimizeBtn.Text = isMinimized and "+" or "−"
end)

-- ==================== UI STATE ====================
local statusNote = nil

local function updateUI()
    if AntiLoggerEnabled then
        toggleStroke.Color = STATUS_GREEN
        toggleStroke.Thickness = 2
        toggleBtn.Text = "ANTI LOGGER ACTIVE"
        statusTxt.Text = "STATUS: ON" .. (statusNote and (" | " .. statusNote) or "")
        statusTxt.TextColor3 = STATUS_GREEN
    else
        toggleStroke.Color = WHITE
        toggleStroke.Thickness = 1.2
        toggleBtn.Text = "ACTIVATE ANTI LOGGER"
        statusTxt.Text = "STATUS: OFF" .. (statusNote and (" | " .. statusNote) or "")
        statusTxt.TextColor3 = STATUS_RED
    end
    keybindBox.Text = WaitingForKeybind and "[ ... ]" or "[ " .. CurrentKeybind.Name .. " ]"
end

local busy = false
local function activateAntiLogger()
    if busy or AntiLoggerEnabled then return end
    busy = true
    toggleBtn.Text = "LOADING..."
    task.spawn(function()
        local ok, info = false, nil
        local success, a, b = pcall(runAntiLogger)
        if success then ok, info = a, b end
        AntiLoggerEnabled = ok and true or false
        statusNote = info
        busy = false
        updateUI()
    end)
end

toggleBtn.MouseButton1Click:Connect(activateAntiLogger)

keybindBox.MouseButton1Click:Connect(function()
    if WaitingForKeybind then return end
    WaitingForKeybind = true
    updateUI()
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if WaitingForKeybind then
        CurrentKeybind = inp.KeyCode
        WaitingForKeybind = false
        updateUI()
        saveKeybind()
    elseif inp.KeyCode == CurrentKeybind then
        activateAntiLogger()
    end
end)

updateUI()
