defmodule Id3vx.Flags do
  defmacro __using__(_) do
    quote do
      def b(true), do: 1
      def b(_), do: 0
    end
  end
end

defmodule Id3vx.TagFlags do
  use Id3vx.Flags
  @moduledoc false
  defstruct unsynchronisation: nil, extended_header: nil, experimental: nil, footer: nil

  def all_false do
    %__MODULE__{
      unsynchronisation: false,
      extended_header: false,
      experimental: false,
      footer: false
    }
  end

  def as_binary(nil, tag) do
    as_binary(all_false(), tag)
  end

  def as_binary(
        %{
          unsynchronisation: u,
          extended_header: ext,
          experimental: exp
        },
        %{version: 3}
      ) do
    <<b(u)::1, b(ext)::1, b(exp)::1, 0::5>>
  end
end

defmodule Id3vx.ExtendedHeaderV4 do
  @moduledoc false
  defstruct size: nil, flag_bytes: nil, flags: nil
end

defmodule Id3vx.ExtendedHeaderV3 do
  @moduledoc false
  defstruct size: nil, flags: nil, padding_size: nil, crc_data: nil
end

defmodule Id3vx.ExtendedHeaderFlags do
  use Id3vx.Flags
  @moduledoc false
  defstruct is_update: nil,
            crc_data_present: nil,
            tag_restrictions: nil

  def all_false do
    %__MODULE__{
      is_update: false,
      crc_data_present: false,
      tag_restrictions: false
    }
  end

  def as_binary(nil, tag) do
    as_binary(all_false(), tag)
  end

  def as_binary(
        %{
          crc_data_present: crc
        },
        %{version: 3}
      ) do
    <<b(crc)::1, 0::15>>
  end
end

defmodule Id3vx.FrameFlags do
  use Id3vx.Flags
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
          grouping_identity: gi
        },
        %{version: 3}
      ) do
    <<b(tap)::1, b(fap)::1, b(ro)::1, 0::5, b(c)::1, b(e)::1, b(gi)::1, 0::5>>
  end
end
