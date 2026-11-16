defmodule LibraryWeb.AddBookLive do
  use LibraryWeb, :live_view

  alias Library.Slices.AddBook

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Add a book")
     |> assign(:error, nil)
     |> assign_form(%{}, nil)}
  end

  @impl true
  def handle_event("validate", %{"book" => params}, socket),
    do: {:noreply, assign_form(socket, params, :validate)}

  def handle_event("save", %{"book" => params}, socket) do
    case AddBook.Context.add_book(params) do
      {:ok, _book_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{params["title"]} is in the catalogue.")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :book, action: :insert))}

      {:error, reason} ->
        {:noreply, socket |> assign(:error, reason) |> assign_form(params, :insert)}
    end
  end

  defp assign_form(socket, params, action),
    do:
      assign(socket, :form, to_form(AddBook.AddBook.changeset(params), as: :book, action: action))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Add a book</.header>

      <div :if={@error} id="error" role="alert" class="alert alert-error">
        {LibraryWeb.DomainErrors.message(@error)}
      </div>

      <.form for={@form} id="add-book" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} label="Title" />
        <.input field={@form[:author]} label="Author" />
        <div class="mt-6 flex gap-2">
          <.button variant="primary" phx-disable-with="Adding…">Add book</.button>
          <.button navigate={~p"/"}>Cancel</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
