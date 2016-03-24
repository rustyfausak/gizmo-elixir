defmodule Gizmo.Netstream.Property do
	alias Gizmo.Netstream.Property, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:id,
		:name,
		:type,
		:stuff
	]

	@doc """
	Properties are read like this:
	 - Compressed property id (max value pulled from the Class Net Cache).
	 - If the property is a static array, serialize the index we are replicating
	   in the static array.
	 - Otherwise, the property's data. Whatever gets serialized here depends on
	   the type of property. Ints, bytes, and strings are obvious. The less
	   obvious ones are structs, and particularly the rigid body state for each
	   car and the ball, which is comprised of several compressed vectors and
	   rotators.
	"""
	def read(data, meta, class_id) do
		IO.puts "class_id #{class_id}"
		class_property_map = Map.fetch!(meta.class_property_map, class_id)
		num_properties = Enum.count(class_property_map)
		IO.puts "total num properties #{num_properties}"
		{mapped_property_id, data} = Reader.read_serialized_int(data, num_properties)
		IO.puts "mapped_property_id => #{mapped_property_id}"
		property = to_string(Map.fetch!(class_property_map, mapped_property_id))
		IO.puts "#{property} =>"
		stuff = []
		type = nil

		cond do
			# Boolean
			Enum.member?([
				"Engine.Actor:bBlockActors",
				"Engine.Actor:bCollideActors",
				"Engine.Actor:bCollideWorld",
				"Engine.Actor:bHidden",
				"Engine.Actor:bNetOwner",
				"Engine.Actor:bTearOff",
				"Engine.GameReplicationInfo:bMatchIsOver",
				"Engine.PlayerReplicationInfo:bBot",
				"Engine.PlayerReplicationInfo:bIsSpectator",
				"Engine.PlayerReplicationInfo:bReadyToPlay",
				"Engine.PlayerReplicationInfo:bWaitingPlayer",
				"ProjectX.GRI_X:bGameStarted",
				"TAGame.CarComponent_Boost_TA:bUnlimitedBoost",
				"TAGame.CarComponent_FlipCar_TA:bFlipRight",
				"TAGame.GameEvent_Soccar_TA:bBallHasBeenHit",
				"TAGame.GameEvent_Soccar_TA:bOverTime",
				"TAGame.GameEvent_TA:bHasLeaveMatchPenalty",
				"TAGame.PRI_TA:bIsInSplitScreen",
				"TAGame.PRI_TA:bReady",
				"TAGame.PRI_TA:bUsingBehindView",
				"TAGame.PRI_TA:bUsingSecondaryCamera",
				"TAGame.RBActor_TA:bFrozen",
				"TAGame.RBActor_TA:bReplayActor",
				"TAGame.Vehicle_TA:bDriving",
				"TAGame.Vehicle_TA:bReplicatedHandbrake",
			], property) ->
				<< bit :: size(1), data :: bits >> = data
				stuff = [bit | stuff]
				type = 'Boolean'

			# Integer
			Enum.member?([
				"Engine.PlayerReplicationInfo:PlayerID",
				"Engine.PlayerReplicationInfo:Score",
				"Engine.TeamInfo:Score",
				"ProjectX.GRI_X:ReplicatedGameMutatorIndex",
				"ProjectX.GRI_X:ReplicatedGamePlaylist",
				"TAGame.CrowdActor_TA:ReplicatedCountDownNumber",
				"TAGame.GameEvent_Soccar_TA:RoundNum",
				"TAGame.GameEvent_Soccar_TA:SecondsRemaining",
				"TAGame.GameEvent_TA:BotSkill",
				"TAGame.GameEvent_TA:ReplicatedGameStateTimeRemaining",
				"TAGame.GameEvent_Team_TA:MaxTeamSize",
				"TAGame.PRI_TA:MatchAssists",
				"TAGame.PRI_TA:MatchGoals",
				"TAGame.PRI_TA:MatchSaves",
				"TAGame.PRI_TA:MatchScore",
				"TAGame.PRI_TA:MatchShots",
				"TAGame.PRI_TA:Title",
				"TAGame.PRI_TA:TotalXP",
			], property) ->
				{int, data} = Reader.read_rev_int(data)
				stuff = [int | stuff]
				type = 'Integer'

			# Flagged integer
			Enum.member?([
				"Engine.Actor:Owner",
				"Engine.Actor:ReplicatedCollisionType",
				"Engine.GameReplicationInfo:GameClass",
				"Engine.Pawn:PlayerReplicationInfo",
				"Engine.PlayerReplicationInfo:Team",
				"TAGame.Ball_TA:GameEvent",
				"TAGame.CarComponent_TA:Vehicle",
				"TAGame.CrowdActor_TA:GameEvent",
				"TAGame.CrowdActor_TA:ReplicatedOneShotSound",
				"TAGame.CrowdManager_TA:GameEvent",
				"TAGame.CrowdManager_TA:ReplicatedGlobalOneShotSound",
				"TAGame.PRI_TA:ReplicatedGameEvent",
				"TAGame.Team_TA:GameEvent",
				"TAGame.Team_TA:LogoData",
			], property) ->
				<< bit :: size(1), data :: bits >> = data
				stuff = [bit | stuff]
				{int, data} = Reader.read_rev_int(data)
				stuff = [int | stuff]
				type = 'Flagged Integer'

			# String
			Enum.member?([
				"Engine.GameReplicationInfo:ServerName",
				"Engine.PlayerReplicationInfo:PlayerName",
				"TAGame.GRI_TA:NewDedicatedServerIP",
				"TAGame.Team_TA:CustomTeamName",
			], property) ->
				{str, data} = Reader.read_rev_string(data)
				stuff = [str | stuff]
				type = 'String'

			# Unknown
			true ->
				raise "No deserialize for actor property #{property}"
		end

		stuff = Enum.reverse(stuff)

		IO.puts "  type => #{type}"
		Enum.each(
			stuff,
			fn(x) ->
				IO.puts "  #{x}"
			end
		)

		{%Self{
			id: mapped_property_id,
			name: property,
			type: type,
			stuff: stuff
		}, data}
	end
end
