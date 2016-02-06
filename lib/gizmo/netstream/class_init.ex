defmodule Gizmo.Netstream.ClassInit do
	alias Gizmo.Netstream.ClassInit, as: Self
	alias Gizmo.Netstream.Vector, as: Vector

	@classes_with_locations MapSet.new([
		"Engine.GameReplicationInfo",
		"TAGame.CarComponent_Boost_TA",
		"TAGame.CarComponent_Dodge_TA",
		"TAGame.CarComponent_DoubleJump_TA",
		"TAGame.CarComponent_FlipCar_TA",
		"TAGame.CarComponent_Jump_TA",
		"TAGame.GameEvent_Season_TA",
		"TAGame.GameEvent_Soccar_TA",
		"TAGame.GameEvent_SoccarPrivate_TA",
		"TAGame.GameEvent_SoccarSplitscreen_TA",
		"TAGame.GRI_TA",
		"TAGame.Default__PRI_TA",
		"TAGame.PRI_TA",
		"TAGame.Team_TA",
		"TAGame.Team_Soccar_TA",
		"TAGame.Ball_TA",
		"TAGame.Car_TA",
	])

	@classes_with_rotations MapSet.new([
		"TAGame.Ball_TA",
		"TAGame.Car_TA",
		"TAGame.Car_Season_TA"
	])

	defstruct [
		:location,
		:rotation
	]

	def read(class_name, data) do
		class_name = to_string(class_name)
		location = nil
		rotation = nil

		if MapSet.member?(@classes_with_locations, class_name) do
			IO.inspect('read location')
			{location, data} = Vector.read(data)
		end

		if MapSet.member?(@classes_with_rotations, class_name) do
			IO.inspect('read rotation')
			{rotation, data} = Vector.read_bytewise(data)
		end

		{%Self{
			location: location,
			rotation: rotation
		}, data}
	end
end
