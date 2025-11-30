defmodule BandcampScraperWeb.SetSongHTML do
  use BandcampScraperWeb, :html

  embed_templates "set_song_html/*"

  @doc """
  Renders a set_song form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def set_song_form(assigns)

  @doc """
  Returns Tailwind CSS classes for variant badge colors based on category.
  """
  def variant_color(category) do
    case category do
      "guest" -> "bg-purple-900 text-purple-200"
      "date" -> "bg-blue-900 text-blue-200"
      "part" -> "bg-green-900 text-green-200"
      "night" -> "bg-indigo-900 text-indigo-200"
      "acoustic" -> "bg-amber-900 text-amber-200"
      "extended" -> "bg-red-900 text-red-200"
      "transition" -> "bg-cyan-900 text-cyan-200"
      "cover" -> "bg-pink-900 text-pink-200"
      "remix" -> "bg-orange-900 text-orange-200"
      "reprise" -> "bg-teal-900 text-teal-200"
      "intro" -> "bg-slate-700 text-slate-200"
      "version" -> "bg-emerald-900 text-emerald-200"
      "notable" -> "bg-yellow-900 text-yellow-200"
      "sequence" -> "bg-gray-700 text-gray-200"
      _ -> "bg-zinc-700 text-zinc-200"
    end
  end
end
