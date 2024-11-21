defmodule Mix.Tasks.OllamaTunnel do
  @shortdoc "Starts up a tunnel to Ollama server"
  require Logger
  @remote_host "gpu.scai.sorbonne-universite.fr"
  @remote_port 22
  @user "maraev"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    case :ssh.connect(@remote_host, @remote_port, [{:user, @user}]) do
      {:ok, conn} ->
        Logger.info("Successfully connected to #{@remote_host}")
        conn

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
