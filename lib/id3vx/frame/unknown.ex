defmodule Id3vx.Frame.Unknown do
  @moduledoc """
  Used for any unknown frame.
  """

  defstruct unused: nil

  alias Id3vx.Frame.Unknown

  @type t :: %Unknown{
          unused: term()
        }
end
