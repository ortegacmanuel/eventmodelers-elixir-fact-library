defmodule Library.Slices.AddBook.Context do
  alias Library.Slices.AddBook.{AddBook, Core}

  require Logger

  def add_book(params) do
    with {:ok, cmd} <- AddBook.new(params, %{book_id: Ecto.UUID.generate()}),
         {:ok, _events} <- write(cmd) do
      {:ok, cmd.book_id}
    end
  end

  defp write(cmd) do
    Library.Decide.execute(Library.Application.fact_db(), Core, cmd)
  rescue
    e in RuntimeError ->
      Logger.error("could not write: #{Exception.message(e)}")
      {:error, :store_unavailable}
  end
end
