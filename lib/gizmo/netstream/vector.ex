defmodule Gizmo.Netstream.Vector do
	alias Gizmo.Netstream.Vector, as: Self
	alias Gizmo.Reader, as: Reader

	def read(data) do
		read(20, data)
	end

	def read(max_bits, data) do
		nil
	end
end
