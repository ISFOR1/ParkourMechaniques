-- src/client/init.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllersDeep(script.Parent.ControllersClients)

Knit.Start()
