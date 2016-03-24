defmodule Gizmo.Meta.Keyframe do
	alias Gizmo.Meta.Keyframe, as: Self

	defstruct [
		:time,
		:frame,
		:position
	]

	def read(data) do
		<< time :: little-float-size(32), data :: binary >> = data
		<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
		<< position :: little-unsigned-integer-size(32), data :: binary >> = data
		{%Self{
			time: time,
			frame: frame,
			position: position
		}, data}
	end

	def format(keyframe) do
		to_string(["t:", to_string(Float.round(keyframe.time, 3)), ", f:", to_string(keyframe.frame), ", p:", to_string(keyframe.position)])
	end
end
