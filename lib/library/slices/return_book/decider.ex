defmodule Library.Slices.ReturnBook.Decider do
  use Library.StateChange

  alias Library.Slices.ReturnBook.{BookReturned, ReturnBook}

  @impl true
  def query(%ReturnBook{} = cmd) do
    Fact.QueryItem.types(["BookLent", "BookReturned"])
    |> Fact.QueryItem.tags(["book:#{cmd.book_id}"])
  end

  @impl true
  def initial_state, do: %{open_loan: nil}

  @impl true
  def apply_event(state, %{"event_type" => "BookLent", "event_data" => d}) do
    %{state | open_loan: %{loan_id: d["loan_id"], member_id: d["member_id"]}}
  end

  def apply_event(state, %{"event_type" => "BookReturned"}), do: %{state | open_loan: nil}

  def apply_event(state, _), do: state

  @impl true
  def execute(_cmd, %{open_loan: nil}), do: {:error, :book_not_lent}

  def execute(%ReturnBook{} = cmd, %{open_loan: loan}) do
    {:ok,
     [
       %BookReturned{
         loan_id: loan.loan_id,
         book_id: cmd.book_id,
         member_id: loan.member_id,
         returned_at: cmd.returned_at
       }
     ]}
  end
end
