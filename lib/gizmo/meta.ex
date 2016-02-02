defmodule Gizmo.Meta do
	alias Gizmo.Reader, as: Reader

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

	@doc """
	`class_map` is a map: `%{netstream_id => name, ..}`
	`cache` is a list of CacheNode: `[%CacheNode{..}, ..]`

	Returns a map of map:
		`%{class_netstream_id => %{property_netstream_id => name, ..}, ..}`
	"""
	def generate_class_property_map(class_map, cache) do
		Enum.reduce(class_map, %{}, fn({netstream_id, name}, acc) ->
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

	defmodule ClassMapNode do
		defstruct [
			:name,
			:netstream_id
		]

		def read(data) do
			{name, data} = Reader.read_string(data)
			<< netstream_id :: little-size(32), data :: binary >> = data
			{%ClassMapNode{
				name: name,
				netstream_id: netstream_id
			}, data}
		end
	end

	defmodule CacheNodeProperty do
		defstruct [
			:netstream_id,
			:name
		]

		def read(data, object_map) do
			<< object_id :: little-unsigned-integer-size(32), data :: binary >> = data
			<< netstream_id :: little-unsigned-integer-size(32), data :: binary >> = data
			{%CacheNodeProperty{
				netstream_id: netstream_id,
				name: Map.fetch!(object_map, object_id)
			}, data}
		end
	end

	defmodule CacheNode do
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
			{%CacheNode{
				class_id: class_id,
				parent_cache_id: parent_cache_id,
				cache_id: cache_id,
				property_map: property_map
			}, data}
		end
	end

	defmodule Property do
		defstruct [
			:type,
			:size,
			:value
		]

		def read(data) do
			{type, data} = Reader.read_string(data)
			<< size :: little-unsigned-integer-size(64), data :: binary >> = data
			{value, data} = case to_string(type) do
				"ArrayProperty" ->
					{x, data} = Reader.read_list(data, fn x -> Reader.read_property_map(x, &read/1) end)
					{x, data}
				"BoolProperty" ->
					<< x :: little-unsigned-integer-size(8), data :: binary >> = data
					{if x == 1 do true else false end, data}
				"ByteProperty" ->
					{key, data} = Reader.read_string(data)
					{value, data} = Reader.read_string(data)
					{{key, value}, data}
				"FloatProperty" ->
					<< x :: little-float-size(32), data :: binary >> = data
					{x, data}
				"IntProperty" ->
					<< x :: little-signed-integer-size(32), data :: binary >> = data
					{x, data}
				"NameProperty" ->
					{x, data} = Reader.read_string(data)
					{x, data}
				"QWordProperty" ->
					# not sure about the type here
					<< x :: little-size(64), data :: binary >> = data
					{x, data}
				"StrProperty" ->
					{x, data} = Reader.read_string(data)
					{x, data}
				_ -> raise "unknown property type #{type}"
			end
			{%Property{
				type: type,
				size: size,
				value: value
			}, data}
		end
	end

	defmodule Keyframe do
		defstruct [
			:time,
			:frame,
			:position
		]

		def read(data) do
			<< time :: little-float-size(32), data :: binary >> = data
			<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
			<< position :: little-unsigned-integer-size(32), data :: binary >> = data
			{%Keyframe{
				time: time,
				frame: frame,
				position: position
			}, data}
		end
	end

	defmodule Message do
		defstruct [
			:frame,
			:name,
			:content
		]

		def read(data) do
			<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
			{name, data} = Reader.read_string(data)
			{content, data} = Reader.read_string(data)
			{%Message{
				frame: frame,
				name: name,
				content: content
			}, data}
		end
	end

	defmodule Mark do
		defstruct [
			:type,
			:frame
		]

		def read(data) do
			{type, data} = Reader.read_string(data)
			<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
			{%Mark{
				type: type,
				frame: frame
			}, data}
		end
	end
end
