defmodule Library.Slices.Catalogue.Context do
  alias Library.Slices.Catalogue.Core

  def catalogue, do: Library.StateView.read(Library.Application.fact_db(), Core, nil)
end
