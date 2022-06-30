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
