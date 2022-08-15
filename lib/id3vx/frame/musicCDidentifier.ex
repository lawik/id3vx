defmodule Id3vx.Frame.MusicCDIdentifier do
  defstruct cd_toc_binary: nil
  alias Id3vx.Frame.MusicCDIdentifier

  @type t :: %MusicCDIdentifier{
          cd_toc_binary: binary()
        }
end
