defmodule Id3vx.Utils do
  @moduledoc false

  def pad_to_byte_size(not_binary, size) when not is_binary(not_binary) do
    pad_to_byte_size(<<not_binary>>, size)
  end

  def pad_to_byte_size(binary, size) do
    if byte_size(binary) >= size do
      binary
    else
      pad_to_byte_size(<<0>> <> binary, size)
    end
  end

  def to_flag_int(truth?) when truth?, do: 1
  def to_flag_int(truth?) when not truth?, do: 0

  def flip_map(m) do
    Map.new(m, fn {key, val} -> {val, key} end)
  end
end
