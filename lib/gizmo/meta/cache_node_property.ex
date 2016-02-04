defmodule Gizmo.Meta.CacheNodeProperty do
	alias Gizmo.Meta.CacheNodeProperty, as: Self

	defstruct [
		:netstream_id,
		:name
	]

	def read(data, object_map) do
		<< object_id :: little-unsigned-integer-size(32), data :: binary >> = data
		<< netstream_id :: little-unsigned-integer-size(32), data :: binary >> = data
		{%Self{
			netstream_id: netstream_id,
			name: Map.fetch!(object_map, object_id)
		}, data}
	end
end
