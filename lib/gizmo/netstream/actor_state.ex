defmodule Gizmo.Netstream.ActorState do
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Netstream.ActorState, as: Self
	alias Gizmo.Netstream.ClassInit, as: ClassInit
	alias Gizmo.Netstream.Property, as: Property
	alias Gizmo.Reader, as: Reader

	defstruct [
		:unknown1, # property flag?
		:object_id,
		:object_name,
		:class_id,
		:class_name,
		:class_init,
		:properties
	]

	@doc """
	Some data for how to reference the actor. If it's a static actor (placed
	in level), then this puts his integer ID from the object table. If it's a
	dynamic actor, it puts the integer id for his "archetype", along with
	optional initial location (vector) and rotation (3 bytes for pitch, yaw,
	roll). Not all actors need this initial location and rotation so not all
	actors serialize it.
	"""
	def read_new(data, meta) do
		<< unknown1 :: size(1), data :: bits >> = data
		{object_id, data} = Reader.read_rev_int(data, 32)
		object_name = Map.fetch!(meta.object_map, object_id)
		{class_id, class_name} = Meta.get_class(meta.object_map, object_id)
		{class_init, data} = ClassInit.read(class_name, data)
		{%Self{
			unknown1: unknown1,
			object_id: object_id,
			object_name: object_name,
			class_id: class_id,
			class_name: class_name,
			class_init: class_init
		}, data}
	end

	@doc """
	Property values for each replicating actor. We only serialize property
	values that have changed since the last frame, unless this is a keyframe
	in which we serialize all replicated properties.
	"""
	def read_existing(data, meta, num_properties) do
		{%Self{
			properties: read_properties(data, meta, num_properties)
		}, data}
	end

	def read_properties(data, meta, num_properties) do
		Enum.reverse(_read_properties(data, meta, num_properties))
	end

	def _read_properties(data, meta, num_properties) do
		<< property_flag :: size(1), data :: bits >> = data
		if property_flag == 1 do
			{property, data} = Property.read(data, meta, num_properties)
			[property | _read_properties(data, meta, num_properties)]
		else
			[]
		end
	end
end
