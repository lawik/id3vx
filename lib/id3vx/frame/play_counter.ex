defmodule Id3vx.Frame.PlayCounter do
  defstruct counter: 0

  alias Id3vx.Frame.PlayCounter

  @type t :: %PlayCounter{
          counter: integer()
        }
end
