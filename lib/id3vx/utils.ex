defmodule Id3vx.Utils do
  @moduledoc false

  use Bitwise
  alias Id3vx.Error

  def pad_to_byte_size(not_binary, size) when not is_binary(not_binary) do
    pad_to_byte_size(:binary.encode_unsigned(not_binary, :big), size)
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

  def encode_synchsafe_integer(num) do
    if num > 256 * 1024 * 1024 - 1 do
      throw(%Error{
        message: "Cannot encode synchsafe integer larger than 256*1024*1024 (256 Mb in bytes)",
        context: :encode_synchsafe_integer
      })
    end

    binary_num = <<num::size(28)>>

    <<b4::7, b3::7, b2::7, b1::7>> = binary_num
    <<0::1, b4::7, 0::1, b3::7, 0::1, b2::7, 0::1, b1::7>>
  end

  def decode_synchsafe_integer(<<0::1, _::7, 0::1, _::7, 0::1, _::7, 0::1, _::7>> = binary) do
    # Cribbed from LiveBeats, not entirely sure how it achieves the result
    binary
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {el, index}, acc -> acc ||| el <<< (index * 7) end)
  end

  def unsynchronise_if_needed(data, desynched? \\ false, count \\ 0, processed \\ []) do
    padded? = false

    case data do
      <<>> ->
        {IO.iodata_to_binary(processed), desynched?, padded?}

      <<0xFF::8>> ->
        # Corner-case, pad one null byte
        padded? = true
        desynched? = true
        processed = [processed, 0xFF, 0x00]
        {IO.iodata_to_binary(processed), desynched?, padded?}

      # False synchronisation
      <<0xFF::8, 1::1, 1::1, 1::1, _::5, rest::binary>> = full ->
        # Grab byte with the leading 1's
        <<_::8, rem::8, _::binary>> = full
        unsynchronise_if_needed(rest, true, count + 1, [processed, <<0xFF, 0x00, rem>>])

      # Avoiding misguiding
      <<0xFF::8, 0x00::8, rest::binary>> ->
        unsynchronise_if_needed(rest, true, count + 1, [processed, <<0xFF, 0x00, 0x00>>])

      <<checked::8, rest::binary>> ->
        # Step one byte forward please
        unsynchronise_if_needed(rest, desynched?, count, [processed, checked])
    end
  end

  def decode_unsynchronized(data, count \\ 0, decoded \\ <<>>)
  # End bytes corner case

  def decode_unsynchronized(<<0xFF, 0x00, rest::binary>>, count, decoded) do
    decode_unsynchronized(rest, count + 1, decoded <> <<0xFF>>)
  end

  # No match, move one byte forward
  def decode_unsynchronized(<<byte::8, data::binary>>, count, decoded) do
    decoded = decoded <> <<byte>>
    decode_unsynchronized(data, count, decoded)
  end

  def decode_unsynchronized(<<>>, _count, decoded) do
    decoded
  end

  # False synch to decode/restore
  def _decode_unsynchronized(
        <<0xFF, 0x00, 1::1, 1::1, 1::1, _::5, rest::binary>> = data,
        count,
        decoded
      ) do
    <<_::16, third::8, _::binary>> = data
    decoded = decoded <> <<0xFF, third>>
    decode_unsynchronized(rest, count + 1, decoded)
  end

  # Accident-avoider
  def _decode_unsynchronized(<<0xFF, 0x00, 0x00, rest::binary>>, count, decoded) do
    decoded = decoded <> <<0xFF, 0x00>>
    decode_unsynchronized(rest, count + 1, decoded)
  end
end
