defmodule Library.Slices.Catalogue.Context do
  alias Library.Slices.Catalogue.ReadModel

  def catalogue, do: Library.StateView.read(Library.Application.fact_db(), ReadModel, nil)
end
