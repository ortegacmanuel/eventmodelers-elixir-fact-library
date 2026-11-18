defmodule Library.Slices.MemberSLoans.Context do
  alias Library.Slices.MemberSLoans.ReadModel

  def read(member_id),
    do: Library.StateView.read(Library.Application.fact_db(), ReadModel, member_id)
end
