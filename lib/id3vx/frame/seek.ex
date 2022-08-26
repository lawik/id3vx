defmodule Id3vx.Frame.Seek do
  defstruct offset: nil

  alias Id3vx.Frame.Seek

  @type t :: %Seek{
          offset: binary()
        }
end
