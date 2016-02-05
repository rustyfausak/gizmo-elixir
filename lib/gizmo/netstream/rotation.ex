defmodule Gizmo.Netstream.Rotation do
	alias Gizmo.Netstream.Rotation, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:pitch,
		:yaw,
		:roll
	]

	def read(data) do
		{%Self{}, data}
	end
end
