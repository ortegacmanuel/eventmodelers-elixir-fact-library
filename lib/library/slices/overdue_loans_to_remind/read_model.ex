defmodule Library.Slices.OverdueLoansToRemind.ReadModel do
  @behaviour Library.StateView

  # A TODO queue for the reminder processor: read by types, not scoped by a tag.
  @impl true
  def query(_today) do
    Fact.QueryItem.types(["BookLent", "BookReturned", "ReminderSent"])
  end

  @impl true
  def initial_state, do: %{order: [], loans: %{}}

  @impl true
  def apply_event(state, %{"event_type" => "BookLent", "event_data" => d}) do
    loan = %{
      loan_id: d["loan_id"],
      book_id: d["book_id"],
      member_id: d["member_id"],
      due_on: Date.from_iso8601!(d["due_on"])
    }

    %{
      state
      | order: [d["loan_id"] | state.order],
        loans: Map.put(state.loans, d["loan_id"], loan)
    }
  end

  def apply_event(state, %{"event_type" => type, "event_data" => d})
      when type in ["BookReturned", "ReminderSent"] do
    %{state | loans: Map.delete(state.loans, d["loan_id"])}
  end

  def apply_event(state, _), do: state

  # Overdue means the due date is before today; a loan due today is not yet overdue.
  @impl true
  def project(state, today) do
    for loan_id <- Enum.reverse(state.order),
        loan = state.loans[loan_id],
        loan != nil,
        Date.compare(loan.due_on, today) == :lt,
        do: loan
  end
end
