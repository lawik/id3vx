#!/usr/bin/env elixir

labels =
  "priv/frame-labels.txt"
  |> File.read!()
  |> String.split("\n")
  |> Enum.map(fn line ->
    line = String.trim(line)

    if line != "" do
      <<id::binary-size(4), _::binary-size(1), label::binary>> = line
      {id, label}
    else
      nil
    end
  end)
  |> Enum.reject(&is_nil/1)
  |> Map.new()

doc = ~s(
  @moduledoc """
  Provides the full set of frames and their labels.

  Generated from priv/generate-labels.exs.
  """
)

module = """
defmodule Id3vx.Frame.Labels do
  #{doc}

  @labels #{inspect(labels, limit: :infinity)}

  def from_id(id) do
    @labels[id]
  end
end
"""

filepath = "lib/id3vx/frame/labels.ex"
File.write!(filepath, module)

System.cmd("mix", ["format", filepath])
