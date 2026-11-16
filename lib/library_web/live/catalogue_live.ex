defmodule LibraryWeb.CatalogueLive do
  use LibraryWeb, :live_view

  alias Library.Slices.Catalogue

  @impl true
  def mount(_params, _session, socket) do
    books = Catalogue.Context.catalogue()

    {:ok,
     socket
     |> assign(:page_title, "Catalogue")
     |> assign(:empty?, books == [])
     |> stream_configure(:books, dom_id: &"book-#{&1.book_id}")
     |> stream(:books, books)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Catalogue
        <:actions>
          <.button navigate={~p"/books/new"} variant="primary">Add a book</.button>
        </:actions>
      </.header>

      <p :if={@empty?} id="empty-catalogue" class="text-base-content/70">
        No books yet. Add the first one.
      </p>

      <.table :if={!@empty?} id="books" rows={@streams.books}>
        <:col :let={{_id, book}} label="Title">{book.title}</:col>
        <:col :let={{_id, book}} label="Author">{book.author}</:col>
        <:col :let={{_id, book}} label="Status">
          <span :if={book.available} class="badge badge-success badge-soft">Available</span>
          <span :if={!book.available} class="badge badge-warning badge-soft">On loan</span>
        </:col>
        <:action :let={{_id, book}}>
          <.link :if={book.available} navigate={~p"/loans/new?#{[book_id: book.book_id]}"}>
            Lend
          </.link>
          <.link :if={!book.available} navigate={~p"/returns/new?#{[book_id: book.book_id]}"}>
            Return
          </.link>
        </:action>
        <:action :let={{_id, book}}>
          <.link
            navigate={~p"/books/correct-title?#{[book_id: book.book_id]}"}
            class="whitespace-nowrap"
          >
            Correct title
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
