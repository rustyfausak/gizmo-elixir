defmodule Gizmo.Replication do
	alias Gizmo.Helper, as: Helper

	@MAX_CHANNELS 1024

	defstruct [
		:actor_id,
		:actor_state
	]

	def read(data, meta) do
		<< replication_flag :: bits-size(1), data :: binary >> = data
		if replication_flag == 0 do
			nil
		else
			n = Helper.bitsize(@MAX_CHANNELS)
			<< actor_id :: little-unsigned-integer-size(n), data :: binary >> = data
			<< channel_state :: bits-size(1), data :: binary >> = data
			if channel_state == 0 do
				# close actor
				# return
			else
				#
			end
			%Replication{

			}
		end
	end
end
