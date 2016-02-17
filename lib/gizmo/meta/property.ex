defmodule Gizmo.Meta.Property do
	alias Gizmo.Meta.Property, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:type,
		:size,
		:value
	]

	def format_map(property_map, depth \\ 1) do
		to_string(["\n"] ++ Enum.reduce(
			property_map,
			[],
			fn({k, property}, acc) ->
				[
					String.duplicate(" ", depth * 2),
					String.rjust("#{k} => ", 20),
					Self.format(property, depth),
					"\n"
				] ++ acc
			end
		))
	end

	def format(property, depth \\ 1) do
		case to_string(property.type) do
			"ArrayProperty" ->
				to_string(["\n", Self.format_map(List.first(property.value), depth + 1)])
			"BoolProperty" ->
				if property.value == true do
					"TRUE"
				else
					"FALSE"
				end
			"ByteProperty" ->
				to_string(Tuple.to_list(property.value))
			_ ->
				to_string(property.value)
		end
	end

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
			_ -> raise "Unknown Gizmo.Meta.Property.type '#{type}'"
		end
		{%Self{
			type: type,
			size: size,
			value: value
		}, data}
	end
end
