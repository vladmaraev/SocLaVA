defmodule Oeuvre.OllamaService do
  require Req
  require Jason
  require Logger

  alias Phoenix.PubSub

  def get_image_base64(imgname) do
    {:ok, %{:status => status, :body => body}} =
      Req.get(
        "https://ttlfngopsrcdgjlvuitl.supabase.co/storage/v1/object/public/images/#{imgname}.jpg"
      )

    case status do
      200 -> {:ok, Base.encode64(body)}
      400 -> {:error, "Image not found"}
    end
  end

  defp visual_description_prompt do
    """
    Please provide a description which would be suitable for a
    human to assess the artistic quality of the image. Be as precise
    and specific as possible. Additionally, describe what is depicted on this image.
    """
  end

  defp chat_system_prompt(image_description) do
    """
    You will be chatting with the user using spoken language. Keep your response VERY brief. Please,answer with just one very short sentence!\n\nBoth you and the user are presented with an artwork and you need to express your opinion about it. In dialogue, you need to come to agreement about the artistic qualities of the work. You can "see" the image through the vision module which tells you the following:\n\n
    #{image_description}
    \n\nDon't forget to you keep your response consise. If the user is not responding say: "Sorry, I didn't hear you."
    """
  end

  def chat(image_description, history \\ []) do
    Req.post!("http://localhost:11434/api/chat",
      json: %{
        model: "zephyr",
        stream: true,
        options: %{num_predict: 50},
        messages: [
          %{role: "system", content: chat_system_prompt(image_description)}
          | history
        ]
      },
      into: fn {:data, data}, {req, resp} ->
        decoded_data = Jason.decode!(data)
        content = decoded_data["message"]["content"]
        PubSub.broadcast(Oeuvre.PubSub, "user:123", content)
        Logger.debug(">>> '#{content}'")
        {:cont, {req, resp}}
      end
    )
  end

  def ollama_generate_visual_description(image64) do
    Req.post!("http://localhost:11434/api/generate",
      cache: true,
      json: %{
        model: "llava:34b",
        stream: false,
        prompt: visual_description_prompt(),
        images: [image64]
      }
    ).body["response"]
  end
end
