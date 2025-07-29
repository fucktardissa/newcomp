local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local window = Fluent:CreateWindow({
    Title = "Enchant Reroller",
    SubTitle = "Pet Simulator GUI",
    Theme = "Dark",
    Acrylic = true
})

local tab = window:AddTab({ Title = "Main" })

-- Variables
local selectedPet = nil
local enchantText = ""
local statusLabel = nil

-- Dropdown
local petDropdown = tab:AddDropdown({
    Title = "Select Pet",
    Values = {"Loading..."},
    Callback = function(value)
        selectedPet = value
    end
})

-- Input
tab:AddInput({
    Title = "Desired Enchant",
    Placeholder = "Enter enchant name",
    Callback = function(text)
        enchantText = text
    end
})

-- Status
statusLabel = tab:AddParagraph({
    Title = "Status",
    Content = "Waiting for input..."
})

-- Reroll Button
tab:AddButton({
    Title = "Start Reroll",
    Callback = function()
        if not selectedPet or not enchantText or enchantText == "" then
            statusLabel:SetContent("❌ Missing input!")
            return
        end

        statusLabel:SetContent("🔄 Rerolling for: " .. enchantText)

        -- Replace with your real Remote event or logic
        for i = 1, 5 do
            task.wait(0.4)
            print("Reroll attempt " .. i .. " for pet:", selectedPet, "with enchant:", enchantText)

            -- example result (replace with actual enchant check logic)
            local currentEnchant = "Strength" .. math.random(1, 5)

            if string.lower(currentEnchant) == string.lower(enchantText) then
                statusLabel:SetContent("✅ Found match: " .. currentEnchant)
                break
            end
        end

        statusLabel:SetContent("❌ Didn't find match.")
    end
})

-- Close Button
tab:AddButton({
    Title = "Close Window",
    Callback = function()
        window:Destroy()
    end
})

-- Populate pet list (replace this with actual pet names if available)
task.spawn(function()
    task.wait(1)
    local dummyPets = {"Cat", "Dog", "Dragon", "Phoenix"}
    petDropdown:Clear()
    for _, petName in ipairs(dummyPets) do
        petDropdown:Add(petName)
    end
end)
