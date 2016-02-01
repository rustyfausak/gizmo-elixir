defmodule Gizmo.Reader do
	def read_mark(data) do
		{type, data} = read_string(data)
		<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
		mark = %Gizmo.Meta.Mark{
			type: type,
			frame: frame
		}
		{mark, data}
	end

	def read_message(data) do
		<< frame :: little-size(32), data :: binary >> = data
		{name, data} = read_string(data)
		{content, data} = read_string(data)
		message = %Gizmo.Meta.Message{
			frame: frame,
			name: name,
			content: content
		}
		{message, data}
	end

	def read_keyframe(data) do
		<< time :: little-float-size(32), data :: binary >> = data
		<< frame :: little-size(32), data :: binary >> = data
		<< position :: little-size(32), data :: binary >> = data
		keyframe = %Gizmo.Meta.Keyframe{
			time: time,
			frame: frame,
			position: position
		}
		{keyframe, data}
	end

	def read_property(data) do
		{type, data} = read_string(data)
		<< size :: little-size(64), data :: binary >> = data
		{value, data} = case to_string(type) do
			"ArrayProperty" ->
				{x, data} = read_list(data, fn x -> read_map(x, &read_property/1) end)
				{x, data}
				# read_list(data, &read_map(data, &read_property/1)/2)
			"BoolProperty" ->
				<< x :: little-size(8), data :: binary >> = data
				{if x == 1 do true else false end, data}
			"ByteProperty" ->
				{key, data} = read_string(data)
				{value, data} = read_string(data)
				{{key, value}, data}
			"FloatProperty" ->
				<< x :: little-float-size(32), data :: binary >> = data
				{x, data}
			"IntProperty" ->
				<< x :: little-size(32), data :: binary >> = data
				{x, data}
			"NameProperty" ->
				{x, data} = read_string(data)
				{x, data}
			"QWordProperty" ->
				<< x :: little-size(64), data :: binary >> = data
				{x, data}
			"StrProperty" ->
				{x, data} = read_string(data)
				{x, data}
			_ -> raise "unknown property type #{type}"
		end
		property = %Gizmo.Meta.Property{
			type: type,
			size: size,
			value: value
		}
		{property, data}
	end

	def read_list(data, read_element) do
		<< length :: little-unsigned-integer-size(32), data :: binary >> = data
		read_list(data, length, read_element)
	end

	def read_list(data, n, _read_element) when n < 1 do
		{[], data}
	end

	def read_list(data, n, read_element) do
		{element, data} = read_element.(data)
		{list, data} = read_list(data, n - 1, read_element)
		{[element | list] , data}
	end

	def read_map_entry(data, read_value) do
		{key, data} = read_string(data)
		if key == 'None' do
			{nil, nil, data}
		else
			{value, data} = read_value.(data)
			{key, value, data}
		end
	end

	def read_map(data, read_value) do
		{key, value, data} = read_map_entry(data, read_value)
		if key && value do
			{new_dictionary, data} = read_map(data, read_value)
			dictionary = Map.merge(
				%{key => value},
				new_dictionary
			)
			{dictionary, data}
		else
			{%{}, data}
		end
	end

	def read_string(data, string, n, _match) when n <= 1 do
		# Read the null terminator for the string
		<< _ :: size(8), data :: binary >> = data
		{string, data}
	end

	def read_string(data, string, n, match) do
		{char, data} = match.(data)
		read_string(data, string ++ [char], n - 1, match)
	end

	def read_string(<< length :: little-unsigned-integer-size(32), data :: binary >>) do
		if length > 0 do
			read_string(data, [], length, &read_utf8_char/1)
		else
			read_string(data, [], length * 2, &read_utf16_char/1)
		end
	end

	def read_utf8_char(data) do
		<< char :: utf8, data :: binary >> = data
		{char, data}
	end

	def read_utf16_char(data) do
		<< char :: utf16, data :: binary >> = data
		{char, data}
	end
end
