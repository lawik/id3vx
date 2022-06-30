defmodule Id3vx.MixProject do
  use Mix.Project

  def project do
    [
      app: :id3vx,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Id3vx",
      source_url: "https://github.com/changelog.com/id3vx",
      # homepage_url: "http://github.com/changelog.com/id3vx",
      docs: [
        # The main page in the docs
        main: "Id3vx",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
