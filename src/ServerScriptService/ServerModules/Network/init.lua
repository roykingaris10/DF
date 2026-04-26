local Server = require(script.Parent)
local network = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local PacketLinks = Server.PacketLinks

local RemoteFolder = game:GetService('ReplicatedStorage')
local event = Instance.new('RemoteEvent', RemoteFolder)
local func  = Instance.new('RemoteFunction', RemoteFolder)

event.Name = 'POST'
func.Name  = 'GET'

local keys = {}
local boundEvents = {}
local boundFuncs  = {}
local guid = Server.Utilities.guid

event.OnServerEvent:connect(function(player, auth, fnId, ...)
	if not auth or auth ~= keys[player] then Server.PostHTTP(player, 'Auth Mismatch') return end
	if not boundEvents[fnId] then warn('event named "'..tostring(fnId)..'" not bound') return end
	boundEvents[fnId](player, ...)
end)

func.OnServerInvoke = function(player, auth, fnId, ...)
	if auth == 'generate' then
		if keys[player] then Server.PostHTTP(player, 'ReAuth') player:Kick() return end
		local key = guid()
		keys[player] = key
		return key
	end
	if not auth or auth ~= keys[player] then Server.PostHTTP(player, 'Auth Mismatch') player:Kick() return end -- Invalid auth
	if not boundFuncs[fnId] then warn(tostring(fnId).. " can't be found") return end
	return boundFuncs[fnId](player, ...)
end

function network:bindEvent(name, callback)
	boundEvents[name] = callback
end

function network:bindFunction(name, callback)
	boundFuncs[name] = callback
end

function network:postAll(...)
	event:FireAllClients(...)
end	

function network:post(fnId, player, ...)
	event:FireClient(player, fnId, ...)
end

function network:get(fnId, player, ...)
	return func:InvokeClient(player, fnId, ...)
end

local ServerHandlers = require(script.ServerHandlers)(Server)
local ServerInvokes = require(script.ServerInvokes)(Server)
local UnreliableServerHandlers = require(script.UnreliableServerHandlers)(Server)
print(ServerHandlers)
for Name, Handler in ServerHandlers do
	if not PacketLinks[Name] then continue end
	PacketLinks[Name].OnServerEvent:Connect(Handler)
end
for Name, Invocation in ServerInvokes do
	if not PacketLinks[Name] then continue end
	PacketLinks[Name].OnServerInvoke = Invocation
end
for Name, UnreliableHandler in UnreliableServerHandlers do
	if not PacketLinks[Name] then continue end
	PacketLinks.Unreliables[Name].OnServerEvent:Connect(UnreliableHandler)
end

network:bindFunction('ServerFunction', function(player, fnName, ...)
	if not player then warn('Missing player?') return end
	if not ServerInvokes[fnName] then
		warn('Server received bad invoke-request ('..tostring(fnName)..')')
		return
	end

	return ServerInvokes[fnName](player, ...)
end)

network:bindEvent('ServerEvent', function(player, fnName, ...)	
	if not player then warn('Missing player?') return end
	if not ServerHandlers[fnName] then
		warn('Server received bad request ('..tostring(fnName)..')')
		return
	end
	ServerHandlers[fnName](player, ...)
end)


return network