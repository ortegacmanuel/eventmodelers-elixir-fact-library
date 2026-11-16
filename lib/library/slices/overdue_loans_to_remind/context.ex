defmodule Library.Slices.OverdueLoansToRemind.Context do
  alias Library.Slices.OverdueLoansToRemind.Core

  def overdue_loans_to_remind(%Date{} = today),
    do: Library.StateView.read(Library.Application.fact_db(), Core, today)
end
