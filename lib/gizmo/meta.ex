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
		:class_property_map
	]

	defmodule Property do
		defstruct [
			:type,
			:size,
			:value
		]

		def read(data) do
			{type, data} = Reader.read_string(data)
			<< size :: little-size(64), data :: binary >> = data
			{value, data} = case to_string(type) do
				"ArrayProperty" ->
					{x, data} = Reader.read_list(data, fn x -> Reader.read_property_map(x, &read/1) end)
					{x, data}
				"BoolProperty" ->
					<< x :: little-size(8), data :: binary >> = data
					{if x == 1 do true else false end, data}
				"ByteProperty" ->
					{key, data} = Reader.read_string(data)
					{value, data} = Reader.read_string(data)
					{{key, value}, data}
				"FloatProperty" ->
					<< x :: little-float-size(32), data :: binary >> = data
					{x, data}
				"IntProperty" ->
					<< x :: little-integer-size(32), data :: binary >> = data
					{x, data}
				"NameProperty" ->
					{x, data} = Reader.read_string(data)
					{x, data}
				"QWordProperty" ->
					<< x :: little-size(64), data :: binary >> = data
					{x, data}
				"StrProperty" ->
					{x, data} = Reader.read_string(data)
					{x, data}
				_ -> raise "unknown property type #{type}"
			end
			property = %Property{
				type: type,
				size: size,
				value: value
			}
			{property, data}
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
			keyframe = %Keyframe{
				time: time,
				frame: frame,
				position: position
			}
			{keyframe, data}
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
			message = %Message{
				frame: frame,
				name: name,
				content: content
			}
			{message, data}
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
			mark = %Mark{
				type: type,
				frame: frame
			}
			{mark, data}
		end
	end
end
