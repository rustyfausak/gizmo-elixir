defmodule Gizmo.CLI do

	@moduledoc """
	Handle the command line parsing and the dispatch.
	"""
	def main(argv) do
		argv
		|> parse_args
		|> process
	end

	@doc """
	`argv` can be -h or --help, which returns :help.

	Otherwise it is a path to a Rocket League replay file.

	Return a string `path`, or `:help` if help was given.
	"""
	def parse_args(argv) do
		parse = OptionParser.parse(
			argv,
			switches: [help: :boolean],
			aliases: [h: :help]
		)
		case parse do
			{[help: true], _, _} -> :help
			{_, [path], _} -> path
			_ -> :help
		end
	end

	def process(:help) do
		IO.puts """
		usage: gizmo <path>
		"""
		System.halt(0)
	end

	def process(path) do
		Gizmo.Parser.parse(path)
	end
end
