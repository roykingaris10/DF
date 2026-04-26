return function(Client)
	local CrewController = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")

	local crewState = {
		CrewId = "",
		CrewName = "",
		CreatedAt = 0,
		Rank = "None",
		CaptainUserId = 0,
		Members = {},
		History = {},
		Message = ""
	}

	local function applyStateFromServer(crewId: string, crewName: string, message: string)
		if crewId ~= "" then
			crewState.CrewId = crewId
			crewState.CrewName = crewName
			crewState.CreatedAt = os.time()
			crewState.CaptainUserId = player.UserId
			crewState.Rank = "Captain"
			crewState.Members = {}
			crewState.History = {}
			crewState.Message = message or ""
		else
			crewState.CrewId = ""
			crewState.CrewName = ""
			crewState.CreatedAt = 0
			crewState.CaptainUserId = 0
			crewState.Rank = "None"
			crewState.Members = {}
			crewState.History = {}
			crewState.Message = message or "You are not in a crew."
		end
	end

	function CrewController.GetState()
		return crewState
	end

	function CrewController.GetCrewState()
		local success, crewId, crewNameOrMessage = Client.PacketLinks.GetCrewState:Fire()
		if success then
			applyStateFromServer(crewId, crewNameOrMessage, "")
		else
			applyStateFromServer("", "", crewNameOrMessage)
		end
		return crewState
	end

	function CrewController.CreateCrew(crewName: string)
		if #crewName < 3 or #crewName > 24 then
			warn("Crew names must be 3-24 characters.")
			return false, "Crew names must be 3-24 characters."
		end
		
		local userFolder = player.StatFolder:FindFirstChild("UserFolder")
		
		if player:GetAttribute("Faction") ~= "Pirate" then
			if userFolder then
				warn(`You cannot create a crew as a {player:GetAttribute("Faction")}`)
				return false, warn(`You must first abandon your role as a {player:GetAttribute("Faction")} [{player:GetAttribute("FactionRank")}]`)
			end
		end

		local success, crewId, savedName = Client.PacketLinks.CreateCrew:Fire(crewName)

		if not success then
			warn(savedName)
			return false, savedName
		end
		
		applyStateFromServer(crewId, savedName, "")
		print(`[CrewController] Crew created: id={crewState.CrewId}, name={crewState.CrewName}`)
		return true, crewState
	end

	function CrewController.DisbandCrew()
		if (crewState.CrewId or "") == "" then
			warn("You are not in a crew.")
			return false, "You are not in a crew."
		end

		local currentCrewId = crewState.CrewId
		local success, message = Client.PacketLinks.DisbandCrew:Fire(currentCrewId)

		if not success then
			warn(`Disband failed: {message or "Unknown error"}`)
			return false, message
		end

		local responseMessage = message or "Crew disbanded."
		applyStateFromServer("", "", responseMessage)
		print(responseMessage)
		return true, responseMessage
	end

	function CrewController.LeaveCrew()
		if (crewState.CrewId or "") == "" then
			warn("You are not in a crew.")
			return false, "You are not in a crew."
		end

		-- Don't clear state on captain check - just return early
		if crewState.Rank == "Captain" then
			warn("You cannot leave a crew as its captain. Disband the crew first.")
			return false, "You cannot leave a crew as its captain. Disband the crew first."
		end

		local currentCrewId = crewState.CrewId
		local success, message = Client.PacketLinks.LeaveCrew:Fire(currentCrewId)

		if not success then
			warn(`Leave failed: {message or "Unknown error"}`)
			return false, message
		end

		local responseMessage = message or "You have left the crew."
		applyStateFromServer("", "", responseMessage)
		print(responseMessage)
		return true, responseMessage
	end

	-- Server events
	Client.PacketLinks.CrewDisbanded.OnClientEvent:Connect(function()
		applyStateFromServer("", "", "Your crew has been disbanded.")
		print("[CrewController] Your crew has been disbanded.")
	end)

	Client.PacketLinks.CrewLeft.OnClientEvent:Connect(function()
		applyStateFromServer("", "", "You have left the crew.")
		print("[CrewController] You have left the crew.")
	end)

	-- Initialize
	CrewController.GetCrewState()

	return CrewController
end