-- Brainrot Catch — Remotes.
-- Creates (server) or finds (client) the RemoteEvents the game uses. Every
-- RemoteEvent lives in ReplicatedStorage under the BrainrotRemotes folder so
-- both sides can find them by name. The server never trusts a RemoteEvent
-- payload it did not validate; see each service for its own checks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local REMOTE_NAMES = {
	"CatchRequest", -- client -> server: uid (string). Ask to start a catch channel.
	"CatchResult", -- server -> client: { state, charId, mutation, reason }.
	"DropCarried", -- client -> server: no args. Drop the carried character.
	"WaveState", -- server -> all clients: { phase, secondsLeft }.
	"CashChanged", -- server -> one client: { cash, incomePerSecond }.
	"SlotRequest", -- client -> server: no args. Buy the next base slot.
	"SlotResult", -- server -> client: { success, slotsUnlocked, reason }.
	"RebirthRequest", -- client -> server: no args. Attempt a rebirth.
	"RebirthResult", -- server -> client: { success, rebirths, reason }.
	"IndexRequest", -- client -> server: no args. Ask for the index book.
	"IndexData", -- server -> client: { discovered = { [charId] = true }, complete = bool }.
	"EventNotice", -- server -> all clients: { kind, text, secondsLeft }.
	"Popup", -- server -> one client: { title, text, colorName }.
	"DashRequest", -- client -> server: no args. Ask to dash (costs stamina).
	"DashState", -- server -> one client: { stamina }.
}

function Remotes.getAll()
	local folder = ReplicatedStorage:FindFirstChild("BrainrotRemotes")
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = "BrainrotRemotes"
		folder.Parent = ReplicatedStorage
		for _, name in ipairs(REMOTE_NAMES) do
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

function Remotes.get(name)
	local folder = Remotes.getAll()
	if not folder then
		return nil
	end
	return folder:WaitForChild(name)
end

return Remotes
