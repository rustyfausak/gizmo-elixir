defmodule Gizmo.Meta.Message do
	alias Gizmo.Meta.Message, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:frame,
		:name,
		:content
	]

	def read(data) do
		<< frame :: little-unsigned-integer-size(32), data :: binary >> = data
		{name, data} = Reader.read_string(data)
		{content, data} = Reader.read_string(data)
		{%Self{
			frame: frame,
			name: name,
			content: content
		}, data}
	end
end
