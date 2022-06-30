defmodule Id3vx.Frame.URL do
  @moduledoc """
  URL frame structs, used for all W???-frames except WXXX.
  """

  defstruct url: nil

  alias Id3vx.Frame.URL

  @type t :: %URL{
          url: String.t()
        }
end
