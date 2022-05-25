defmodule Id3vx.Frame do
  @moduledoc """

  Natives types:
    AENC Audio encryption
    APIC Attached picture
    ASPI Audio seek point index
    COMM Comments
    COMR Commercial frame
    ENCR Encryption method registration
    EQU2 Equalisation (2)
    ETCO Event timing codes
    GEOB General encapsulated object
    GRID Group identification registration
    LINK Linked information
    MCDI Music CD identifier
    MLLT MPEG location lookup table
    OWNE Ownership frame
    PRIV Private frame
    PCNT Play counter
    POPM Popularimeter
    POSS Position synchronisation frame
    RBUF Recommended buffer size
    RVA2 Relative volume adjustment (2)
    RVRB Reverb
    SEEK Seek frame
    SIGN Signature frame
    SYLT Synchronised lyric/text
    SYTC Synchronised tempo codes
    TALB Album/Movie/Show title
    TBPM BPM (beats per minute)
    TCOM Composer
    TCON Content type
    TCOP Copyright message
    TDEN Encoding time
    TDLY Playlist delay
    TDOR Original release time
    TDRC Recording time
    TDRL Release time
    TDTG Tagging time
    TENC Encoded by
    TEXT Lyricist/Text writer
    TFLT File type
    TIPL Involved people list
    TIT1 Content group description
    TIT2 Title/songname/content description
    TIT3 Subtitle/Description refinement
    TKEY Initial key
    TLAN Language(s)
    TLEN Length
    TMCL Musician credits list
    TMED Media type
    TMOO Mood
    TOAL Original album/movie/show title
    TOFN Original filename
    TOLY Original lyricist(s)/text writer(s)
    TOPE Original artist(s)/performer(s)
    TOWN File owner/licensee
    TPE1 Lead performer(s)/Soloist(s)
    TPE2 Band/orchestra/accompaniment
    TPE3 Conductor/performer refinement
    TPE4 Interpreted, remixed, or otherwise modified by
    TPOS Part of a set
    TPRO Produced notice
    TPUB Publisher
    TRCK Track number/Position in set
    TRSN Internet radio station name
    TRSO Internet radio station owner
    TSOA Album sort order
    TSOP Performer sort order
    TSOT Title sort order
    TSRC ISRC (international standard recording code)
    TSSE Software/Hardware and settings used for encoding
    TSST Set subtitle
    TXXX User defined text information frame
    UFID Unique file identifier
    USER Terms of use
    USLT Unsynchronised lyric/text transcription
    WCOM Commercial information
    WCOP Copyright/Legal information
    WOAF Official audio file webpage
    WOAR Official artist/performer webpage
    WOAS Official audio source webpage
    WORS Official Internet radio station homepage
    WPAY Payment
    WPUB Publishers official webpage
    WXXX User defined URL link frame
  """

  defstruct id: nil,
    size: nil,
    flags: nil,
    label: nil, # "Payment", "Album sort order", "Title/songname/content description"
    data: nil

  alias Id3vx.Frame

  def parse("T" <> _ = id, flags, data) do
    frame_data = parse_text(flags, data)
    %Frame{
      id: id,
      data: frame_data
    }
  end

  @picture_type %{
    0x00 => :other,
    0x01 => :basic_file_icon,
    0x02 => :other_file_icon,
    0x03 => :cover,
    0x04 => :cover_back,
    0x05 => :leaflet_page,
    0x06 => :media,
    0x07 => :lead_artist,
    0x08 => :artist,
    0x09 => :conductor,
    0x0a => :band,
    0x0b => :composer,
    0x0c => :lyricist,
    0x0d => :recording_location,
    0x0e => :during_recording,
    0x0f => :during_performance,
    0x10 => :video_capture,
    0x11 => :a_bright_coloured_fish,
    0x12 => :illustration,
    0x13 => :band_logotype,
    0x14 => :studio_logotype
  }
  def parse("APIC" = id, flags, data) do
    <<encoding::size(8), rest::binary>> = data
    {mime_type, rest} = split_at_next_null(rest)
    <<picture_type::binary-size(1), rest::binary>> = rest
    picture_type = @picture_type[picture_type]
    {description, rest} =
      case encoding do
        0 ->
          split_at_next_null(rest)
        1 ->
          {description, rest} = split_at_next_double_null(rest)
          {convert_string(encoding, description), rest}
      end

    %Frame{
      id: id,
      data: %{
          encoding: encoding,
          mime_type: mime_type,
          picture_type: picture_type,
          description: description,
          image_data: rest
        }
    }
  end

  def parse(id, flags, data) do
    %Frame{
      id: id,
      label: "#{id} is not implemented, please contribute, it's not hard.",
      data: %{status: :not_implemented, raw_data: data}
    }
  end

  defp split_at_next_null(data, acc \\ <<>>) do
    case data do
      <<0x00::size(8), data::binary>> ->
        {acc, data}
      <<byte::binary-size(1), data::binary>> ->
        split_at_next_null(data, acc <> byte)
    end
  end

  defp split_at_next_double_null(data, acc \\ <<>>) do
    case data do
      <<0x00::size(8), 0x00::size(8), data::binary>> ->
        {acc, data}
      <<byte::binary-size(1), data::binary>> ->
        split_at_next_double_null(data, acc <> byte)
    end
  end

  def parse_text(flags, <<encoding::size(8), info::binary>>) do
    {strings, _rest} = decode_string_sequence(encoding, byte_size(info), info)
    %{
      encoding: encoding,
      text: strings
    }
  end

  # TODO: All this text parsing was ripped from live_beats and I
  #       don't find it very easy to follow. Tons of stuff around
  #       null terminations and so on. See if it makes sense to rework
  #       or if it can be made easier to follow
  defp decode_string_sequence(encoding, max_byte_size, data, acc \\ [])

  defp decode_string_sequence(_, max_byte_size, data, acc) when max_byte_size <= 0 do
    {Enum.reverse(acc), data}
  end

  defp decode_string_sequence(encoding, max_byte_size, data, acc) do
    {str, str_size, rest} = decode_string(encoding, max_byte_size, data)
    decode_string_sequence(encoding, max_byte_size - str_size, rest, [str | acc])
  end

  defp convert_string(encoding, str) when encoding in [0, 3] do
    str
  end

  defp convert_string(1, data) do
    {encoding, bom_length} = :unicode.bom_to_encoding(data)
    {_, string_data} = String.split_at(data, bom_length)
    :unicode.characters_to_binary(string_data, encoding)
  end

  defp convert_string(2, data) do
    :unicode.characters_to_binary(data, {:utf16, :big})
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [1, 2] do
    {str, rest} = get_double_null_terminated(data, max_byte_size)

    {convert_string(encoding, str), byte_size(str) + 2, rest}
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [0, 3] do
    case :binary.split(data, <<0>>) do
      [str, rest] when byte_size(str) + 1 <= max_byte_size ->
        {str, byte_size(str) + 1, rest}

      _ ->
        {str, rest} = :erlang.split_binary(data, max_byte_size)
        {str, max_byte_size, rest}
    end
  end

  defp get_double_null_terminated(data, max_byte_size, acc \\ [])

  defp get_double_null_terminated(rest, 0, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<0, 0, rest::binary>>, _, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<a::size(8), b::size(8), rest::binary>>, max_byte_size, acc) do
    next_max_byte_size = max_byte_size - 2
    get_double_null_terminated(rest, next_max_byte_size, [b, a | acc])
  end
end
