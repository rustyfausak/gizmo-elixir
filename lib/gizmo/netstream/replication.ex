defmodule Gizmo.Netstream.Replication do
	alias Gizmo.Helper, as: Helper
	alias Gizmo.Netstream.ActorData, as: ActorData
	alias Gizmo.Netstream.Replication, as: Self
	alias Gizmo.Reader, as: Reader

	@max_channels 1024

	defstruct [
		:actor_id,
		:actor_state
	]

	def read(data, meta) do
		IO.inspect "Replication.read"
		# 1 bit to signal we are replicating another actor
		<< replication_flag :: bits-size(1), data :: bits >> = data
		if replication_flag == << 0 :: size(1) >> do
			{nil, data}
		else
			# compressed integer for the actor's network channel ID (max value is MaxChannels)
			n = Helper.bitsize(@max_channels)
			{actor_id, data} = Reader.read_rev_int(data, n)
			IO.inspect "actor_id = #{actor_id}"
			# 1 bit to signal if channel is closing (actor was destroyed)
			<< channel_state :: bits-size(1), data :: bits >> = data
			if channel_state == << 0 :: size(1) >> do
				IO.inspect "channel state = 0"
				# close actor
			else
				IO.inspect "channel state = 1"
				# Data for actors that are replicating this frame
				# 1 bit to signal if it is a new actor
				<< actor_state :: bits-size(1), data :: bits >> = data
				if actor_state == << 1 :: size(1) >> do
					IO.inspect "actor state = 1"
					# new actor
					{actor, data} = ActorData.read_new(data, meta)
				else
					IO.inspect "actor state = 0"
					# existing actor
					{actor, data} = ActorData.read_existing(data, meta)
				end
			end
			{nil, data}
		end
		System.halt(0)
	end
end
