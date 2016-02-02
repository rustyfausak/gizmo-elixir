defmodule Gizmo.Parser do
	alias Gizmo.Replay, as: Replay
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Reader, as: Reader

	@doc """
	`path` is a string.
	"""
	def parse(path) do
		data = File.read!(path)
		{meta, _netstream} = parse_meta(data)
		replay = Map.put(%Replay{}, :meta, meta)
		IO.inspect(replay, pretty: true)
	end

	@doc """
	Return tuple `{meta, netstream}`.
	"""
	def parse_meta(data) do
		{meta, data} = parse_header(data, %Meta{})
		parse_body(data, meta)
	end

	@doc """
	Return tuple `{meta, data}`.
	"""
	def parse_header(data, meta) do
		<<
			size1 :: little-unsigned-integer-size(32),
			crc1 :: little-unsigned-integer-size(32),
			version1 :: little-unsigned-integer-size(32),
			version2 :: little-unsigned-integer-size(32),
			data :: binary
		>> = data
		{label, data} = Reader.read_string(data)
		{properties, data} = Reader.read_property_map(data, &Meta.Property.read/1)
		{Map.merge(meta, %{
			size1: size1,
			crc1: crc1,
			version1: version1,
			version2: version2,
			label: label,
			properties: properties
		}), data}
	end

	@doc """
	Return tuple `{meta, netstream}`.
	"""
	def parse_body(data, meta) do
		<<
			size2 :: little-unsigned-integer-size(32),
			crc2 :: little-unsigned-integer-size(32),
			data :: binary
		>> = data
		{levels, data} = Reader.read_list(data, &Reader.read_string/1)
		{keyframes, data} = Reader.read_list(data, &Meta.Keyframe.read/1)
		<< netstream_bytes :: little-unsigned-integer-size(32), data :: binary >> = data
		netstream_bits = netstream_bytes * 8
		<< netstream :: bits-size(netstream_bits), data :: binary >> = data
		{messages, data} = Reader.read_list(data, &Meta.Message.read/1)
		{marks, data} = Reader.read_list(data, &Meta.Mark.read/1)
		{packages, data} = Reader.read_list(data, &Reader.read_string/1)
		{objects, data} = Reader.read_list(data, &Reader.read_string/1)
		object_map = Enum.into(Enum.with_index(objects), %{}, fn({v, k}) -> {k, v} end)
		{names, data} = Reader.read_list(data, &Reader.read_string/1)
		{class_map_nodes, data} = Reader.read_list(data, &Meta.ClassMapNode.read/1)
		class_map = Enum.reduce(class_map_nodes, %{},
			fn(class_map_node, acc) ->
				Map.put(acc, class_map_node.class_netstream_id, class_map_node.name)
			end
		)
		# {property_cache, data} = Reader.read_list(data, &(Meta.PropertyCacheNode.read(&1, object_map)))
		{property_cache, data} = Reader.read_list(data,
			fn(data) -> Meta.PropertyCacheNode.read(data, object_map) end
		)
		class_property_map = Meta.generate_class_property_map(class_map, property_cache)
		{Map.merge(meta, %{
			size2: size2,
			crc2: crc2,
			levels: levels,
			keyframes: keyframes,
			messages: messages,
			marks: marks,
			packages: packages,
			object_map: object_map,
			names: names,
			class_map: class_map,
			class_property_map: class_property_map
		}), netstream}
	end
end
