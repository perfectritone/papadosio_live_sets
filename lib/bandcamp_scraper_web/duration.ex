defmodule BandcampScraperWeb.Duration do
  def seconds_to_human_readable(seconds) do
    minutes = Integer.floor_div(seconds, 60)
    remaining_seconds =
      seconds - minutes * 60
      |> Integer.to_string
      |> String.pad_leading(2, "0")

    "#{minutes}:#{remaining_seconds}"
  end
end
