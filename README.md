# gizmo-elixir

**A Rocket League replay parser in Elixir.**

## Escript Build

Windows

```
$ mix escript.build
$ escript gizmo.es <replay path>
```

or

```
$ run.bat <replay path>
```

Unix

```
$ mix escript.build
$ ./gizmo.es <replay path>
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add gizmo to your list of dependencies in `mix.exs`:

        def deps do
          [{:gizmo, "~> 0.0.1"}]
        end

  2. Ensure gizmo is started before your application:

        def application do
          [applications: [:gizmo]]
        end

