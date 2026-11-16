defmodule Library.Slices.Catalogue.Core do
  @behaviour Library.StateView

  # The whole catalogue, every book: read by types, not scoped by a book: tag.
  @impl true
  def query(_args) do
    Fact.QueryItem.types(["BookAdded", "BookTitleCorrected", "BookLent", "BookReturned"])
  end

  @impl true
  def initial_state, do: %{order: [], books: %{}}

  @impl true
  def apply_event(state, %{"event_type" => "BookAdded", "event_data" => d}) do
    if Map.has_key?(state.books, d["book_id"]) do
      state
    else
      book = %{book_id: d["book_id"], title: d["title"], author: d["author"], available: true}

      %{
        state
        | order: [d["book_id"] | state.order],
          books: Map.put(state.books, d["book_id"], book)
      }
    end
  end

  def apply_event(state, %{"event_type" => "BookTitleCorrected", "event_data" => d}) do
    %{state | books: Map.replace_lazy(state.books, d["book_id"], &%{&1 | title: d["title"]})}
  end

  def apply_event(state, %{"event_type" => "BookLent", "event_data" => d}) do
    %{state | books: Map.replace_lazy(state.books, d["book_id"], &%{&1 | available: false})}
  end

  def apply_event(state, %{"event_type" => "BookReturned", "event_data" => d}) do
    %{state | books: Map.replace_lazy(state.books, d["book_id"], &%{&1 | available: true})}
  end

  def apply_event(state, _), do: state

  # Books in the order they were added to the catalogue.
  @impl true
  def project(state, _args), do: state.order |> Enum.reverse() |> Enum.map(&state.books[&1])
end
