defmodule Id3vx.MixProject do
  use Mix.Project

  def project do
    [
      app: :id3vx,
      version: "0.0.1-rc5",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Id3vx",
      description: "Read and Write ID3 tags with Chapter support (ID3v2.3)",
      source_url: "https://github.com/thechangelog/id3vx",
      docs: [
        # The main page in the docs
        main: "Id3vx",
        extras: ["README.md"]
      ],
      package: [
        name: :id3vx,
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/thechangelog/id3vx"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
