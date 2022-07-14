defmodule Id3vx.Frame.URL do
  @moduledoc """
  URL frame structs, used for all W???-frames except WXXX.

  Known URL frames:

  - WCOM: Commercial information
  - WCOP: Copyright/Legal information
  - WFED: Podcast link
  - WOAF: Official audio file webpage
  - WOAR: Official artist/performer webpage
  - WOAS: Official audio source webpage
  - WORS: Official Internet radio station homepage
  - WPAY: Payment
  - WPUB: Publishers official webpage

  """

  defstruct url: nil

  alias Id3vx.Frame.URL

  @type t :: %URL{
          url: String.t()
        }
end
