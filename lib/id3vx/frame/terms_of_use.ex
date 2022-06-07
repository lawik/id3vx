defmodule Id3vx.Frame.TermsOfUse do
  defstruct encoding: :utf16,
            language: nil,
            text: nil

  alias Id3vx.Frame.TermsOfUse

  @type t :: %TermsOfUse{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          language: String.t(),
          text: String.t()
        }
end
