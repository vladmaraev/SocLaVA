defmodule OeuvreWeb.OllamaController do
  use OeuvreWeb, :controller
  alias Oeuvre.OllamaService
  alias Phoenix.PubSub
  require Logger

  def describe_image(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    descr = OllamaService.ollama_generate_visual_description("Degas")
    json(conn, %{:description => descr})
  end

  def chat(
        conn,
        %{"description" => description, "history" => history}
      ) do
    PubSub.subscribe(Oeuvre.PubSub, "user:123")
    OllamaService.chat(description, history)
    result = loop("")
    json(conn, %{:role => "user", :content => result})
  end

  defp loop(string) do
    receive do
      "" ->
        string

      msg ->
        loop(string <> msg)
    end
  end
end
