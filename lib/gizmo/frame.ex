defmodule Gizmo.Frame do
	alias Gizmo.Replication, as: Replication

	defstruct [
		:time,
		:delta,
		:replications
	]

	def read(data, meta) do
		<< time :: little-float-size(32), data :: binary >> = data
		<< delta :: little-float-size(32), data :: binary >> = data
		if time == 0 && delta == 0 do
			nil
		end
		%Frame{
			time: time,
			delta: delta
			replications: read_replications(data, meta)
		}
	end

	def read_replications(data, meta) do
		Enum.reverse(_read_replications(data, meta))
	end

	def _read_replications(data, meta) do
		{replication, data} = Replication.read(data, meta)
		if replication do
			[replication | _read_replications(data, meta)]
		else
			[]
		end
	end
end
