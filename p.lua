--[[
    Title: Enchant Reroller (Fluent Edition)
    Description: A full-featurhsrdfahraerhjRAWHERAHERJARWJAERASJJERTJREJREJRESJRESed pet enchant reroller built with the Fluent UI library.
    Version: 5.0 (Verified)
]]

--// =================================================================================
--// Part 1: Setup & Services
--// =================================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

local rerolling = false

--// =================================================================================
--// Part 2: Fluent UI Initialization
--// =================================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "v5.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 420),
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

-- RE-IMPLEMENTED: AddLabel is a valid function and provides better status updates.
local StatusLabel = SettingsSection:AddLabel("StatusInfo", {
    Text = "Status: Waiting..."
})
local EnchantToggle

--// =================================================================================
--// Part 4: Core Logic & Functions
--// =================================================================================

function updatePetList()
    local petsForDropdown = {}
    petDataMap = {}
    local petsFolder = game:GetService("Workspace"):WaitForChild("Markers"):WaitForChild("Pets")
    if not petsFolder then return end

    for _, petFolder in ipairs(petsFolder:GetChildren()) do
        if petFolder:GetAttribute("OwnerId") == LocalPlayer.UserId then
            local petId = petFolder.Name
            local petName = petFolder:GetAttribute("Name") or "Unknown"
            local isShiny = petFolder:GetAttribute("Shiny") or false
            local isMythic = petFolder:GetAttribute("Mythic") or false

            local prefix = ""
            if isShiny and isMythic then prefix = "Shiny Mythic "
            elseif isShiny then prefix = "Shiny "
            elseif isMythic then prefix = "Mythic "
            end

            local finalName = prefix .. petName
            local displayName = string.format("%s [%s]", finalName, tostring(petId):sub(1, 5))

            table.insert(petsForDropdown, displayName)
            petDataMap[displayName] = petId
        end
    end

    PetDropdown:SetValues(petsForDropdown)
    if #petsForDropdown > 0 then
        Fluent:Notify({ Title = "Success", Content = "Found " .. #petsForDropdown .. " of your pets.", Duration = 4 })
    else
        Fluent:Notify({ Title = "No Pets Found", Content = "Could not find any pets owned by you.", Duration = 6 })
    end
end

local function startRerollProcess()
    local targetEnchants = Fluent.Options.EnchantDropdown.Value
    local rerollQueue = {}

    for _, displayName in pairs(Fluent.Options.PetDropdown.Value) do
        if petDataMap[displayName] then table.insert(rerollQueue, petDataMap[displayName]) end
    end

    if #rerollQueue == 0 or #targetEnchants == 0 then
        StatusLabel:Set("⚠️ Select pets and enchants.")
        EnchantToggle:Set({ Value = false, Silent = true })
        EnchantToggle:SetText("Start Enchanting")
        return
    end

    rerolling = true
    StatusLabel:Set("⏳ Starting reroll for " .. #rerollQueue .. " pets...")

    coroutine.wrap(function()
        local petsProcessed = 0
        while rerolling and #rerollQueue > 0 do
            local petId = table.remove(rerollQueue, 1)
            petsProcessed += 1
            StatusLabel:Set("🔁 Rerolling pet " .. petsProcessed .. "/" .. #rerollQueue + petsProcessed)
            RemoteFunction:InvokeServer("RerollEnchants", petId, "Gems")
            task.wait(0.5)
        end

        rerolling = false
        StatusLabel:Set("✅ Finished processing pets.")
        EnchantToggle:Set({ Value = false, Silent = true })
        EnchantToggle:SetText("Start Enchanting")
    end)()
end

local function stopRerollProcess()
    rerolling = false
    StatusLabel:Set("⏹️ Reroll stopped by user.")
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
