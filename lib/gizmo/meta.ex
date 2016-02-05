defmodule Gizmo.Meta do
	defstruct [
		:size1,
		:size2,
		:crc1,
		:crc2,
		:version1,
		:version2,
		:label,
		:properties,
		:levels,
		:keyframes,
		:messages,
		:marks,
		:packages,
		:object_map,
		:names,
		:class_map,
		:class_property_map
	]

	def get_class(object_map, 0) do
		raise "Could not find class name"
	end

	def get_class(object_map, object_id) do
		name = Map.fetch!(object_map, object_id)
		if String.contains?(to_string(name), "Archetype") do
			get_class(object_map, object_id - 1)
		else
			name
		end
	end

	@doc """
	`class_map` is a map: `%{netstream_id => name, ..}`
	`cache` is a list of CacheNode: `[%CacheNode{..}, ..]`

	Returns a map of map:
		`%{class_netstream_id => %{property_netstream_id => name, ..}, ..}`
	"""
	def generate_class_property_map(class_map, cache) do
		Enum.reduce(class_map, %{}, fn({netstream_id, _}, acc) ->
			node = Enum.find(cache, fn(x) -> x.class_id == netstream_id end)
			if node do
				Map.put(acc, netstream_id, get_property_map(cache, node.cache_id))
			else
				acc
			end
		end)
	end

	@doc """
	Look for the CacheNode with `cache_id` and return its properties merged with
	its parents properties.

	Returns a map.
	"""
	def get_property_map(cache, cache_id) do
		cache_node = Enum.find(cache, fn(x) -> x.cache_id == cache_id end)
		cond do
			!cache_node ->
				%{}
			!cache_node.parent_cache_id || cache_node.parent_cache_id == cache_id ->
				cache_node.property_map
			true ->
				Map.merge(
					cache_node.property_map,
					get_property_map(cache, cache_node.parent_cache_id)
				)
		end
	end
end
