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

  def parse(id, flags, data) do
    %Frame{
      id: id,
      label: "#{id} is not implemented, please contribute, it's not hard.",
      data: :not_implemented
    }
  end

  def parse_text(flags, <<encoding::binary-size(1), info::binary>>) do
    %{}
  end
end
