defmodule Library.Slices.OverdueLoansToRemind.Context do
  alias Library.Slices.OverdueLoansToRemind.Core

  def pending, do: Library.StateView.read(Library.Application.fact_db(), Core, Date.utc_today())
end
