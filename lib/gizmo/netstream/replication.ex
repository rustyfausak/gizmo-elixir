defmodule Gizmo.Netstream.Replication do
	alias Gizmo.Netstream.ActorState, as: ActorState
	alias Gizmo.Netstream.Replication, as: Self
	alias Gizmo.Reader, as: Reader

	@max_channels 1024

	defstruct [
		:actor_id,
		:actor_state,
		:is_new,
		:is_closing
	]

	def read(data, meta) do
		# 1 bit to signal we are replicating another actor
		<< replication_flag :: size(1), data :: bits >> = data
		if replication_flag == 0 do
			{nil, data}
		else
			# Compressed integer for the actor's network channel ID (max value is MaxChannels)
			num_bits = Reader.bitsize(@max_channels)
			{actor_id, data} = Reader.read_rev_int(data, num_bits)
			actor_state = nil
			is_new = false
			is_closing = false
			# 1 bit to signal if channel is closing (actor was destroyed)
			<< channel_flag :: size(1), data :: bits >> = data
			if channel_flag == 0 do
				# Close actor
				is_closing = true
			else
				# Data for actors that are replicating this frame
				# 1 bit to signal if it is a new actor
				<< actor_flag :: size(1), data :: bits >> = data
				if actor_flag == 1 do
					# New actor
					is_new = true
					{actor_state, data} = ActorState.read_new(data, meta)
					# Save the class ID for this actor so we can use it when we
					# parse existing actors
					meta = Map.put(
						meta,
						:actor_object_map,
						Map.put(
							meta.actor_object_map,
							actor_id,
							actor_state.class_id
						)
					)
				else
					# Existing actor
					# Get the number of properties for this actor
					class_id = Map.fetch!(meta.actor_object_map, actor_id)
					num_properties = Enum.count(Map.fetch!(meta.class_property_map, class_id))
					{actor_state, data} = ActorState.read_existing(data, meta, num_properties)
				end
			end
			{%Self{
				actor_id: actor_id,
				actor_state: actor_state,
				is_new: is_new,
				is_closing: is_closing
			}, data, meta}
		end
	end
end
