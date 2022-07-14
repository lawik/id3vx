defmodule Id3vx.Utils do
  @moduledoc false

  use Bitwise
  alias Id3vx.Error

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

  def unsynchronise_if_needed(data, desynched? \\ false, processed \\ []) do
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
      <<0xFF::8, 1::3, rem::5, rest::binary>> ->
        unsynchronise_if_needed(rest, true, [processed, <<0xFF::8, 0::8, 1::3, rem::5>>])

      <<checked::8, rest::binary>> ->
        # Step one byte forward please
        unsynchronise_if_needed(rest, desynched?, [processed, checked])
    end
  end

  def decode_unsynchronized(data, decoded \\ <<>>)

  # Candidate for decoding
  def decode_unsynchronized(<<0xFF::8, 0x00::8, _::binary>> = data, decoded) do
    if byte_size(data) < 3 do
      # Can't be false sync
      decoded <> data
    else
      {sample, remainder} =
        case data do
          <<sample::binary-size(3)>> -> {sample, <<>>}
          <<sample::binary-size(3), rest::binary>> -> {sample, rest}
          sample -> {sample, <<>>}
        end

      <<0xFF::8, 0x00::8, third::8>> = sample

      fixed =
        case <<third::8>> do
          <<1::3, bits::5>> ->
            <<0xFF, 1::3, bits::5>>

          <<0::8>> ->
            <<0xFF, 0x00>>

          <<any::8>> ->
            <<0xFF, 0x00, any>>
        end

      decoded = decoded <> fixed

      if byte_size(remainder) == 0 do
        decoded
      else
        decode_unsynchronized(remainder, decoded)
      end
    end
  end

  # Final byte
  def decode_unsynchronized(<<byte::8>>, decoded) do
    decoded <> <<byte>>
  end

  # No match, move one byte forward
  def decode_unsynchronized(<<byte::8, data::binary>>, decoded) do
    decoded = decoded <> <<byte>>
    decode_unsynchronized(data, decoded)
  end
end
