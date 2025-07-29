local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Rerollerr",
    SubTitle = "Select Pets",
    TabWidth = 120,
    Size = UDim2.fromOffset(460, 540),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local tab = Window:AddTab({ Title = "Main" })

-- Search box + dropdown frame
local selectedPetIds = {}
local petButtons = {}

local section = tab:AddSection("Select Pets")

local dropdownFrame = section:AddDropdown("Select Pets", {
    Values = {},
    Multi = true,
    Default = {},
    Callback = function(selected)
        selectedPetIds = {}
        for _, id in pairs(selected) do
            selectedPetIds[id] = true
        end
    end
})

local searchBox = section:AddTextbox("Search Name", "", function(value)
    updatePetList(value)
end)

function updatePetList(filterText)
    local LocalData = require(game:GetService("ReplicatedStorage").Client.Framework.Services.LocalData)
    local data = LocalData:Get()
    local results = {}

    for _, pet in pairs(data.Pets or {}) do
        local name = tostring(pet.Name or pet.name or pet._name or "Unknown")
        local id = tostring(pet.Id or pet.id or pet._id or "???")
        if filterText == "" or string.find(name:lower(), filterText:lower()) then
            table.insert(results, name .. " [" .. id .. "]")
        end
    end

    dropdownFrame:Clear()
    dropdownFrame:Add(results)
end

updatePetList("")
