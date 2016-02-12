defmodule Gizmo.Netstream.Property do
	alias Gizmo.Meta, as: Meta
	alias Gizmo.Netstream.Property, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:id
	]

	def read(data, meta) do
		{%Self{}, data}
	end
end
