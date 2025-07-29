--[[
    Title: Enchant Reroller (Fluent Edition)
    Description: A full-featured pet enchant reroller built with the Fluent UI library.
]]

--// =================================================================================
--// Part 1: Setup & Services
--// =================================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

local rerolling = false

--// =================================================================================
--// Part 2: Fluent UI Initialization
--// =================================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "v2.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 550),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10222013164" })
local PetSection = MainTab:AddSection("Pet Selection")
local SettingsSection = MainTab:AddSection("Settings & Control")

--// =================================================================================
--// Part 3: UI Element Definitions
--// =================================================================================

-- Pet Selection UI
local petDataMap = {} 
local PetDropdown = PetSection:AddDropdown("PetDropdown", {
    Title = "Select Pets",
    Values = {},
    MultiSelect = true,
    Text = "Click Refresh Pet List below...",
})
PetSection:AddButton({
    Title = "🔄 Refresh Pet List",
    Callback = function()
        updatePetList()
    end,
})

-- Settings & Control UI
local availableEnchants = {
    "Secret Hunter", "Determination", "Ultra Roller", "Shiny Seeker", "Magnetism", 
    "Infinity", "High Roller", "Team Up I", "Team up II", "Team up III", 
    "Team Up IV", "Team Up V", "Looter I", "Looter II", "Looter III", "Looter IV", 
    "Looter V", "Gleaming I", "Gleaming II", "Gleaming III", "Bubbler I", 
    "Bubbler II", "Bubbler III", "Bubbler IV", "Bubbler V"
}
local EnchantDropdown = SettingsSection:AddDropdown("EnchantDropdown", {
    Title = "Desired Enchant(s)",
    Values = availableEnchants,
    MultiSelect = true,
    Text = "Click to select enchants...",
})

-- CORRECTED LINE: AddTextBox with a capital 'B'
SettingsSection:AddTextBox("EnchantLevel", {
    Title = "Enchant Level",
    PlaceholderText = "e.g., 9",
    Default = "",
})

local StatusLabel = SettingsSection:AddLabel({ Text = "Status: Waiting..." })
local EnchantToggle 

--// =================================================================================
--// Part 4: Core Logic & Functions
--// =================================================================================

local function hasDesiredEnchant(pet, targetEnchants, enchantLevel)
    for _, desiredId in pairs(targetEnchants) do
        for _, petEnchant in pairs(pet.Enchants or {}) do
            if string.lower(petEnchant.Id) == string.lower(desiredId) and petEnchant.Level == tonumber(enchantLevel) then
                return true
            end
        end
    end
    return false
end

function updatePetList()
    local petsForDropdown = {}
    petDataMap = {}
    local data = LocalData:Get()
    if not (data and data.Pets) then return end

    for _, pet in pairs(data.Pets) do
        local displayName = string.format("%s [%s]", (pet.Name or "Unknown"), tostring(pet.Id):sub(1, 5))
        table.insert(petsForDropdown, displayName)
        petDataMap[displayName] = pet.Id
    end
    
    PetDropdown:SetValues(petsForDropdown)
    if #petsForDropdown > 0 then
        Fluent:Notify({ Title = "Success", Content = "Found " .. #petsForDropdown .. " pets.", Duration = 4 })
    end
end

local function startRerollProcess()
    local targetEnchants = Fluent.Options.EnchantDropdown.Value
    local targetLevel = tonumber(Fluent.Options.EnchantLevel.Value)
    local rerollQueue = {}
    
    local selectedPetIds = {}
    for _, displayName in pairs(Fluent.Options.PetDropdown.Value) do
        if petDataMap[displayName] then table.insert(selectedPetIds, petDataMap[displayName]) end
    end
    
    if #selectedPetIds == 0 or #targetEnchants == 0 or not targetLevel then
        StatusLabel:SetText("⚠️ Select pets, enchants, and a level.")
        EnchantToggle:Set({ Value = false, Silent = true })
        EnchantToggle:SetText("Start Enchanting")
        return
    end
    
    rerolling = true
    StatusLabel:SetText("⏳ Initializing...")
    
    coroutine.wrap(function()
        local allPets = LocalData:Get().Pets or {}
        for _, petId in pairs(selectedPetIds) do
            local pet
            for _, p in pairs(allPets) do
                if p.Id == petId then pet = p; break end
            end
            if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                table.insert(rerollQueue, petId)
            end
        end

        while rerolling do
            if #rerollQueue > 0 then
                local currentPetId = table.remove(rerollQueue, 1)
                StatusLabel:SetText("🔁 Rerolling pet ID: " .. tostring(currentPetId):sub(1, 8))
                RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")
                
                local pet
                for _, p in pairs(LocalData:Get().Pets or {}) do if p.Id == currentPetId then pet = p; break end end
                if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                    table.insert(rerollQueue, currentPetId)
                end
            else
                StatusLabel:SetText("✅ Pets have desired enchants. Monitoring...")
                task.wait(2.0)
                
                for _, petId in pairs(selectedPetIds) do
                    local pet
                    for _, p in pairs(LocalData:Get().Pets or {}) do if p.Id == petId then pet = p; break end end
                    if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                        StatusLabel:SetText("⚠️ Pet " .. pet.Name .. " lost enchant. Re-queuing...")
                        table.insert(rerollQueue, pet.Id)
                    end
                end
            end
            task.wait(0.4)
        end
    end)()
end

local function stopRerollProcess()
    rerolling = false
    StatusLabel:SetText("⏹️ Reroll stopped by user.")
end

--// =================================================================================
--// Part 5: Final UI Connections
--// =================================================================================

EnchantToggle = SettingsSection:AddToggle("EnchantToggle", {
    Text = "Start Enchanting",
    Default = false,
    Callback = function(toggledOn)
        if toggledOn then
            EnchantToggle:SetText("Stop Enchanting")
            startRerollProcess()
        else
            EnchantToggle:SetText("Start Enchanting")
            stopRerollProcess()
        end
    end,
})

task.wait(2)
updatePetList()
