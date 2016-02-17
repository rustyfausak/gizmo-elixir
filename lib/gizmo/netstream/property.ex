defmodule Gizmo.Netstream.Property do
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Netstream.Property, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:id,
		:stuff
	]

	@doc """
	Properties are read like this:
	 - Compressed property id (max value pulled from the Class Net Cache).
	 - If the property is a static array, serialize the index we are replicating
	   in the static array.
	 - Otherwise, the property's data. Whatever gets serialized here depends on
	   the type of property. Ints, bytes, and strings are obvious. The less
	   obvious ones are structs, and particularly the rigid body state for each
	   car and the ball, which is comprised of several compressed vectors and
	   rotators.
	"""
	def read(data, meta, num_properties) do
		IO.puts "total num properties #{num_properties}"
		{property_id, data} = Reader.read_serialized_int(data, num_properties)
		IO.puts "property_id => #{property_id}"
		property = Map.fetch!(meta.object_map, property_id)
		IO.puts "property => #{property}"
		raise "Dont know how to read actor state properties yet.."
		{%Self{}, data}
	end
end
