defmodule Library.Slices.CorrectBookTitle.Core do
  use Library.StateChange

  alias Library.Slices.CorrectBookTitle.{BookTitleCorrected, CorrectBookTitle}

  @impl true
  def query(%CorrectBookTitle{} = cmd) do
    Fact.QueryItem.types(["BookAdded"])
    |> Fact.QueryItem.tags(["book:#{cmd.book_id}"])
  end

  @impl true
  def initial_state, do: %{added: false}

  @impl true
  def apply_event(state, %{"event_type" => "BookAdded"}), do: %{state | added: true}
  def apply_event(state, _), do: state

  @impl true
  def execute(_cmd, %{added: false}), do: {:error, :book_not_found}

  def execute(%CorrectBookTitle{} = cmd, _state) do
    {:ok, [%BookTitleCorrected{book_id: cmd.book_id, title: cmd.title}]}
  end
end
