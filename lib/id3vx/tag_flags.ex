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
