defmodule Gizmo.Parser do
	alias Gizmo.Replay, as: Replay
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Reader, as: Reader
	alias Gizmo.Frame, as: Frame

	@doc """
	`path` is a string.
	"""
	def parse(path) do
		data = File.read!(path)
		{meta, netstream} = parse_meta(data)
		replay = Map.put(%Replay{}, :meta, meta)
		netstream = reverse_endian(netstream)
		frames = parse_frames(netstream, meta)
		replay = Map.put(replay, :frames, frames)
		IO.inspect(replay.frames, pretty: true)
	end

	def reverse_bits(<<>>, acc) do
		acc
	end

	def reverse_bits(<< h :: size(1), data :: bits >>, acc) do
		reverse_bits(data, << h :: size(1), acc :: bits >>)
	end

	def reverse_endian(data) do
		if byte_size(data) > 1 do
			<<
				byte :: bits-size(8),
				data :: bits
			>> = data
			reverse_bits(byte, <<>>) <> reverse_endian(data)
		else
			<<>>
		end
	end

	@doc """
	Netstream is replay file data for the replay frames.

	The network stream is pretty much just the same data that the server sends
	to the client, so it does have some compression going on. This is not an
	overall compression, it is a per-property compression (such as vector
	compression for velocity, location)

	Returns list of frames.
	"""
	def parse_frames(netstream, meta) do
		Enum.reverse(_parse_frames(netstream, meta))
	end

	def _parse_frames(netstream, meta) do
		{frame, netstream} = Frame.read(netstream, meta)
		if frame do
			[frame | _parse_frames(netstream, meta)]
		else
			[]
		end
	end

	@doc """
	Return tuple `{meta, netstream}`.
	"""
	def parse_meta(data) do
		{meta, data} = parse_header(data, %Meta{})
		{meta, netstream} = parse_body(data, meta)
		{meta, netstream}
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

		# Array of strings for all of the levels that need to be loaded (array
		# length followed by each string)
		{levels, data} = Reader.read_list(data, &Reader.read_string/1)

		# Array of Keyframe information used for timeline scrubbing (array
		# length followed by each keyframe struct) (Time, Frame, File Position)
		{keyframes, data} = Reader.read_list(data, &Meta.Keyframe.read/1)

		# Array of bytes that is the bulk of the data. This is the raw network
		# stream. (array length followed by a bunch of bytes)
		<< netstream_bytes :: little-unsigned-integer-size(32), data :: binary >> = data
		netstream_bits = netstream_bytes * 8
		<< netstream :: bits-size(netstream_bits), data :: binary >> = data

		# Array of debugging logs (strings). This reminds me that I should
		# probably turn these off to make the replays smaller.
		# (array length followed by each string)
		{messages, data} = Reader.read_list(data, &Meta.Message.read/1)

		# Array of information used to display the Tick marks in the replay
		# (goal scores). (array length followed by each tick struct) (Type, Frame)
		{marks, data} = Reader.read_list(data, &Meta.Mark.read/1)

		# Array of strings of replicated Packages
		{packages, data} = Reader.read_list(data, &Reader.read_string/1)

		# Array of strings for the Object table. Whenever a persistent object
		# gets referenced in the network stream its path gets added to this
		# array. Then its index in this array is used in the network stream.
		{object_map_nodes, data} = Reader.read_list(data, &Reader.read_string/1)
		object_map = Enum.into(Enum.with_index(object_map_nodes), %{}, fn({v, k}) -> {k, v} end)

		# Array of strings for the Name table. "Names" are commonly used strings
		# that get assigned an integer for use in the network stream.
		{names, data} = Reader.read_list(data, &Reader.read_string/1)

		# Map of string, integer pairs for the Class Index Map. Whenever a class
		# is used in the network stream it is given an integer id by this map.
		{class_map_nodes, data} = Reader.read_list(data, &Meta.ClassMapNode.read/1)
		class_map = Enum.reduce(class_map_nodes, %{},
			fn(class_map_node, acc) ->
				Map.put(acc, class_map_node.netstream_id, class_map_node.name)
			end
		)

		# "Class Net Cache Map" maps each replicated property in a class to an
		# integer id used in the network stream.
		{cache, data} = Reader.read_list(data,
			fn(data) -> Meta.CacheNode.read(data, object_map) end
		)
		class_property_map = Meta.generate_class_property_map(class_map, cache)

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
