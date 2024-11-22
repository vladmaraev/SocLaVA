defmodule OeuvreWeb.AzureController do
  use OeuvreWeb, :controller
    alias Oeuvre.AzureService

  require Logger

  def token(conn, _params) do
    token = Oeuvre.AzureService.get_token()
    text(conn, token)
  end
end
