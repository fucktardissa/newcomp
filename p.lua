--// Fluent + SaveManager Setup
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local Options = SaveManager:Load() or {}

--// Window Configuration
local Window = Fluent:CreateWindow({
    Title = "Enchant Reroller 2.0",
    SubTitle = "by YourName",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 420),
    Acrylic = true,
    Theme = "Dark",
    Accent = Color3.fromRGB(100, 160, 255),
    MinimizeKey = Enum.KeyCode.LeftControl
})

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings() -- Optional: Prevents theme changes from being saved

--// Tabs
local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://6031219434" })
local CreditsTab = Window:AddTab({ Title = "Info", Icon = "rbxassetid://7995689793" })

--// Services & Variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

local rerollingEnabled = false
local selectedPetIds = {}

--// Core Logic
local function hasDesiredEnchant(pet, enchantName, enchantLevel)
    if not pet or not pet.Enchants or not enchantName or enchantName == "" or not enchantLevel then return false end
    for _, enchant in pairs(pet.Enchants) do
        if enchant.Id:lower() == enchantName:lower() and enchant.Level == enchantLevel then
            return true
        end
    end
    return false
end

local function rerollerLoop()
    while rerollingEnabled do
        local targetEnchant = Options.TargetEnchantName
        local targetLevel = tonumber(Options.TargetEnchantLevel)
        local rerollQueue = {}
        local playerData = LocalData:Get()
        
        -- Guard clause: Stop if settings are invalid
        if not targetEnchant or targetEnchant == "" or not targetLevel then
            Fluent:Notify({ Title = "Error", Content = "Invalid enchant name or level in settings." })
            getgenv().ToggleReroller:Set(false) -- Access the toggle via getgenv to turn it off
            break
        end

        -- Find pets that need rerolling from the selected list
        for _, petId in pairs(selectedPetIds) do
            local currentPet
            for _, p in pairs(playerData.Pets or {}) do
                if p.Id == petId then
                    currentPet = p
                    break
                end
            end

            if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                table.insert(rerollQueue, currentPet)
            end
        end

        if #rerollQueue > 0 then
            for _, petToReroll in ipairs(rerollQueue) do
                if not rerollingEnabled then break end -- Check flag before each expensive operation
                getgenv().StatusLabel:Set(`🔁 Rerolling {petToReroll.Name or petToReroll.Id}...`)
                RemoteFunction:InvokeServer("RerollEnchants", petToReroll.Id, "Gems")
                task.wait(0.3)
            end
        else
            getgenv().StatusLabel:Set("✅ All selected pets have the desired enchant. Monitoring...")
        end
        
        task.wait(1.5) -- Wait before checking all pets again
    end
end

--// UI Elements

-- Main Rerolling Tab
local ConfigSection = MainTab:AddSection("Configuration")

getgenv().PetDropdown = ConfigSection:AddDropdown("PetDropdown", {
    Title = "Select Pets",
    Values = (function()
        local petOptions = {}
        local data = LocalData:Get()
        if data and data.Pets then
            for _, pet in pairs(data.Pets) do
                table.insert(petOptions, `{pet.Name or "Unknown"} [{pet.Id}]`)
            end
        end
        table.sort(petOptions)
        return petOptions
    end)(),
    MultiSelect = true,
    Default = {},
})

getgenv().PetDropdown.OnChanged:Connect(function(selectedOptions)
    table.clear(selectedPetIds)
    for _, optionString in pairs(selectedOptions) do
        local id = string.match(optionString, "%[(.+)%]$")
        if id then table.insert(selectedPetIds, id) end
    end
    getgenv().StatusLabel:Set(`ℹ️ Selected {tostring(#selectedPetIds)} pets.`)
end)

ConfigSection:AddTextbox("TargetEnchantName", {
    Title = "Target Enchant Name",
    Placeholder = "e.g., agility",
    Default = Options.TargetEnchantName or "",
    Callback = function(text)
        Options.TargetEnchantName = text
        SaveManager:Save(Options)
    end
})

ConfigSection:AddTextbox("TargetEnchantLevel", {
    Title = "Target Enchant Level",
    Placeholder = "e.g., 10",
    Default = Options.TargetEnchantLevel or "",
    Callback = function(text)
        local sanitized = text:gsub("%D", "") -- Allow only numbers
        Options.TargetEnchantLevel = sanitized
        SaveManager:Save(Options)
        return sanitized -- Update the textbox visually
    end
})

local ControlsSection = MainTab:AddSection("Controls & Status")

getgenv().ToggleReroller = ControlsSection:AddToggle("EnableRerolling", {
    Title = "Enable Rerolling",
    Default = false,
    Callback = function(value)
        rerollingEnabled = value
        if value then
            if #selectedPetIds == 0 then
                Fluent:Notify({ Title = "Warning", Content = "No pets selected to reroll."})
                getgenv().ToggleReroller:Set(false) -- Automatically turn toggle off
                return
            end
            getgenv().StatusLabel:Set("⏳ Starting reroll process...")
            task.spawn(rerollerLoop)
        else
            getgenv().StatusLabel:Set("⏹️ Reroll process stopped.")
        end
    end
})

getgenv().StatusLabel = ControlsSection:AddLabel("StatusLabel", {
    Title = "Status: Waiting for input..."
})

-- Info Tab
CreditsTab:AddParagraph({ Title = "About this Script", Content = "This script automatically rerolls enchants on selected pets until a target enchant and level is reached."})
CreditsTab:AddParagraph({ Title = "Creator", Content = "UI refactor based on your example."})
CreditsTab:AddButton({ Title = "Copy Discord to Clipboard", Content = "lonly on discord", Callback = function() setclipboard("lonly on discord") end})


--// Finalize
Window:SelectTab(1)
SaveManager:LoadAtStart(Options)
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Enchant Reroller 2.0 is ready.",
    Duration = 5
})
