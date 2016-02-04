defmodule Gizmo.Meta.ClassMapNode do
	alias Gizmo.Meta.ClassMapNode, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:name,
		:netstream_id
	]

	def read(data) do
		{name, data} = Reader.read_string(data)
		<< netstream_id :: little-unsigned-integer-size(32), data :: binary >> = data
		{%Self{
			name: name,
			netstream_id: netstream_id
		}, data}
	end
end
