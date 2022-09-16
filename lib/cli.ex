defmodule Opal.CLI do
  alias Opal

  @cli_options %{
    "SET" => "set values using: \"SET <key> <value>\".",
    "GET" => "retrieve values using: \"GET <key>\".",
    "DELETE" => "delete values using: \"DELETE <key>\".",
    "COUNT" => "return the number of keys that have a certain value using: \"COUNT <value>\".",
    "BEGIN" => "start a new transaction",
    "COMMIT" => "complete the current transaction",
    "ROLLBACK" => "revert the state prior to BEGIN call",
    "QUIT" => "End the session and clear the store"
  }

  def main(args) do
    args
    |> parse_args
    |> process_args
  end

  def parse_args(args) do
    {params, _, _} = OptionParser.parse(args, switches: [help: :boolean])
    params
  end

  def process_args([help: true]) do
    print_instructions()
    receive_user_input()
  end

  def process_args(_) do
    IO.puts("Welcome to your CLI. Store some words, change some words or maybe don't.")
    print_instructions()
    receive_user_input()
  end

  defp receive_user_input(store \\ %{}, store_state \\ %{}) do
    IO.gets("\n> ")
    |> String.trim()
    |> String.split(" ")
    |> handle_and_route_command(store, store_state)
  end

  def handle_and_route_command(["GET" | opts], store, store_state) when length(opts) > 1 do
      IO.puts("\nYour input is invalid, Please follow GET instructions and provide the correct values")
      receive_user_input(store, store_state)
  end

  def handle_and_route_command(["GET" | opts], store, store_state) when length(opts) == 1 do
    case Map.get(store, List.first(opts)) do
      nil ->
        IO.puts("\nThat key is not set yet")
        receive_user_input(store)

      value -> 
        IO.puts("#{value}")
        receive_user_input(store, store_state)
    end
  end

  def handle_and_route_command(["DELETE" | opts], store, store_state) do
    if length(opts) > 1 do
      IO.puts("\nYour input is invalid, Please follow DELETE instructions and provide the correct values")
      receive_user_input(store, store_state)
    else
      new_store = Map.delete(store, List.first(opts))
      IO.puts("\nYou deleted key: #{List.first(opts)}. Store has remaining keys. #{Map.keys(new_store)}")
      receive_user_input(new_store, store_state)
    end
  end

  def handle_and_route_command(["SET" | opts], store, store_state) do
    if length(opts) < 2 do
      IO.puts("\nYour input is invalid, Please follow DELETE instructions and provide the correct values")
      receive_user_input(store)
    else
      [key, value] = opts
      new_store = Map.put(store, key, value)
      receive_user_input(new_store, store_state)
    end
  end

  def handle_and_route_command(["COUNT" | opts], store, store_state) do
    matches = Enum.count(store, fn {_key, value} -> value == List.first(opts) end)
    IO.puts("\nThere are #{matches} in your store for value: #{List.first(opts)}")
    receive_user_input(store, store_state)
  end

  def handle_and_route_command(["BEGIN"], current_store, state_store) when is_list(state_store) do
    store_state = List.insert_at(state_store, 0, current_store)
    receive_user_input(%{}, store_state)
  end

  def handle_and_route_command(["BEGIN"], current_store, _state_store) do
    state = []
    store_state = List.insert_at(state, 0, current_store)
    receive_user_input(%{}, store_state)
  end

  def handle_and_route_command(["COMMIT"], _store, _) do
    IO.puts("\nNo transaction")
    receive_user_input(%{}, %{})
  end

  def handle_and_route_command(["ROLLBACK"], _store, store_state) do
    {old_store, state} = List.pop_at(store_state, 0)
    receive_user_input(old_store, state)
  end

  def handle_and_route_command(["QUIT" | _opts], _store, _store_state) do
    IO.puts("\nClosing session and clearing all values.")
  end

  def handle_and_route_command(_opts, store, store_state) do
    IO.puts("\nInvalid option. Please enter a valid option")
    print_instructions()
    receive_user_input(store, store_state)
  end

  defp print_instructions do
    IO.puts("\nThe CLI accepts the following options: \n")
    @cli_options
    |> Enum.map(fn({option, description}) -> IO.puts(" #{option} - #{description}") end)
  end
end