defmodule <%= web_module %>.UserSocket do
  use Phoenix.Socket

  # Channels can be added here. Example:
  #
  #     channel "room:*", <%= web_module %>.RoomChannel
  #
  # To add real-time features:
  # 1. Create a channel module (e.g., lib/<%= web_dir %>/channels/room_channel.ex)
  # 2. Add the channel route above
  # 3. Subscribe from React using useChannel hook

  @impl true
  def connect(params, socket, _connect_info) do
    # Verify CSRF token for security
    # In production, you may want to authenticate users here
    # and assign user_id to the socket.
    #
    # Example with user authentication:
    #   case verify_token(params["token"]) do
    #     {:ok, user_id} -> {:ok, assign(socket, :user_id, user_id)}
    #     {:error, _} -> :error
    #   end

    {:ok, socket}
  end

  @impl true
  def id(_socket) do
    # Return nil for anonymous connections
    # For authenticated users, return a unique identifier:
    #   "user_socket:#{socket.assigns.user_id}"
    nil
  end
end
