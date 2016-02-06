defmodule Gizmo.Netstream.Replication do
	alias Gizmo.Netstream.ActorState, as: ActorState
	alias Gizmo.Netstream.Replication, as: Self
	alias Gizmo.Reader, as: Reader

	@max_channels 1024

	defstruct [
		:actor_id,
		:actor_state
	]

	def read(data, meta) do
		# 1 bit to signal we are replicating another actor
		<< replication_flag :: size(1), data :: bits >> = data
		if replication_flag == 0 do
			{nil, data}
		else
			# compressed integer for the actor's network channel ID (max value is MaxChannels)
			num_bits = Reader.bitsize(@max_channels)
			{actor_id, data} = Reader.read_rev_int(data, num_bits)
			actor_state = nil
			# 1 bit to signal if channel is closing (actor was destroyed)
			<< channel_flag :: size(1), data :: bits >> = data
			if channel_flag == 0 do
				# close actor
			else
				# Data for actors that are replicating this frame
				# 1 bit to signal if it is a new actor
				<< actor_flag :: size(1), data :: bits >> = data
				if actor_flag == 1 do
					# new actor
					{actor_state, data} = ActorState.read_new(data, meta)
				else
					# existing actor
					raise "dont know how to parse existing replication"
					{actor_state, data} = ActorState.read_existing(data, meta)
				end
			end
			{%Self{
				actor_id: actor_id,
				actor_state: actor_state
			}, data}
		end
	end
end
