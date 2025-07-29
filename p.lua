local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

-- Window Setup
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Rerollerrrr",
    SubTitle = "Select Pets to reroll",
    TabWidth = 120,
    Size = UDim2.fromOffset(460, 540),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Reroller", Icon = "RefreshCcw" })
}

-- Elements
local selectedPetIds = {}
local rerolling = false
local rerollQueue = {}

local petDropdown = Tabs.Main:AddDropdown("Select Pets", {
    Multi = true,
    Search = true,
    Placeholder = "Search for pets...",
    Values = {}, -- to be populated dynamically
    Callback = function(selected)
        selectedPetIds = {}
        for _, petName in pairs(selected) do
            selectedPetIds[petName] = true
        end
    end
})

local enchantNameBox = Tabs.Main:AddInput("Enchant Name", {
    Placeholder = "Enter enchant name",
    Numeric = false,
    CharacterLimit = 30
})

local enchantLevelBox = Tabs.Main:AddInput("Enchant Level", {
    Placeholder = "Enter enchant level (number)",
    Numeric = true,
    CharacterLimit = 3
})

local statusLabel = Tabs.Main:AddParagraph("Status", "⏳ Waiting...")

-- Pet loading function
local function updatePetDropdown()
    local data = LocalData:Get()
    local petNames = {}

    for _, pet in pairs(data.Pets or {}) do
        local name = pet.Name or pet.name or pet._name or "Unknown"
        petNames[#petNames + 1] = name .. " [" .. pet.Id .. "]"
    end

    petDropdown:SetValues(petNames)
end

updatePetDropdown()

-- Helper
local function hasDesiredEnchant(pet, id, lvl)
    for _, enchant in pairs(pet.Enchants or {}) do
        if enchant.Id == id and enchant.Level == tonumber(lvl) then
            return true
        end
    end
    return false
end

local function enqueueRerolls(targetEnchant, targetLevel)
    for _, pet in pairs(LocalData:Get().Pets or {}) do
        if selectedPetIds[pet.Name .. " [" .. pet.Id .. "]"]
            and not hasDesiredEnchant(pet, targetEnchant, targetLevel) then
            table.insert(rerollQueue, pet.Id)
        end
    end
end

-- Buttons
Tabs.Main:AddButton({
    Title = "▶ Start Reroll",
    Description = "Begin enchant rerolling",
    Callback = function()
        local targetEnchant = enchantNameBox.Value:lower()
        local targetLevel = tonumber(enchantLevelBox.Value)

        if not next(selectedPetIds) then
            statusLabel:Set("⚠️ Select at least one pet.")
            return
        end
        if not targetEnchant or not targetLevel then
            statusLabel:Set("⚠️ Invalid enchant or level.")
            return
        end

        rerolling = true
        rerollQueue = {}
        enqueueRerolls(targetEnchant, targetLevel)
        statusLabel:Set("🔁 Starting reroll...")

        task.spawn(function()
            while rerolling and #rerollQueue > 0 do
                local petId = table.remove(rerollQueue, 1)
                while rerolling do
                    local petData = LocalData:Get().Pets or {}
                    local currentPet = nil
                    for _, p in ipairs(petData) do
                        if p.Id == petId then currentPet = p break end
                    end
                    if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                        RemoteFunction:InvokeServer("RerollEnchants", petId, "Gems")
                        statusLabel:Set("🔁 Rerolling " .. (currentPet.Name or petId))
                    else
                        statusLabel:Set("✅ " .. (currentPet and currentPet.Name or petId) .. " is good.")
                        break
                    end
                    task.wait(0.3)
                end
                task.wait(0.5)
            end

            statusLabel:Set("✅ All selected pets have desired enchant. Monitoring...")

            while rerolling do
                local petData = LocalData:Get().Pets or {}
                for _, pet in ipairs(petData) do
                    if selectedPetIds[pet.Name .. " [" .. pet.Id .. "]"]
                        and not hasDesiredEnchant(pet, targetEnchant, targetLevel) then
                        table.insert(rerollQueue, pet.Id)
                        statusLabel:Set("⚠️ " .. (pet.Name or pet.Id) .. " lost enchant. Re-queueing.")
                    end
                end

                while rerolling and #rerollQueue > 0 do
                    local petId = table.remove(rerollQueue, 1)
                    while rerolling do
                        local currentPet = nil
                        for _, p in pairs(LocalData:Get().Pets or {}) do
                            if p.Id == petId then currentPet = p break end
                        end

                        if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                            RemoteFunction:InvokeServer("RerollEnchants", petId, "Gems")
                            statusLabel:Set("🔁 Rerolling " .. (currentPet.Name or petId))
                        else
                            statusLabel:Set("✅ " .. (currentPet and currentPet.Name or petId) .. " good.")
                            break
                        end
                        task.wait(0.3)
                    end
                end

                task.wait(2.0)
            end

            statusLabel:Set("⏹️ Reroll stopped.")
        end)
    end
})

Tabs.Main:AddButton({
    Title = "■ Stop Reroll",
    Description = "Stop enchant rerolling",
    Callback = function()
        rerolling = false
        statusLabel:Set("⏹️ Reroll manually stopped.")
    end
})
