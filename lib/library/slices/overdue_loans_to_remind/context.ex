defmodule Library.Slices.OverdueLoansToRemind.Context do
  alias Library.Slices.OverdueLoansToRemind.ReadModel

  def pending,
    do: Library.StateView.read(Library.Application.fact_db(), ReadModel, Date.utc_today())
end
