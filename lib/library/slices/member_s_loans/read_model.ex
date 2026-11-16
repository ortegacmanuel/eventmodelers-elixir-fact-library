defmodule Library.Slices.MemberSLoans.ReadModel do
  @behaviour Library.StateView

  @impl true
  def query(member_id) do
    Fact.QueryItem.types(["BookLent", "BookReturned"])
    |> Fact.QueryItem.tags(["member:#{member_id}"])
  end

  # The titles live on book:-tagged events only, so each lent book is read in a second round.
  @impl true
  def next_query(state) do
    for {_loan_id, loan} <- state.loans,
        do:
          Fact.QueryItem.types(["BookAdded", "BookTitleCorrected"])
          |> Fact.QueryItem.tags(["book:#{loan.book_id}"])
  end

  @impl true
  def initial_state, do: %{order: [], loans: %{}, titles: %{}}

  @impl true
  def apply_event(state, %{"event_type" => "BookLent", "event_data" => d}) do
    loan = %{loan_id: d["loan_id"], book_id: d["book_id"], due_on: d["due_on"]}

    %{
      state
      | order: [d["loan_id"] | state.order],
        loans: Map.put(state.loans, d["loan_id"], loan)
    }
  end

  def apply_event(state, %{"event_type" => "BookReturned", "event_data" => d}) do
    %{state | loans: Map.delete(state.loans, d["loan_id"])}
  end

  def apply_event(state, %{"event_type" => "BookAdded", "event_data" => d}) do
    %{state | titles: Map.put_new(state.titles, d["book_id"], d["title"])}
  end

  def apply_event(state, %{"event_type" => "BookTitleCorrected", "event_data" => d}) do
    %{state | titles: Map.put(state.titles, d["book_id"], d["title"])}
  end

  def apply_event(state, _), do: state

  # Open loans in the order they were lent.
  @impl true
  def project(state, _member_id) do
    for loan_id <- Enum.reverse(state.order),
        loan = state.loans[loan_id],
        loan != nil,
        do: Map.put(loan, :title, state.titles[loan.book_id])
  end
end
