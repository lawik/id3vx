defmodule Id3vx.Frame.Unknown do
  defstruct unused: nil

  alias Id3vx.Frame.Unknown

  @type t :: %Unknown{
          unused: term()
        }
end
