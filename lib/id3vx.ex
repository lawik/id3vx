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
    defstruct unsynchronized: nil, extended_header: nil, experimental: nil, footer: nil
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
    <<body::binary-size(tag_size),_::binary>> = rest
    header <> body
  end

  def tag_to_binary(%Tag{version: 3} = tag) do
    raise "not implemented"
  end

  def get_bytes({used, unused}, bytes) do
    <<data::binary-size(bytes), rest::binary>> = unused
    {data, {used <> data, rest}}
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
    IO.inspect(tag)
    IO.inspect(tag.flags)

    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)

    {data, source} = get_bytes(source, frames_size)
    frames = parse_frames(tag, data, [])
    tag = %{tag | frames: frames}

    if tag.flags.footer do
      {:parse_footer, source, tag}
    else
      {:skip_padding, source, tag}
    end
  end

  defp parse_step(source, :parse_frames, %{version: 3} = tag) do
    IO.inspect(tag)
    IO.inspect(tag.flags)

    frames_size =
      tag.size
      |> subtract_extended_header(tag)
      |> subtract_footer(tag)


    {data, source} = get_bytes(source, frames_size)
    frames = parse_frames(tag, data, [])
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

  def find_offset(target, data, offset \\ 0) do
    case data do
      <<t::binary-size(4), data::binary>> when target == t ->
        offset
      <<_skip::binary-size(1), data::binary>> ->
        find_offset(target, data, offset + 1)
      "" ->
        -1
    end
  end

  def parse_tag(
        <<"ID3", 4::integer, minor::integer, unsynchronized::size(1), extended_header::size(1),
          experimental::size(1), footer::size(1), _unused::size(4), tag_size::binary-size(4)>>
      ) do
    flags = %TagFlags{
      unsynchronized: unsynchronized == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1,
      footer: footer == 1
    }

    tag_size = decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: 4, revision: minor, flags: flags, size: tag_size}}
  end

  def parse_tag(<<"ID3", 3::integer, minor::integer, flag_bytes::size(8), tag_size::binary-size(4)>>) do
    <<unsynchronized::size(1), extended_header::size(1), experimental::size(1), footer::size(1), _unused::size(4)>> = <<flag_bytes>>

    IO.inspect(flag_bytes, label: "tag flag bits", base: :binary)

    flags = %TagFlags{
      unsynchronized: unsynchronized == 1,
      extended_header: extended_header == 1,
      experimental: experimental == 1
    }

    tag_size = decode_synchsafe_integer(tag_size)

    {:ok, %Tag{version: 3, revision: minor, flags: flags, size: tag_size}}
  end

  def parse_tag(bin) do
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
        <<size::binary-size(4), crc_data_present::1, _::15, padding_size::binary-size(4)>>
      ) do
    %ExtendedHeaderV3{
      size: size,
      flags: %ExtendedHeaderFlags{
        crc_data_present: crc_data_present == 1
      }
    }
  end

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
    frames =
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

    IO.puts("==========================")
    IO.inspect(id)
    IO.inspect(frame_size, label: "unparsed frame size")
    frame_size = :binary.decode_unsigned(frame_size, :big)
    IO.inspect(frame_size, label: "frame size")

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
            IO.inspect(frame, label: "frame")
            {frames_data, [frame | frames], true}
          :not_found -> {frames_data, frames, false}
        end
    end

    # Does it contain enough data for another frame?
    frames =
      if continue? and byte_size(frames_data) > 10 do
        parse_frames(tag, frames_data, frames)
      else
        Enum.reverse(frames)
      end
  end

  def find_next_valid_id(bytes, offset \\ 0) do
    case bytes do
      <<id::binary-size(4), rest::binary>> ->
        if Regex.match?(~r/[A-Z0-9]{4}/, id) do
          {:ok, {id, offset}}
        else
          <<_::binary-size(1), next::binary>> = bytes
          find_next_valid_id(next, offset + 1)
        end
      _ ->
        :not_found
    end
  end

  def find_all_ids_offsets_and_sizes(bytes, tag_size, found \\ [], offset \\ 0) do
    if offset >= tag_size do
        IO.puts("done by tag size")
        Enum.reverse(found)
    else
    case bytes do
      <<id::binary-size(4), size::binary-size(4), flags::binary-size(2), rest::binary>> ->
        if Regex.match?(~r/[A-Z0-9]{4}/, id) do
          IO.inspect(offset, label: "offset")
          size = :binary.decode_unsigned(size)
          next = size + offset + 10
          #next = offset + 10
          find = {id, size, offset, next}
          IO.inspect(flags, label: "flags", base: :binary)

          #case found do
          #  [{_, _, _, n} = f  | _] when n != offset ->
          #    IO.inspect(f, label: "pre")
          #    IO.inspect(find, label: "this")
          #    #raise "FAIL!"
          #  _ -> nil
          #end

          IO.puts(byte_size(rest))
          found = [find | found]
          IO.inspect({id, size})
          case rest do
            <<_skip::binary-size(size), rest::binary>> ->
              find_all_ids_offsets_and_sizes(rest, tag_size, found, next)
            _ ->
              IO.puts("done, too short")
              Enum.reverse(found)
          end
        else
          <<_::binary-size(1), next::binary>> = bytes
          find_next_valid_id(next, offset + 1)
          find_all_ids_offsets_and_sizes(next, tag_size, found, offset+1)
        end
      _ ->
        IO.puts("done")
        Enum.reverse(found)
    end
    end
  end

  def parse_frame_flags(flags) do
    IO.inspect(flags, base: :binary)
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

  def parse_frame(tag, id, size, flags, data) do
    #data =
    #  if tag.flags.unsynchronized do
    #    decode_unsynchronized(data)
    #  else
    #    data
    #  end

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

  def decode_synchsafe_integer(<<0::1, _::7, 0::1, _::7, 0::1, _::7, 0::1, _::7>> = binary) do
    IO.inspect(binary, label: "decoding binary synchsafe int", base: :binary)
    # Cribbed from LiveBeats, not entirely sure how it achieves the result
    binary
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {el, index}, acc -> acc ||| el <<< (index * 7) end)
  end

  #  def decode_synchsafe_integer(binary) do
  #    :binary.decode_unsigned(binary)
  #    |> IO.inspect(label: "decoded as unsigned")
  #  end

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
