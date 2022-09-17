defmodule Id3vx.Frame.Popularimeter do
  defstruct email: nil,
            rating: 0,
            counter: 0

  alias Id3vx.Frame.Popularimeter

  @type t :: %Popularimeter{
          email: String.t(),
          rating: integer(),
          counter: integer()
        }
end
