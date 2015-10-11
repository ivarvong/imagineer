defmodule Imagineer.Image.PNG.Interlace do
  alias Imagineer.Image.PNG
  alias Imagineer.Image.PNG.Helpers

  @moduledoc """
  A module for extracting and storing scanlines from images based on their
  interlace method.
  """

  @doc """
  Extracts scanlines for an image based on its interlace method.
  """
  def extract_pixels(%PNG{interlace_method: 0}=image) do
    %PNG{image | scanlines: Interlace.None.extract_scanlines(image)}
    |> PNG.Filter.unfilter
    |> PNG.Pixels.extract
    |> handle_palette
  end

  def extract_pixels(%PNG{interlace_method: 1}=image) do
    %PNG{image | scanlines: adam7_scanlines(image)}
    |> log_scanlines
    |> PNG.Filter.unfilter
    |> log_unfiltered_rows
    |> PNG.Pixels.extract
    |> handle_palette
  end

  defp log_scanlines(image) do
    Apex.ap inspect {image.width, image.height}
    Apex.ap inspect image.scanlines
    image
  end

  defp log_unfiltered_rows(image) do
    Apex.ap inspect image.unfiltered_rows
    image
  end

  defp handle_palette(%PNG{color_type: 3, palette: palette, pixels: pixels}=image) do
    %PNG{image | pixels: extract_pixels_from_palette(pixels, palette)}
  end

  # If the image doesn't have a color type of 3, it doesn't use a palette
  defp handle_palette(image) do
    image
  end

  defp extract_pixels_from_palette(palette_rows, palette) do
    extract_pixels_from_palette(palette_rows, palette, [])
  end

  # In the base case, we will have a reversed list of lists. Each list refers to
  # a row of pixels.
  defp extract_pixels_from_palette([], _palette, extracted_palette) do
    Enum.reverse(extracted_palette)
  end

  defp extract_pixels_from_palette([palette_row | palette_rows], palette, extracted_palette) do
    row_pixels = extract_pixels_from_palette_row(palette_row, palette, [])
    extract_pixels_from_palette(palette_rows, palette, [row_pixels | extracted_palette])
  end

  # In the base case, we are left with a row of pixels. Reverse them and we're
  # finished.
  defp extract_pixels_from_palette_row([], _palette, pixels) do
    Enum.reverse(pixels)
  end

  defp extract_pixels_from_palette_row([{palette_index} | palette_indices], palette, pixels) do
    pixel = :array.get(palette_index, palette)
    extract_pixels_from_palette_row(palette_indices, palette, [pixel | pixels])
  end

  defp adam7_scanlines(
    %PNG{width: width, height: height, color_format: color_format,
      decompressed_data: decompressed_data}
  ) do
    {width, height, Helpers.bits_per_pixel(color_format)}
    |> Adam7.PNG.extract_images(decompressed_data)
  end
end
