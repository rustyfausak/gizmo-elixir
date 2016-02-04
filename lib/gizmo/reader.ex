defmodule Gizmo.Reader do
	@moduledoc """
	Handle reading basic types from a Rocket League replay binary file. The `data`
	parameter in these functions represents the binary file.
	"""

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

	def reverse_bits(<<>>, acc) do
		acc
	end

	def reverse_bits(<< h :: size(1), data :: bits >>, acc) do
		reverse_bits(data, << h :: size(1), acc :: bits >>)
	end

	@doc """
	Read a list. Each item is read using the function `read_element`.

	Returns a tuple of `{list, data}`.
	"""
	def read_list(data, read_element) do
		<< length :: little-unsigned-integer-size(32), data :: binary >> = data
		read_list(data, length, read_element)
	end

	@doc """
	Base case for `read_list` recursion.

	Returns a tuple of `{list, data}`.
	"""
	def read_list(data, n, _read_element) when n < 1 do
		{[], data}
	end

	@doc """
	Read a list of `n` elements. Each item is read using the function `read_element`.

	Returns a tuple of `{list, data}`.
	"""
	def read_list(data, n, read_element) do
		{element, data} = read_element.(data)
		{list, data} = read_list(data, n - 1, read_element)
		{[element | list] , data}
	end

	@doc """
	Read a property map entry using the function `read_value` for the value of the
	key/value pair.

	Returns a tuple of `{key, value, data}`.
	"""
	def read_property_map_entry(data, read_value) do
		{key, data} = read_string(data)
		if key == 'None' do
			{nil, nil, data}
		else
			{value, data} = read_value.(data)
			{key, value, data}
		end
	end

	@doc """
	Read a property map. Each value in the key/value pairs is read using the
	function `read_value`. Reads until a key of `None` is read.

	Returns a map.
	"""
	def read_property_map(data, read_value) do
		{key, value, data} = read_property_map_entry(data, read_value)
		if key && value do
			{map, data} = read_property_map(data, read_value)
			{Map.put(map, key, value), data}
		else
			{%{}, data}
		end
	end

	@doc """
	Read the null terminator for a string. Base case for `read_string` recursion.

	Returns a tuple of `{string, data}`.
	"""
	def read_string(<< _ :: size(8), data :: binary >>, string, n, _read_char) when n <= 1 do
		{string, data}
	end

	@doc """
	Read a character using the function `read_char` off the string.

	Returns a tuple of `{string, data}`.
	"""
	def read_string(data, string, n, read_char) do
		{char, data} = read_char.(data)
		read_string(data, string ++ [char], n - 1, read_char)
	end

	@doc """
	Read an integer specifying the size of the string, then recursively read
	a string of that size.

	Returns a tuple of `{string, data}`.
	"""
	def read_string(<< length :: little-unsigned-integer-size(32), data :: binary >>) do
		if length > 0 do
			read_string(data, [], length, &read_utf8_char/1)
		else
			read_string(data, [], length * 2, &read_utf16_char/1)
		end
	end

	@doc """
	Read a UTF-8 character.

	Returns a tuple of `{char, data}`.
	"""
	def read_utf8_char(<< char :: utf8, data :: binary >>) do
		{char, data}
	end

	@doc """
	Read a UTF-16 character.

	Returns a tuple of `{char, data}`.
	"""
	def read_utf16_char(<< char :: utf16, data :: binary >>) do
		{char, data}
	end
end
