defmodule Parallex.Mixfile do
  use Mix.Project

  def project do
    [ app: :parallex,
      version: "0.0.1",
      elixir: "~> 0.14.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: []]
    # [mod: { Parallex, [] }]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps do
    [
      # {:poolboy, "~> 1.1.0",[github: "devinus/poolboy", tag: "1.1.0"]}
    ]
  end
end
