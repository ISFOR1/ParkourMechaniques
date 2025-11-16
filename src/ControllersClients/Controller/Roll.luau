local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Roll = Knit.CreateController({ Name = "Roll" })

function Roll:KnitStart() end

return Roll
