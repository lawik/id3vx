defmodule Id3vx.MixProject do
  use Mix.Project

  def project do
    [
      app: :id3vx,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    if Mix.env() in [:dev, :test] do
      [
        extra_applications: [:logger, :xmerl]
      ]
    else
      [
        extra_applications: [:logger]
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:feeder_ex, only: [:dev, :test]},
      {:req, "~> 0.2.2", only: [:dev, :test]}
    ]
  end
end
