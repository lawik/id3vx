defmodule Id3vx.TagFlags do
  @moduledoc false
  defstruct unsynchronisation: nil, extended_header: nil, experimental: nil, footer: nil
end

defmodule Id3vx.ExtendedHeaderV4 do
  @moduledoc false
  defstruct size: nil, flag_bytes: nil, flags: nil
end

defmodule Id3vx.ExtendedHeaderV3 do
  @moduledoc false
  defstruct size: nil, flags: nil, padding: nil
end

defmodule Id3vx.ExtendedHeaderFlags do
  @moduledoc false
  defstruct is_update: nil,
            crc_data_present: nil,
            tag_restrictions: nil
end

defmodule Id3vx.FrameFlags do
  @moduledoc false
  defstruct tag_alter_preservation: nil,
            file_alter_preservation: nil,
            read_only: nil,
            grouping_identity: nil,
            compression: nil,
            encryption: nil,
            unsynchronisation: nil,
            data_length_indicator: nil

  def all_false do
    %__MODULE__{
      tag_alter_preservation: false,
      file_alter_preservation: false,
      read_only: false,
      grouping_identity: false,
      compression: false,
      encryption: false,
      unsynchronisation: false,
      data_length_indicator: false
    }
  end
end
