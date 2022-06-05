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

  def as_binary(nil, tag) do
    as_binary(all_false(), tag)
  end

  def as_binary(
        %{
          tag_alter_preservation: tap,
          file_alter_preservation: fap,
          read_only: ro,
          compression: c,
          encryption: e,
          unsynchronisation: u
        },
        %{version: 3}
      ) do
    <<b(tap)::1, b(fap)::1, b(ro)::1, 0::5, b(c)::1, b(e)::1, b(u)::1, 0::5>>
  end

  def b(true), do: 1
  def b(_), do: 0
end
