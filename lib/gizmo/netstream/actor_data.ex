defmodule Gizmo.Netstream.ActorData do
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Netstream.ActorData, as: Self
	alias Gizmo.Netstream.ClassInit, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:unknown1,
		:object_id,
		:object_name,
		:class_name,
		:class_init
	]

	# Some data for how to reference the actor. If it's a static actor (placed
	# in level), then this puts his integer ID from the object table. If it's a
	# dynamic actor, it puts the integer id for his "archetype", along with
	# optional initial location (vector) and rotation (3 bytes for pitch, yaw,
	# roll). Not all actors need this initial location and rotation so not all
	# actors serialize it.
	def read_new(data, meta) do
		<< unknown1 :: bits-size(1), data :: bits >> = data
		{object_id, data} = Reader.read_rev_int(data, 32)
		object_name = Map.fetch!(meta.object_map, object_id)
		class_name = Meta.get_class(meta.object_map, object_id)
		{class_init, data} = ClassInit.read(class_name, data)
		actor_data = %Self{
			unknown1: unknown1,
			object_id: object_id,
			object_name: object_name,
			class_name: class_name
		}
		IO.inspect actor_data
		System.halt(0)
		{actor_data, data}
	end

	def read_existing(data, meta) do
		{nil, data}
	end
end
