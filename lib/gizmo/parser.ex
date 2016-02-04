defmodule Gizmo.Parser do
	alias Gizmo.Replay, as: Replay

	@doc """
	`path` is a string.

	Returns `Replay`.
	"""
	def parse(path) do
		data = File.read!(path)
		Replay.parse(data)
	end
end
