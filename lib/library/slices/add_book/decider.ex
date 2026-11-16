defmodule Library.Slices.AddBook.Decider do
  use Library.StateChange

  alias Library.Slices.AddBook.{AddBook, BookAdded}

  @impl true
  def query(%AddBook{} = cmd) do
    Fact.QueryItem.types(["BookAdded"])
    |> Fact.QueryItem.tags(["book:#{cmd.book_id}"])
  end

  @impl true
  def initial_state, do: %{added: false}

  @impl true
  def apply_event(state, %{"event_type" => "BookAdded"}), do: %{state | added: true}
  def apply_event(state, _), do: state

  @impl true
  def execute(_cmd, %{added: true}), do: {:ok, []}

  def execute(%AddBook{} = cmd, _state) do
    {:ok, [%BookAdded{book_id: cmd.book_id, title: cmd.title, author: cmd.author}]}
  end
end
