defmodule Id3vx.Utils do
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

  def flip_map(m) do
    Map.new(m, fn {key, val} -> {val, key} end)
  end
end
