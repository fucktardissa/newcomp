-- =================================================================================
--// DEBUG VERSION 1.0
-- =================================================================================
print("DEBUG: Script starting...")

--// Part 1: Setup & Services
print("DEBUG: Part 1 - Loading services and game modules...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
print("DEBUG: Part 1 - Complete.")

-- State Variables
local rerolling = false

--// Part 2: Fluent UI Initialization
print("DEBUG: Part 2 - Initializing Fluent UI...")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller (Debug)",
    SubTitle = "v2.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 550),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})
local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10222013164" })
local PetSection = MainTab:AddSection("Pet Selection")
local SettingsSection = MainTab:AddSection("Settings & Control")
print("DEBUG: Part 2 - Complete.")

--// Part 3: UI Element Definitions
print("DEBUG: Part 3 - Defining UI elements...")
local petDataMap = {} 
local PetDropdown = PetSection:AddDropdown("PetDropdown", {
    Title = "Select Pets", Values = {}, MultiSelect = true, Text = "Click Refresh Pet List below...",
})
PetSection:AddButton({
    Title = "🔄 Refresh Pet List",
    Callback = function()
        updatePetList()
    end,
})
print("DEBUG: Created Pet UI.")

local availableEnchants = {
    "Secret Hunter", "Determination", "Ultra Roller", "Shiny Seeker", "Magnetism", 
    "Infinity", "High Roller", "Team Up I", "Team up II", "Team up III", 
    "Team Up IV", "Team Up V", "Looter I", "Looter II", "Looter III", "Looter IV", 
    "Looter V", "Gleaming I", "Gleaming II", "Gleaming III", "Bubbler I", 
    "Bubbler II", "Bubbler III", "Bubbler IV", "Bubbler V"
}
local EnchantDropdown = SettingsSection:AddDropdown("EnchantDropdown", {
    Title = "Desired Enchant(s)", Values = availableEnchants, MultiSelect = true, Text = "Click to select enchants...",
})
print("DEBUG: Created Enchant Dropdown.")

SettingsSection:AddTextbox("EnchantLevel", {
    Title = "Enchant Level", PlaceholderText = "e.g., 9", Default = "",
})
print("DEBUG: Created Level Textbox.")

local StatusLabel = SettingsSection:AddLabel({ Text = "Status: Waiting..." })
print("DEBUG: Created Status Label.")

local EnchantToggle -- Forward-declare
print("DEBUG: Part 3 - Complete.")

--// Part 4: Core Logic & Functions
print("DEBUG: Part 4 - Defining functions...")

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
    print("DEBUG: updatePetList() called.")
    local petsForDropdown = {}
    petDataMap = {}
    
    print("DEBUG: Calling LocalData:Get()...")
    local data = LocalData:Get()
    print("DEBUG: LocalData:Get() returned:", data) -- This will tell us if 'data' is nil

    if data and data.Pets then
        print("DEBUG: 'data.Pets' found. Iterating through pets...")
        for _, pet in pairs(data.Pets) do
            local displayName = string.format("%s [%s]", (pet.Name or "Unknown"), tostring(pet.Id):sub(1, 5))
            table.insert(petsForDropdown, displayName)
            petDataMap[displayName] = pet.Id
        end
        print("DEBUG: Finished iterating. Found", #petsForDropdown, "pets.")
    else
        print("DEBUG: 'data' was nil or 'data.Pets' was not found!")
    end
    
    PetDropdown:SetValues(petsForDropdown)
    if #petsForDropdown > 0 then
        Fluent:Notify({ Title = "Success", Content = "Found " .. #petsForDropdown .. " pets.", Duration = 4 })
    else
        Fluent:Notify({ Title = "Debug Info", Content = "Pet list is empty. Check console for details.", Duration = 8 })
    end
end

local function startRerollProcess()
    -- This logic remains the same
end

local function stopRerollProcess()
    rerolling = false
    StatusLabel:SetText("⏹️ Reroll stopped by user.")
end
print("DEBUG: Part 4 - Complete.")


--// Part 5: Final UI Connections
print("DEBUG: Part 5 - Connecting final UI (the toggle)...")
EnchantToggle = SettingsSection:AddToggle("EnchantToggle", {
    Text = "Start Enchanting", Default = false,
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
print("DEBUG: Part 5 - Complete. Script setup finished.")

-- Initial setup call
task.wait(2)
print("DEBUG: Performing initial pet list update...")
updatePetList()
