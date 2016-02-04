defmodule Gizmo.Meta.CacheNode do
	alias Gizmo.Meta.CacheNode, as: Self
	alias Gizmo.Meta.CacheNodeProperty, as: CacheNodeProperty
	alias Gizmo.Reader, as: Reader

	defstruct [
		:class_id,
		:parent_cache_id,
		:cache_id,
		:property_map
	]

	def read(data, object_map) do
		<< class_id :: little-unsigned-integer-size(32), data :: binary >> = data
		<< parent_cache_id :: little-unsigned-integer-size(32), data :: binary >> = data
		<< cache_id :: little-unsigned-integer-size(32), data :: binary >> = data
		{properties, data} = Reader.read_list(data,
			fn(data) -> CacheNodeProperty.read(data, object_map) end
		)
		property_map = Enum.reduce(properties, %{},
			fn(property, acc) ->
				Map.put(acc, property.netstream_id, property.name)
			end
		)
		{%Self{
			class_id: class_id,
			parent_cache_id: parent_cache_id,
			cache_id: cache_id,
			property_map: property_map
		}, data}
	end
end
