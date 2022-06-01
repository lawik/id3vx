defmodule Id3vx do
  @moduledoc """
  Documentation for `Id3vx`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Id3vx.hello()
      :world

  """

  use Bitwise
  require Logger

  defmodule Tag do
    defstruct version: nil,
              revision: nil,
              flags: nil,
              size: nil,
              extended_header: nil,
              footer: nil,
              frames: nil
  end

  defmodule TagFlags do
    defstruct unsynchronisation: nil, extended_header: nil, experimental: nil, footer: nil
  end

  defmodule ExtendedHeaderV4 do
    defstruct size: nil, flag_bytes: nil, flags: nil
  end

  defmodule ExtendedHeaderV3 do
    defstruct size: nil, flags: nil, padding: nil
  end

  defmodule ExtendedHeaderFlags do
    defstruct is_update: nil,
              crc_data_present: nil,
              tag_restrictions: nil
  end

  defmodule FrameFlags do
    defstruct tag_alter_preservation: nil,
              file_alter_preservation: nil,
              read_only: nil,
              grouping_identity: nil,
              compression: nil,
              encryption: nil,
              unsynchronisation: nil,
              data_length_indicator: nil
  end

  alias Id3vx.Tag
  alias Id3vx.TagFlags
  alias Id3vx.ExtendedHeaderV4
  alias Id3vx.ExtendedHeaderV3
  alias Id3vx.ExtendedHeaderFlags
  alias Id3vx.Frame
  alias Id3vx.FrameFlags
  alias Id3vx.Frame.Labels
  alias Id3vx.Utils

  @parse_states [
    :parse_prepend_tag,
    :seek_tag,
    :parse_extended_header,
    :parse_extended_header_flags,
    :parse_frames,
    :skip_padding,
    :parse_footer,
    :parse_append_tag,
    :done
  ]

  def parse_file(path) do
    binary = File.read!(path)
    parse_binary(binary)
  end

  def parse_binary(<<binary::binary>>) do
    {<<>>, binary}
    |> parse
  end

  def get_tag_binary(<<binary::binary>>) do
    <<header::binary-size(10), rest::binary>> = binary
    {:ok, tag} = parse_tag(header)
    tag_size = tag.size
    <<body::binary-size(tag_size), _::binary>> = rest
    header <> body
  end

  def encode_tag(%Tag{version: 3} = tag) do
    frames = encode_frames(tag)

    # TODO: Proper flag encoding
    flags = <<0x00>>
    tag_size = frames |> byte_size() |> encode_synchsafe_integer()

    IO.iodata_to_binary([
      "ID3",
      <<tag.version>>,
      <<tag.revision>>,
      flags,
      tag_size,
      frames
    ])
  end

  def encode_frames(%Tag{frames: []}) do
    # TODO: proper error
    raise "Cannot generate an empty ID3 tag"
  end

  def encode_frames(%Tag{frames: frames} = tag) do
    Enum.reduce(frames, <<>>, fn frame, acc ->
      acc <> Frame.encode_frame(frame, tag)
    end)
  end

  def get_bytes({used, unused}, bytes) do
    <<data::binary-size(bytes), rest::binary>> = unused
    {data, {used <> data, rest}}
  end

  def parse(source) do
    iterate(source, :parse_prepend_tag, nil)
  end

  def iterate(source, step, state) do
    state_number = Enum.find_index(@parse_states, fn s -> s == step end) + 1
    Logger.debug("Parser step ##{state_number}: #{step}")

    case parse_step(source, step, state) do
      {:done, result} -> result
      {next_step, source, state} -> iterate(source, next_step, state)
    end
  end

  defp parse_step(source, :parse_prepend_tag, _) do
    {data, source} = get_bytes(source, 10)

    case parse_tag(data) do
      {:ok, tag} ->
        if tag.flags.extended_header do
          {:parse_extended_header, source, tag}
        else
          {:parse_frames, source, tag}
        end

      :not_found ->
        {:done, {:error, :not_found}}
    end
  end

  # TODO: For ID3v2.3 we need to unsynchronize all the bytes before parsing further

  defp parse_step(source, :parse_extended_header, tag) do
    {data, source} = get_bytes(source, 6)
    ext_header = parse_extended_header_fixed(tag, data)
    tag = %{tag | extended_header: ext_header}
    # Implement rest of ext header parsing, for now, we pull the data
    # to get it out of the way and that's a way to just skip the extended
    # header
    {_data, source} =
      case tag.version do
        # Different calculations, same results
        4 ->
          get_bytes(source, ext_header.size - 6)

        3 ->
          if tag.flags.unsynchronisation, do: raise("v3 unsynchronization not implemented!")
          get_bytes(source, ext_header.size - 6)
      end

    # TODO: Actually handle the extended header
    # {:parse_extended_header_flags, source, tag}

    {:parse_frames, source, tag}
  end

  defp parse_step(source, :parse_frames, %{version: 4} = tag) do
    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)

    {data, source} = get_bytes(source, frames_size)

    data =
      if tag.flags.unsynchronisation do
        decode_unsynchronized(data)
      else
        data
      end

    frames = parse_frames(tag, data)
    tag = %{tag | frames: frames}

    if tag.flags.footer do
      {:parse_footer, source, tag}
    else
      {:skip_padding, source, tag}
    end
  end

  defp parse_step(source, :parse_frames, %{version: 3} = tag) do
    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)

    {data, source} = get_bytes(source, frames_size)

    data =
      if tag.flags.unsynchronisation do
        decode_unsynchronized(data)
      else
        data
      end

    frames = parse_frames(tag, data, [])
    tag = %{tag | frames: frames}

    if tag.flags.footer do
      {:parse_footer, source, tag}
    else
      {:skip_padding, source, tag}
    end
  end

  defp parse_step(_source, step, state) do
    Logger.warn("Step not implemented #{step}")
    {:done, {:ok, state}}
  end

  def parse_tag(
        <<"ID3", 4::integer, minor::integer, unsynchronisation::size(1), extended_header::size(1),
          experimental::size(1), footer::size(1), _unused::size(4), tag_size::binary-size(4)>>
      ) do
    flags = %TagFlags{
      unsynchronisation: unsynchronisation == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1,
      footer: footer == 1
    }

    tag_size = decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: 4, revision: minor, flags: flags, size: tag_size}}
  end

  def parse_tag(
        <<"ID3", 3::integer, minor::integer, flag_bytes::size(8), tag_size::binary-size(4)>>
      ) do
    <<unsynchronisation::size(1), extended_header::size(1), experimental::size(1),
      _unused::size(5)>> = <<flag_bytes>>

    flags = %TagFlags{
      unsynchronisation: unsynchronisation == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1
    }

    tag_size = decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: 3, revision: minor, flags: flags, size: tag_size}}
  end

  def parse_tag(_bin) do
    :not_found
  end

  def parse_extended_header_fixed(
        %{version: 4},
        <<size::binary-size(4), _::binary-size(1), _::size(1), is_update::size(1),
          crc_data_present::size(1), tag_restrictions::size(1), _unused::size(4)>>
      ) do
    %ExtendedHeaderV4{
      size: decode_synchsafe_integer(size),
      flag_bytes: 0x01,
      flags: %ExtendedHeaderFlags{
        is_update: is_update == 1,
        crc_data_present: crc_data_present == 1,
        tag_restrictions: tag_restrictions == 1
      }
    }
  end

  def parse_extended_header_fixed(
        %{version: 3},
        <<size::binary-size(4), crc_data_present::1, _::15, _padding_size::binary-size(4)>>
      ) do
    %ExtendedHeaderV3{
      size: size,
      flags: %ExtendedHeaderFlags{
        crc_data_present: crc_data_present == 1
      }
    }
  end

  def parse_frames(tag, frames_data, frames \\ [])

  def parse_frames(%{version: 4} = tag, frames_data, frames) do
    # A tag must have at least one frame, a frame must have at least one byte
    # in it after the header
    <<id::binary-size(4), frame_size::binary-size(4), flags::binary-size(2), frames_data::binary>> =
      frames_data

    decoded_frame_size = decode_synchsafe_integer(frame_size)

    {frame_data, frames_data} =
      case frames_data do
        <<frame_data::binary-size(decoded_frame_size)>> -> {frame_data, <<>>}
        <<frame_data::binary-size(decoded_frame_size), rest::binary>> -> {frame_data, rest}
      end

    flags = parse_frame_flags(flags)

    {frames, continue?} =
      case parse_frame(tag, id, decoded_frame_size, flags, frame_data) do
        {:frame, frame} -> {[frame | frames], true}
        :not_found -> {frames, false}
      end

    # Does it contain enough data for another frame?
    if continue? and byte_size(frames_data) > 10 do
      parse_frames(tag, frames_data, frames)
    else
      Enum.reverse(frames)
    end
  end

  def parse_frames(%{version: 3} = tag, frames_data, frames) do
    # A tag must have at least one frame, a frame must have at least one byte
    # in it after the header
    <<id::binary-size(4), frame_size::binary-size(4), flags::binary-size(2), frames_data::binary>> =
      frames_data

    frame_size = :binary.decode_unsigned(frame_size, :big)

    {frames_data, frames, continue?} =
      cond do
        not Regex.match?(~r/[A-Z0-9]{4}/, id) ->
          Logger.warn("Invalid frame ID. Weird.")
          {frames_data, frames, false}

        byte_size(frames_data) < frame_size ->
          Logger.warn("Frame data is less than parsed size field. Weird.")
          {frames_data, frames, false}

        true ->
          {frame_data, frames_data} =
            case frames_data do
              <<frame_data::binary-size(frame_size)>> -> {frame_data, <<>>}
              <<frame_data::binary-size(frame_size), rest::binary>> -> {frame_data, rest}
            end

          flags = parse_frame_flags(flags)

          case parse_frame(tag, id, frame_size, flags, frame_data) do
            {:frame, frame} ->
              {frames_data, [frame | frames], true}

            :not_found ->
              {frames_data, frames, false}
          end
      end

    # Does it contain enough data for another frame?
    if continue? and byte_size(frames_data) > 10 do
      parse_frames(tag, frames_data, frames)
    else
      Enum.reverse(frames)
    end
  end

  def parse_frame_flags(flags) do
    <<0::1, tap::1, fap::1, ro::1, 0::5, gi::1, 0::2, c::1, e::1, u::1, dli::1>> = flags

    %FrameFlags{
      tag_alter_preservation: tap == 1,
      file_alter_preservation: fap == 1,
      read_only: ro == 1,
      grouping_identity: gi == 1,
      compression: c == 1,
      encryption: e == 1,
      unsynchronisation: u == 1,
      data_length_indicator: dli == 1
    }
  end

  def parse_frame(%{version: 3} = tag, id, size, flags, data) do
    frame = Frame.parse(id, tag, flags, data)
    {:frame, %{frame | size: size, flags: flags, label: Labels.from_id(frame.id)}}
  end

  def parse_frame(%Tag{version: 4} = tag, id, size, flags, data) do
    data =
      if flags.unsynchronisation do
        decode_unsynchronized(data)
      else
        data
      end

    frame = Frame.parse(id, tag, flags, data)
    {:frame, %{frame | size: size, flags: flags}}
  end

  defp subtract_extended_header(size, %{
         flags: %{extended_header: true},
         extended_header: %{size: ex_size}
       }) do
    size - ex_size
  end

  defp subtract_extended_header(size, _) do
    size
  end

  defp subtract_footer(size, %{flags: %{footer: true}}) do
    size - 10
  end

  defp subtract_footer(size, _) do
    size
  end

  def encode_synchsafe_integer(num) do
    if num > 256 * 1024 * 1024 - 1 do
      # TODO: Better error
      raise "Cannot encode synchsafe integer larger than 256*1024*1024 (256 Mb in bytes)"
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

  def decode_unsynchronized(data, decoded \\ <<>>)

  # Candidate for decoding
  def decode_unsynchronized(<<0xFF::8, 0x00::8, _::binary>> = data, decoded) do
    {sample, remainder} =
      case data do
        <<sample::binary-size(3)>> -> {sample, <<>>}
        <<sample::binary-size(3), rest::binary>> -> {sample, rest}
      end

    <<0xFF::8, 0x00::8, third::8>> = sample

    fixed =
      case third do
        <<1::3, bits::5>> ->
          <<0xFF, 1::3, bits::5>>

        <<0::8>> ->
          <<0xFF, 0x00>>

        any ->
          <<0xFF, 0x00, any>>
      end

    decoded = decoded <> fixed

    if byte_size(remainder) == 0 do
      decoded
    else
      decode_unsynchronized(remainder, decoded)
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
