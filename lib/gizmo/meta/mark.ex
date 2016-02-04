defmodule Gizmo.Meta.Mark do
	alias Gizmo.Meta.Mark, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:type,
		:frame
	]

	def read(data) do
		{type, data} = Reader.read_string(data)
		<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
		{%Self{
			type: type,
			frame: frame
		}, data}
	end
end
