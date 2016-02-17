defmodule Gizmo.Netstream.Frame do
	alias Gizmo.Netstream.Frame, as: Self
	alias Gizmo.Netstream.Replication, as: Replication
	alias Gizmo.Reader, as: Reader

	defstruct [
		:time,
		:delta,
		:replications
	]

	def read(<<>>, meta) do
		{nil, <<>>}
	end

	@doc """
	Each frame is composed like this:
	 - Current Time
	 - Delta Time (since last frame)
	 - Data for actors (replications)
	"""
	def read(data, meta) do
		{time, data} = Reader.read_rev_float(data)
		{delta, data} = Reader.read_rev_float(data)
		if time == 0 && delta == 0 do
			{nil, data}
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
		{replication, data, meta} = Replication.read(data, meta)
		IO.inspect(replication, pretty: true, width: 1)
		if replication do
			[replication | _read_replications(data, meta)]
		else
			[]
		end
	end
end
