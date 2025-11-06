-- src/server/init.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServicesDeep(game:GetService("ServerScriptService").Services)

Knit.Start()
