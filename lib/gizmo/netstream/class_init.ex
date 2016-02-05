defmodule Gizmo.Netstream.ClassInit do
	alias Gizmo.Netstream.ClassInit, as: Self
	alias Gizmo.Netstream.Rotation, as: Rotation
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
		"TAGame.PRI_TA",
		"TAGame.Team_TA"
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
		if MapSet.member?(@classes_with_locations, class_name) do
			{location, data} = Vector.read(data)
		end

		if MapSet.member?(@classes_with_rotations, class_name) do
			{rotation, data} = Rotation.read(data)
		end

		{%Self{
			location: location,
			rotation: rotation
		}, data}
	end
end
