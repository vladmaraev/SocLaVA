defmodule Oeuvre.SshTunnel do
  require Logger
  require SSHEx

  @remote_host ~c"gpu.scai.sorbonne-universite.fr"
  @remote_port 22
  @user ~c"maraev"

  @local_port 10012

  def connect() do
    :ssh.start()

    case :ssh.connect(@remote_host, @remote_port,
           user: @user,
           silently_accept_hosts: true,
           user_interaction: false
         ) do
      {:ok, conn} ->
        Logger.info("Successfully connected to #{@remote_host}")
        conn

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def setup_port_forwarding(conn) do
    :ssh.tcpip_tunnel_to_server(
      conn,
      "localhost",
      @local_port,
      "localhost",
      @local_port
    )

    Logger.info("Port forwarding from local port #{@local_port} to remote port #{@local_port}")
  end

  def start_ollama(conn) do
    stream = SSHEx.stream(conn, "ls -l")

    Enum.each(stream, fn x ->
      case x do
        {:stdout, row} -> Logger.info(row)
        {:stderr, row} -> Logger.error(row)
        {:status, status} -> Logger.info("Status: #{status}")
        {:error, reason} -> Logger.error(reason)
        x -> Logger.info("Other: #{x}")
      end
    end)

    # {:ok, channel} = :ssh_connection.session_channel(conn, :infinity)
    # :ssh_connection.exec(conn, channel, "srun -p electronic --gpus-per-node=1 -t 1 --pty bash", :infinity)
    # {:ok, new_channel} = :ssh_connection.session_channel(conn, :infinity)
    # res = :ssh_connection.exec(conn, new_channel, "./ollama.sh", :infinity)
    # log_ollama(conn)
    # res
  end

  def forward_srun_port(conn) do
    {:ok, channel} = :ssh_connection.session_channel(conn, :infinity)
    :ssh_connection.exec(conn, channel, "ssh led -L 10012:127.0.0.1:10012", :infinity)
    log_ollama(conn)
  end

  defp log_ollama(conn) do
    receive do
      {:ssh_cm, ^conn, {_, _, _, value}} ->
        Logger.info(value)
        log_ollama(conn)
    end
  end

  def cleanup(conn) do
    :ssh.close(conn)
    Logger.info("SSH connection closed.")
  end
end
