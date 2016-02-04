defmodule Gizmo.Netstream.Frame do
	alias Gizmo.Reader, as: Reader
	alias Gizmo.Netstream.Frame, as: Self
	alias Gizmo.Netstream.Replication, as: Replication

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
		{time, data} = Reader.read_float(data)
		{delta, data} = Reader.read_float(data)
		IO.inspect time
		IO.inspect delta
		if time == 0 && delta == 0 do
			nil
		end
		{%Self{
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
