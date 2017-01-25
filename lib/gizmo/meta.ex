defmodule Gizmo.Meta do
	alias Gizmo.Meta.Keyframe, as: Keyframe
	alias Gizmo.Meta.Mark, as: Mark
	alias Gizmo.Meta.Property, as: Property

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
		:property_cache,
		:class_property_map,
		actor_object_map: %{}
	]

	def print(meta) do
		IO.puts "=== Meta ==="

		IO.puts "meta.size1 => #{meta.size1}"
		IO.puts "meta.size2 => #{meta.size2}"
		IO.puts "meta.crc1 => #{meta.crc1}"
		IO.puts "meta.crc2 => #{meta.crc2}"
		IO.puts "meta.version => #{meta.version1}.#{meta.version2}"
		IO.puts "meta.label => #{meta.label}"
		IO.puts "meta.levels =>"
		Enum.each(
			meta.levels,
			fn(x) ->
				IO.puts "  #{x}"
			end
		)
		IO.puts "meta.keyframes =>"
		Enum.each(
			meta.keyframes,
			fn(x) ->
				IO.puts "  " <> Keyframe.format(x)
			end
		)
		IO.puts "meta.messages =>"
		Enum.each(
			meta.messages,
			fn(x) ->
				IO.puts "  #{x}"
			end
		)
		IO.puts "meta.marks =>"
		Enum.each(
			meta.marks,
			fn(x) ->
				IO.puts "  " <> Mark.format(x)
			end
		)
		IO.puts "meta.packages =>"
		Enum.each(
			meta.packages,
			fn(x) ->
				IO.puts "  #{x}"
			end
		)
		IO.puts "meta.names =>"
		Enum.each(
			meta.names,
			fn(x) ->
				IO.puts "  #{x}"
			end
		)

		IO.puts "meta.properties =>"
		IO.puts Property.format_map(meta.properties)

		IO.puts "meta.object_map =>"
		Enum.each(
			Enum.sort(meta.object_map),
			fn({k, v}) ->
				IO.puts "  #{k} => #{v}"
			end
		)

		IO.puts "meta.class_map =>"
		Enum.each(
			Enum.sort(meta.class_map),
			fn({k, v}) ->
				IO.puts "  #{k} => #{v}"
			end
		)

		IO.puts "meta.class_property_map =>"
		Enum.each(
			Enum.sort(meta.class_property_map),
			fn({k, v}) ->
				IO.puts "  #{k} =>"
				Enum.each(
					Enum.sort(v),
					fn({k2, v2}) ->
						IO.puts "    #{k2} => #{v2}"
					end
				)
			end
		)
	end

	def get_class(_, 0) do
		raise "Could not find class name"
	end

	@doc """
	Gets the class from the given `object_map` and `object_id`.

	Returns a tuple of `{class_id, class_name}`.
	"""
	def get_class(object_map, object_id) do
		name = to_string(Map.fetch!(object_map, object_id))
		cond do
			String.contains?(name, "Archetype") ->
				get_class(object_map, object_id - 1)
			String.equivalent?(name, "TAGame.Default__PRI_TA") ->
				get_class(object_map, object_id - 1)
			true -> {object_id, name}
		end
	end

	@doc """
	`class_map` is a map: `%{netstream_id => name, ..}`
	`cache` is a list of CacheNode: `[%CacheNode{..}, ..]`

	Returns a map of map:
		`%{class_netstream_id => %{property_netstream_id => name, ..}, ..}`
	"""
	def generate_class_property_map(class_map, cache) do
		IO.puts "generate_class_property_map.."
		Enum.reduce(class_map, %{}, fn({netstream_id, _}, acc) ->
			IO.puts "netstream_id => #{netstream_id}"
			node = Enum.find(cache, fn(x) -> x.class_id == netstream_id end)
			if node do
				IO.puts " found node"
				IO.puts "  node.class_id => #{node.class_id}"
				IO.puts "  node.parent_cache_id => #{node.parent_cache_id}"
				IO.puts "  node.cache_id => #{node.cache_id}"
				Map.put(acc, netstream_id, get_property_map(cache, node.cache_id))
			else
				IO.puts " no node"
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
		IO.puts "    get_property_map(.., #{cache_id})"
		cache_node = Enum.find(cache, fn(x) -> x.cache_id == cache_id end)
		cond do
			!cache_node ->
				IO.puts "     no cache node"
				%{}
			!cache_node.parent_cache_id || cache_node.parent_cache_id == cache_id ->
				IO.puts "     no cache node parent_cache_id or cache node parent_cache_id == cache_id"
				cache_node.property_map
			true ->
				Map.merge(
					cache_node.property_map,
					get_property_map(cache, cache_node.parent_cache_id)
				)
		end
	end
end
