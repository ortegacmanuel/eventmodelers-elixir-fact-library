defmodule Library.Slices.LendBook.Decider do
  use Library.StateChange

  alias Library.Slices.LendBook.{BookLent, LendBook}

  # The limit of 2 open loans per member comes from the board's scenario
  # "A member holding 2 books can't borrow a third".
  @max_open_loans 2

  @impl true
  def query(%LendBook{} = cmd) do
    [
      Fact.QueryItem.types(["BookAdded", "BookLent", "BookReturned"])
      |> Fact.QueryItem.tags(["book:#{cmd.book_id}"]),
      Fact.QueryItem.types(["BookLent", "BookReturned"])
      |> Fact.QueryItem.tags(["member:#{cmd.member_id}"])
    ]
  end

  @impl true
  def initial_state, do: %{added: false, open_loans: %{}}

  @impl true
  def apply_event(state, %{"event_type" => "BookAdded"}), do: %{state | added: true}

  def apply_event(state, %{"event_type" => "BookLent", "event_data" => d}) do
    put_in(state, [:open_loans, d["loan_id"]], %{book_id: d["book_id"], member_id: d["member_id"]})
  end

  def apply_event(state, %{"event_type" => "BookReturned", "event_data" => d}) do
    %{state | open_loans: Map.delete(state.open_loans, d["loan_id"])}
  end

  def apply_event(state, _), do: state

  @impl true
  def execute(%LendBook{} = cmd, state) do
    loans = Map.values(state.open_loans)

    cond do
      not state.added ->
        {:error, :book_not_found}

      Enum.any?(loans, &(&1.book_id == cmd.book_id)) ->
        {:error, :book_already_lent}

      Enum.count(loans, &(&1.member_id == cmd.member_id)) >= @max_open_loans ->
        {:error, :member_holds_two_books}

      true ->
        {:ok,
         [
           %BookLent{
             loan_id: cmd.loan_id,
             book_id: cmd.book_id,
             member_id: cmd.member_id,
             due_on: cmd.due_on,
             lent_at: cmd.lent_at
           }
         ]}
    end
  end
end
