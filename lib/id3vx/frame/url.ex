defmodule Id3vx.Frame.URL do
  defstruct url: nil

  alias Id3vx.Frame.URL

  @type t :: %URL{
          url: String.t()
        }
end
