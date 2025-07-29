-- Main GUI Script (put in LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

-- GUI Setup
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "EnchantRerollerGUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 440, 0, 600)
mainFrame.Position = UDim2.new(0.5, -220, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 8)

-- Drag to move
mainFrame.Active = true
mainFrame.Draggable = true

-- Title
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "🔁 Enchant Reroller"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

-- Search Box
local searchBox = Instance.new("TextBox", mainFrame)
searchBox.PlaceholderText = "Search Pet Name..."
searchBox.Size = UDim2.new(1, -20, 0, 28)
searchBox.Position = UDim2.new(0, 10, 0, 40)
searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.Font = Enum.Font.Gotham

-- Dropdown toggle button
local dropdownButton = Instance.new("TextButton", mainFrame)
dropdownButton.Size = UDim2.new(1, -20, 0, 30)
dropdownButton.Position = UDim2.new(0, 10, 0, 75)
dropdownButton.Text = "▼ Select Pets"
dropdownButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdownButton.TextColor3 = Color3.new(1, 1, 1)
dropdownButton.Font = Enum.Font.Gotham

-- Scrollable dropdown
local dropdownFrame = Instance.new("ScrollingFrame", mainFrame)
dropdownFrame.Position = UDim2.new(0, 10, 0, 110)
dropdownFrame.Size = UDim2.new(1, -20, 0, 180)
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownFrame.ScrollBarThickness = 6
dropdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdownFrame.Visible = false
dropdownFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

dropdownButton.MouseButton2Click:Connect(function()
    dropdownFrame.Visible = false
end)

local uiListLayout = Instance.new("UIListLayout", dropdownFrame)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 4)

local selectedPetIds = {}
local petButtons = {}

-- Dropdown toggle
dropdownButton.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

-- Populate dropdown
local function updatePetList(filterText)
    for _, btn in pairs(petButtons) do btn:Destroy() end
    table.clear(petButtons)

    local data = LocalData:Get()
    for _, pet in pairs(data.Pets or {}) do
        local petName = pet.Name or pet.name or pet._name or "Unknown"
        local petId = pet.Id
        if filterText == "" or string.find(string.lower(petName), string.lower(filterText)) then
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -10, 0, 24)
            item.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            item.TextColor3 = Color3.new(1, 1, 1)
            item.Font = Enum.Font.Gotham
            item.TextSize = 14
            item.Text = petName .. " [" .. petId .. "]"
            item.Parent = dropdownFrame
            petButtons[#petButtons + 1] = item

            item.MouseButton1Click:Connect(function()
                if selectedPetIds[petId] then
                    selectedPetIds[petId] = nil
                    item.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                else
                    selectedPetIds[petId] = true
                    item.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
                end
            end)
        end
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePetList(searchBox.Text)
end)

updatePetList("")

-- Enchant Name
local enchantBox = Instance.new("TextBox", mainFrame)
enchantBox.PlaceholderText = "Enter Enchant Name"
enchantBox.Size = UDim2.new(1, -20, 0, 30)
enchantBox.Position = UDim2.new(0, 10, 0, 310)
enchantBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
enchantBox.TextColor3 = Color3.new(1, 1, 1)
enchantBox.Font = Enum.Font.Gotham

-- Enchant Level
local levelBox = Instance.new("TextBox", mainFrame)
levelBox.PlaceholderText = "Enter Enchant Level"
levelBox.Size = UDim2.new(1, -20, 0, 30)
levelBox.Position = UDim2.new(0, 10, 0, 350)
levelBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
levelBox.TextColor3 = Color3.new(1, 1, 1)
levelBox.Font = Enum.Font.Gotham
levelBox.Text = ""

-- Status Label
local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 390)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Text = "Status: Waiting..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextWrapped = true

-- Start Button
local startButton = Instance.new("TextButton", mainFrame)
startButton.Text = "▶ Start"
startButton.Size = UDim2.new(0.48, -5, 0, 30)
startButton.Position = UDim2.new(0.02, 0, 0, 440)
startButton.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Font = Enum.Font.GothamBold

-- Stop Button
local stopButton = Instance.new("TextButton", mainFrame)
stopButton.Text = "■ Stop"
stopButton.Size = UDim2.new(0.48, -5, 0, 30)
stopButton.Position = UDim2.new(0.5, 5, 0, 440)
stopButton.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.Font = Enum.Font.GothamBold

startButton.Parent = mainFrame
stopButton.Parent = mainFrame

local rerolling = false
local rerollQueue = {}

local function hasDesiredEnchant(pet, id, lvl)
    for _, enchant in pairs(pet.Enchants or {}) do
        if enchant.Id == id and enchant.Level == tonumber(lvl) then
            return true
        end
    end
    return false
end

local function enqueueRerolls(targetEnchant, targetLevel)
    local playerData = LocalData:Get()
    for _, pet in pairs(playerData.Pets or {}) do
        if selectedPetIds[pet.Id] and not hasDesiredEnchant(pet, targetEnchant, targetLevel) then
            table.insert(rerollQueue, pet.Id)
        end
    end
end

startButton.MouseButton1Click:Connect(function()
    local targetEnchant = enchantBox.Text:lower()
    local targetLevel = tonumber(levelBox.Text)
    if not next(selectedPetIds) then
        statusLabel.Text = "⚠️ Select at least one pet."
        return
    end
    if not targetEnchant or not targetLevel then
        statusLabel.Text = "⚠️ Enter valid enchant and level."
        return
    end

    rerolling = true
    rerollQueue = {}
    statusLabel.Text = "⏳ Starting reroll..."
    enqueueRerolls(targetEnchant, targetLevel)

    coroutine.wrap(function()
        while rerolling and #rerollQueue > 0 do
            local currentPetId = table.remove(rerollQueue, 1)

            while rerolling do
                local playerData = LocalData:Get()
                local currentPet
                for _, p in pairs(playerData.Pets or {}) do
                    if p.Id == currentPetId then
                        currentPet = p
                        break
                    end
                end

                if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                    RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")
                    statusLabel.Text = "🔁 Rerolling " .. (currentPet.Name or currentPetId)
                else
                    statusLabel.Text = "✅ " .. (currentPet and currentPet.Name or currentPetId) .. " has desired enchant."
                    break
                end
                task.wait(0.3)
            end
            enqueueRerolls(targetEnchant, targetLevel)
            task.wait(0.5)
        end

        statusLabel.Text = "✅ All selected pets have desired enchant. Monitoring for changes..."

        while rerolling do
            local playerData = LocalData:Get()
            local anyChanged = false

            for _, pet in pairs(playerData.Pets or {}) do
                if selectedPetIds[pet.Id] and not hasDesiredEnchant(pet, targetEnchant, targetLevel) then
                    table.insert(rerollQueue, pet.Id)
                    anyChanged = true
                    statusLabel.Text = "⚠️ " .. (pet.Name or pet.Id) .. " lost desired enchant. Re-queuing..."
                end
            end

            while rerolling and #rerollQueue > 0 do
                local currentPetId = table.remove(rerollQueue, 1)

                while rerolling do
                    local currentPet
                    for _, p in pairs(LocalData:Get().Pets or {}) do
                        if p.Id == currentPetId then
                            currentPet = p
                            break
                        end
                    end

                    if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                        RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")
                        statusLabel.Text = "🔁 Rerolling " .. (currentPet.Name or currentPetId)
                    else
                        statusLabel.Text = "✅ " .. (currentPet and currentPet.Name or currentPetId) .. " has desired enchant."
                        break
                    end

                    task.wait(0.3)
                end
            end

            task.wait(2.0)
        end

        statusLabel.Text = "⏹️ Reroll stopped."
    end)()
end)

stopButton.MouseButton1Click:Connect(function()
    rerolling = false
    statusLabel.Text = "⏹️ Reroll stopped."
end)
