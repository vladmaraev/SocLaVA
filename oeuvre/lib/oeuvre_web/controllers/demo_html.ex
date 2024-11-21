defmodule OeuvreWeb.DemoHTML do
  use OeuvreWeb, :html

  embed_templates "demo_html/*"

  attr :image64, :string
  attr :description, :string

  def image(assigns) do
    ~H"""
    <div>
      <button id="start">Click to start!</button>
      <img src={"data:image/jpeg;base64, #{@image64}"} />
    </div>
    """
  end

  def script(assigns) do
    ~H"""
    <script type="module">
      window.dmActor.start();
        window.dmActor.send({type: "SETUP", value: `<%= @description %>`})
            document.getElementById("start").addEventListener("click", () => { window.dmActor.send({type: "START"}) }, false);
    </script>
    """
  end
end
