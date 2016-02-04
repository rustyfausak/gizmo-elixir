defmodule Gizmo.Frame do
	alias Gizmo.Replication, as: Replication

	defstruct [
		:time,
		:delta,
		:replications
	]

	@doc """
	Each frame is composed like this:
	- Current Time
	- Delta Time (since last frame)
	- Data for actors
	"""
	def read(data, meta) do
		IO.inspect "Frame.read"
		<< time :: little-float-size(32), data :: bits >> = data
		<< delta :: little-float-size(32), data :: bits >> = data
		if time == 0 && delta == 0 do
			nil
		end
		{%Gizmo.Frame{
			time: time,
			delta: delta,
			replications: read_replications(data, meta)
		}, data}
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
