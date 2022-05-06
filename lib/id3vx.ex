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
    defstruct version: nil, flags: nil, size: nil, extended_header: nil, footer: nil, frames: nil
  end

  defmodule TagFlags do
    defstruct unsynchronized: nil, extended_header: nil, experimental: nil, footer: nil
  end

  defmodule ExtendedHeader do
    defstruct size: nil, flag_bytes: nil, flags: nil
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
  alias Id3vx.ExtendedHeader
  alias Id3vx.ExtendedHeaderFlags
  alias Id3vx.Frame
  alias Id3vx.FrameFlags

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

  # parse tag header, get flags
  # handle flags:
  #   if extended headerparse extended header
  #

  @stream_chunk_size 2048
  def parse_stream(path) do
    stream = File.stream!(path, [:raw], @stream_chunk_size)

    {<<>>, <<>>, stream}
    |> parse
  end

  def parse_binary(<<binary>>) do
    {<<>>, binary}
    |> parse
  end

  def get_bytes({used, unused, %File.Stream{} = stream}, bytes) do
    left = byte_size(unused)

    {taken, remainder} =
      case bytes - left do
        take when take > 0 ->
          gotten = take_from_stream(stream, take)

          {data, rest} =
            case gotten do
              <<data::binary-size(take), rest::binary>> ->
                {data, rest}

              <<data::binary-size(take)>> ->
                {data, <<>>}

              <<data::binary>> ->
                Logger.error(
                  "Tried to take #{take} bytes but source only provided #{byte_size(data)}."
                )

                {data, <<>>}
            end

          {unused <> data, rest}

        take when take == 0 ->
          rest = take_from_stream(stream, take)
          {unused, rest}

        take when take < 0 ->
          <<data::binary-size(bytes), rest::binary>> = unused
          {data, rest}
      end

    {taken, {used <> taken, remainder, stream}}
  end

  def get_bytes({used, unused}, bytes) do
    <<data::binary-size(bytes), rest::binary>> = unused
    {data, {used <> data, rest}}
  end

  defp take_from_stream(stream, take) do
    takes = ceil(take / @stream_chunk_size)

    stream
    |> Enum.take(takes)
    |> Enum.reduce(<<>>, fn got, acc ->
      acc <> got
    end)
  end

  def parse(source) do
    iterate(source, :parse_prepend_tag, nil)
  end

  def iterate(source, step, state) do
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

  defp parse_step(source, :parse_extended_header, tag) do
    {data, source} = get_bytes(source, 6)
    ext_header = parse_extended_header_fixed(data)
    tag = %{tag | extended_header: ext_header}
    # Implement rest of ext header parsing, for now, we pull the data
    # to get it out of the way and that's a way to just skip the extended
    # header
    {_data, source} = get_bytes(source, ext_header.size - 6)
    # {:parse_extended_header_flags, source, tag}

    {:parse_frames, source, tag}
  end

  defp parse_step(source, :parse_frames, tag) do
    IO.inspect(tag)
    IO.inspect(tag.flags)
    IO.inspect(tag.size, label: "pre-subtraction")
    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)
    IO.inspect(frames_size, label: "post-subtraction")

    {data, source} = get_bytes(source, frames_size)

    data =
      if tag.flags.unsynchronized do
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

  defp parse_step(source, step, state) do
    IO.puts("Step not implemented #{step}")
    {:done, {:ok, state}}
  end

  def parse_tag(
        <<"ID3", major::integer, minor::integer, unsynchronized::size(1),
          extended_header::size(1), experimental::size(1), footer::size(1), _unused::size(4),
          tag_size::binary-size(4)>>
      ) do
    flags = %TagFlags{
      unsynchronized: unsynchronized == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1,
      footer: footer == 1
    }

    tag_size = decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: {major, minor}, flags: flags, size: tag_size}}
  end

  def parse_tag(bin) do
    :not_found
  end

  def parse_extended_header_fixed(
        <<size::binary-size(4), _::binary-size(1), _::size(1), is_update::size(1),
          crc_data_present::size(1), tag_restrictions::size(1), _unused::size(4)>>
      ) do
    %ExtendedHeader{
      size: decode_synchsafe_integer(size),
      flag_bytes: 0x01,
      flags: %ExtendedHeaderFlags{
        is_update: is_update == 1,
        crc_data_present: crc_data_present == 1,
        tag_restrictions: tag_restrictions == 1
      }
    }
  end

  def parse_frames(tag, frames_data, frames \\ []) do
    # A tag must have at least one frame, a frame must have at least one byte
    # in it after the header
    <<id::binary-size(4), frame_size::binary-size(4), flags::binary-size(2), frames_data::binary>> =
      frames_data

    IO.inspect(id)
    frame_size = decode_synchsafe_integer(frame_size)
    flags = parse_frame_flags(flags)

    IO.inspect({byte_size(frames_data), frame_size})
    {frame_data, frames_data} =
      case frames_data do
        <<frame_data::binary-size(frame_size)>> -> {frame_data, <<>>}
        <<frame_data::binary-size(frame_size), rest::binary>> -> {frame_data, rest}
      end

    {frames, continue?} =
      case parse_frame(tag, id, frame_size, flags, frame_data) do
        {:frame, frame} -> {[frame | frames], true}
        :not_found -> {frames, false}
      end

    # Does it contain enough data for another frame?
    frames =
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
    IO.inspect(flags)
  end

  def parse_frame(tag, id, size, flags, data) do
    frame = Frame.parse(id, flags, data)
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

  defp decode_synchsafe_integer(<<bin>>), do: bin

  defp decode_synchsafe_integer(binary) do
    # Cribbed from LiveBeats, not entirely sure how it achieves the result
    binary
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {el, index}, acc -> acc ||| el <<< (index * 7) end)
  end

  def decode_unsynchronized(data, decoded \\ <<>>)


  # Candidate for decoding
  def decode_unsynchronized(<<0xff::8, 0x00::8, _::binary>> = data, decoded) do
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
    decoded <> byte
  end

  # No match, move one byte forward
  def decode_unsynchronized(<<byte::8, data::binary>>, decoded) do
    decoded = decoded <> byte
    decode_unsynchronized(data, decoded)
  end
end
