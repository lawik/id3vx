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
