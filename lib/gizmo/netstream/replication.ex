defmodule Gizmo.Netstream.Replication do
	@max_channels 1024

	alias Gizmo.Helper, as: Helper
	alias Gizmo.Netstream.ActorState, as: ActorState
	alias Gizmo.Netstream.Replication, as: Self

	defstruct [
		:actor_id,
		:actor_state
	]

	def read(data, meta) do
		IO.inspect "Replication.read"
		<< bits :: bits-size(40), _ :: bits >> = data
		IO.inspect(bits)
		# 1 bit to signal we are replicating another actor
		<< replication_flag :: bits-size(1), data :: bits >> = data
		if replication_flag == << 0 :: size(1) >> do
			IO.inspect "flag = 0"
			{nil, data}
		else
			IO.inspect "flag = 1"
			# compressed integer for the actor's network channel ID (max value is MaxChannels)
			n = Helper.bitsize(@max_channels)
			IO.inspect "read n #{n}"
			<< actor_id :: size(n), data :: bits >> = data
			IO.inspect "actor_id = #{actor_id}"
			# 1 bit to signal if channel is closing (actor was destroyed)
			<< channel_state :: bits-size(1), data :: bits >> = data
			if channel_state == << 0 :: size(1) >> do
				IO.inspect "channel state = 0"
				# close actor
				# return
			else
				IO.inspect "channel state = 1"
				# Data for actors that have started replicating this frame (newly spawned)
				# 1 bit to signal if it is a new actor
				<< actor_state :: bits-size(1), data :: bits >> = data
				if actor_state == << 1 :: size(1) >> do
					IO.inspect "actor state = 1"
					# new actor
					{actor, data} = ActorState.read_new(data, meta)
				else
					IO.inspect "actor state = 0"
					# existing actor
					{actor, data} = ActorState.read_existing(data, meta)
				end
			end
			{nil, data}
		end
		System.halt(0)
	end
end
