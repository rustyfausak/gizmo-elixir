defmodule Gizmo.Reader do
	use Bitwise

	@moduledoc """
	Handle reading basic types from a Rocket League replay binary file. The `data`
	parameter in these functions represents the binary file.
	"""

	@doc """
	Returns the number of bits needed to represent the given `int`.
	"""
	def bitsize(int) do
		int
		|> :math.log2
		|> Float.ceil
		|> trunc
	end

	@doc """
	"""
	def read_serialized_int(data, max_value) do
		max_bits = bitsize(max_value)
		_read_serialized_int(data, max_value, max_bits)
	end

	def _read_serialized_int(data, max_value, max_bits, i \\ 0, value \\ 0) do
		if i < max_bits && (value + (bsl(1, i)) <= max_value) do
			<< bit :: size(1), data :: bits >> = data
			if bit == 1 do
				value = value + (bsl(1, i))
			end
			_read_serialized_int(data, max_value, max_bits, i + 1, value)
		else
			{value, data}
		end
	end

	@doc """
	Reverses the bit ordering of each byte in `data`.

	Returns bits.
	"""
	def reverse_bytewise(data) do
		if byte_size(data) > 0 do
			<<
				byte :: bits-size(8),
				data :: bits
			>> = data
			reverse_bits(byte) <> reverse_bytewise(data)
		else
			<<>>
		end
	end

	@doc """
	Reverses the bits of the binary `data`.

	Returns bits.
	"""
	def reverse_bits(data) do
		reverse_bits(data, <<>>)
	end

	def reverse_bits(<<>>, acc) do
		acc
	end

	def reverse_bits(<< b :: bits-size(1), data :: bits >>, acc) do
		reverse_bits(data, << b :: bits-size(1), acc :: bits >>)
	end

	@doc """
	Reverses the first `n` bits from `data` then reads a float from it.

	Returns a tuple of `{float, bits}`
	"""
	def read_rev_float(data, n \\ 32) do
		<< b :: bits-size(n), data :: bits >> = data
		<< b :: float-size(n) >> = reverse_bits(b)
		{b, data}
	end

	@doc """
	Reverses the first `n` bits from `data`  then reads an int from it.

	Returns a tuple of `{int, bits}`
	"""
	def read_rev_int(data, n \\ 32) do
		<< b :: bits-size(n), data :: bits >> = data
		<< b :: unsigned-integer-size(n) >> = reverse_bits(b)
		{b, data}
	end

	@doc """
	Read a list. Each item is read using the function `read_element`.

	Returns a tuple of `{list, data}`.
	"""
	def read_list(data, read_element) do
		<< length :: little-unsigned-integer-size(32), data :: bits >> = data
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
	def read_string(<< _ :: size(8), data :: bits >>, string, n, _read_char) when n <= 1 do
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
	def read_string(<< length :: little-integer-size(32), data :: bits >>) do
		if length > 0 do
			read_string(data, [], length, &read_char/1)
		else
			read_string(data, [], length * 2, &read_utf16_char/1)
		end
	end

	def read_rev_string(data) do
		{length, data} = read_rev_int(data)
		if length > 0 do
			read_string(data, [], length, &read_rev_char/1)
		else
			read_string(data, [], length * 2, &read_rev_utf16_char/1)
		end
	end

	@doc """
	Read a UTF-8 character.

	Returns a tuple of `{char, data}`.
	"""
	def read_char(<< char :: utf8, data :: bits >>) do
		{char, data}
	end
	def read_rev_char(<< b :: bits-size(8), data :: bits >>) do
		<< char :: bits-size(8) >> = reverse_bits(b)
		{char, data}
	end

	@doc """
	Read a UTF-16 character.

	Returns a tuple of `{char, data}`.
	"""
	def read_utf16_char(<< char :: utf16, data :: bits >>) do
		{char, data}
	end
	def read_rev_utf16_char(<< b :: bits-size(16), data :: bits >>) do
		<< char :: utf16 >> = reverse_bytewise(b)
		{char, data}
	end
end
