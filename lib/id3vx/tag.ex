defmodule Id3vx.Tag do
  @moduledoc """
  Utility module for building ID3 tags and common frames conveniently.


  """

  defstruct version: nil,
            revision: nil,
            flags: nil,
            size: nil,
            extended_header: nil,
            footer: nil,
            frames: nil

  alias Id3vx.Tag
  alias Id3vx.Frame
  alias Id3vx.FrameFlags

  @type t :: %Tag{
          version: 3 | 4,
          revision: integer(),
          flags: %Id3vx.TagFlags{},
          size: integer(),
          extended_header: %Id3vx.ExtendedHeaderV3{} | %Id3vx.ExtendedHeaderV4{},
          footer: term(),
          frames: [Id3vx.Frame.t()]
        }

  @doc """
  Create a new blank tag for a specific version of the ID3 spec.
  """
  @spec create(version :: integer()) :: Tag.t()
  def create(version) do
    %Tag{version: version, revision: 0, frames: []}
  end

  @doc """
  Add a picture to a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.
  """
  @spec add_attached_picture(
          container :: Tag.t() | Frame.Chapter.t(),
          description :: String.t(),
          mime_type :: String.t(),
          image_data :: binary(),
          picture_type :: atom()
        ) :: Tag.t() | Frame.Chapter.t()
  def add_attached_picture(container, description, mime_type, image_data, picture_type \\ :other) do
    frame = %Frame{
      id: "APIC",
      flags: FrameFlags.all_false(),
      label: Id3vx.Frame.Labels.from_id("APIC"),
      data: %Frame.AttachedPicture{
        encoding: :utf16,
        mime_type: mime_type,
        picture_type: picture_type,
        description: description,
        image_data: image_data
      }
    }

    %{container | frames: [frame | container.frames]}
  end

  @doc """
  Add a custom URL to a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Typically used for Chapters.
  """
  @spec add_custom_url(
          container :: Tag.t() | Frame.Chapter.t(),
          description :: String.t(),
          url :: String.t()
        ) :: Tag.t() | Frame.Chapter.t()
  def add_custom_url(container, description, url) do
    frame = %Frame{
      id: "WXXX",
      flags: FrameFlags.all_false(),
      label: Id3vx.Frame.Labels.from_id("WXXX"),
      data: %Frame.CustomURL{
        description: description,
        url: url
      }
    }

    %{container | frames: [frame | container.frames]}
  end

  @doc """
  Add a text frame to a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.
  """
  @spec add_text_frame(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t(),
          text :: String.t()
        ) :: Tag.t() | Frame.Chapter.t()
  def add_text_frame(container, frame_id, text) when is_binary(text) do
    add_text_frame(container, frame_id, [text])
  end

  def add_text_frame(container, "T" <> _ = frame_id, text) when is_list(text) do
    frame = %Frame{
      id: frame_id,
      flags: FrameFlags.all_false(),
      label: Id3vx.Frame.Labels.from_id(frame_id),
      data: %Frame.Text{
        encoding: :utf16,
        text: text
      }
    }

    %{container | frames: [frame | container.frames]}
  end

  @typical_element_prefix "chp"
  @doc """
  Add a typical `Id3vx.Frame.Chapter` frame to a tag.

  The callback gets the new chapter frame and is normally used to add
  sub-frames like text, links, pictures using the other tag-building
  utilities in this module.

  It also creates a matching Table of Content frame and entry.
  Essentially it tries to take care of all the annoying bits.
  """
  @spec add_typical_chapter_and_toc(
          tag :: Tag.t(),
          start_time :: integer(),
          end_time :: integer(),
          start_offset :: integer(),
          end_offset :: integer(),
          title :: String.t(),
          callback :: (Frame.Chapter.t() -> Frame.Chapter.t())
        ) :: Tag.t()
  def add_typical_chapter_and_toc(
        tag,
        start_time,
        end_time,
        start_offset,
        end_offset,
        title,
        callback
      )
      when is_function(callback) do
    {toc_okay?, toc_frame} =
      case find_element(tag, "CTOC", "toc") do
        nil ->
          {true, nil}

        %Frame{data: toc} = f ->
          {toc.ordered and
             toc.top_level and
             Enum.all?(toc.child_elements, fn eid ->
               String.starts_with?(eid, @typical_element_prefix)
             end), f}
      end

    # Ensure we build a ToC
    {tag, toc_frame} =
      case toc_frame do
        nil ->
          toc_frame = %Frame{
            id: "CTOC",
            flags: FrameFlags.all_false(),
            label: Id3vx.Frame.Labels.from_id("CTOC"),
            data: %Frame.TableOfContents{
              element_id: "toc",
              top_level: true,
              ordered: true,
              child_elements: []
            }
          }

          {%{tag | frames: [toc_frame | tag.frames]}, toc_frame}

        toc_frame ->
          {tag, toc_frame}
      end

    if toc_okay? do
      num =
        case List.last(toc_frame.data.child_elements) do
          nil ->
            0

          <<"chp", num::binary>> ->
            String.to_integer(num)
        end

      chapter_element_id = @typical_element_prefix <> to_string(num + 1)

      chapter =
        %Frame.Chapter{
          element_id: chapter_element_id,
          start_time: start_time,
          end_time: end_time,
          start_offset: start_offset,
          end_offset: end_offset,
          frames: []
        }
        |> add_text_frame("TIT2", title)
        |> callback.()

      chapter_frame = %Frame{
        id: "CHAP",
        flags: FrameFlags.all_false(),
        label: Id3vx.Frame.Labels.from_id("CHAP"),
        data: chapter
      }

      # Append the child element in the ToC child elements
      toc_frame = %{
        toc_frame
        | data: %{
            toc_frame.data
            | child_elements: toc_frame.data.child_elements ++ [chapter_element_id]
          }
      }

      %{tag | frames: tag.frames ++ [chapter_frame]}
      |> change_element("CTOC", "toc", fn _ ->
        toc_frame.data
      end)
    else
      raise Id3vx.Error, message: "Not a typical CTOC frame, can't modify it typically"
    end
  end

  @doc """
  Change frames in a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Runs the callback on all frames that match the frame ID.

  Returns the updated container.
  """
  @spec change_elements(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t(),
          callback :: fun()
        ) :: Tag.t() | Frame.Chapter.t()
  def change_elements(container, frame_id, callback) do
    frames =
      Enum.map(container.frames, fn frame ->
        if frame.id == frame_id do
          callback.(frame)
        else
          frame
        end
      end)

    %{container | frames: frames}
  end

  @doc """
  Change specific frame in a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Runs the callback on all frames that match the frame ID and the element ID.

  Returns the updated container.
  """
  @spec change_element(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t(),
          element_id :: String.t(),
          callback :: fun()
        ) :: Tag.t() | Frame.Chapter.t()
  def change_element(container, frame_id, element_id, callback) do
    frames =
      Enum.map(container.frames, fn frame ->
        case frame do
          %Frame{id: ^frame_id, data: %Frame.Chapter{element_id: ^element_id}} ->
            %{frame | data: callback.(frame.data)}

          %Frame{id: ^frame_id, data: %Frame.TableOfContents{element_id: ^element_id}} ->
            %{frame | data: callback.(frame.data)}

          _ ->
            frame
        end
      end)

    %{container | frames: frames}
  end

  @doc """
  Find specific frame in a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Returns the frame if anything matches the frame ID or nil if nothing was found.
  """
  @spec find_element(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t()
        ) :: Frame.t() | nil
  def find_element(container, frame_id) do
    Enum.find(container.frames, fn f ->
      f.id == frame_id
    end)
  end

  @doc """
  Find specific frame in a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Returns the frame if anything matches the frame ID and element ID, or nil if nothing was found.
  """
  @spec find_element(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t(),
          element_id :: String.t()
        ) :: Frame.t() | nil
  def find_element(container, frame_id, element_id) do
    Enum.find(container.frames, fn frame ->
      case frame do
        %Frame{id: ^frame_id, data: %Frame.Chapter{element_id: ^element_id}} ->
          true

        %Frame{id: ^frame_id, data: %Frame.TableOfContents{element_id: ^element_id}} ->
          true

        _ ->
          false
      end
    end)
  end

  @doc """
  Delete frames in a `Id3vx.Tag` or `Id3vx.Frame.Chapter`.

  Deletes all frames matching frame ID.

  Returns the updated container.
  """
  @spec delete_elements(
          container :: Tag.t() | Frame.Chapter.t(),
          frame_id :: String.t()
        ) :: Tag.t() | Frame.Chapter.t()
  def delete_elements(container, frame_id) do
    frames =
      Enum.reject(container.frames, fn f ->
        f.id == frame_id
      end)

    %{container | frames: frames}
  end

  @doc """
  Delete a chapter in a `Id3vx.Tag`.

  Delete ToC element and chapter matching element ID.

  Returns the updated container.
  """
  @spec delete_chapter(
          container :: Tag.t() | Frame.Chapter.t(),
          element_id :: String.t()
        ) :: Tag.t() | Frame.Chapter.t()
  def delete_chapter(container, element_id) do
    # Remove ToC element child for chapter
    container =
      change_element(container, "CTOC", "toc", fn d ->
        els =
          Enum.reject(d.child_elements, fn e ->
            e == element_id
          end)

        %{d | child_elements: els}
      end)

    frames =
      Enum.reject(container.frames, fn f ->
        case f do
          %{id: "CHAP", data: %Frame.Chapter{element_id: ^element_id}} ->
            true

          _ ->
            false
        end
      end)

    %{container | frames: frames}
  end
end
