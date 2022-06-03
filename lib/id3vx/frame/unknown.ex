defmodule Id3vx.Frame.Unknown do
  defstruct raw_data: nil

  alias Id3vx.Frame.Unknown

  @type t :: %Unknown{
          raw_data: binary()
        }
end
