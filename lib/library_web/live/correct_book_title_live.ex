defmodule LibraryWeb.CorrectBookTitleLive do
  use LibraryWeb, :live_view

  alias Library.Slices.{Catalogue, CorrectBookTitle}

  @impl true
  def mount(params, _session, socket) do
    books = Catalogue.Context.catalogue()

    {:ok,
     socket
     |> assign(:page_title, "Correct a book's title")
     |> assign(:options, Enum.map(books, &{"#{&1.title} — #{&1.author}", &1.book_id}))
     |> assign(:error, nil)
     |> assign_form(Map.take(params, ["book_id"]), nil)}
  end

  @impl true
  def handle_event("validate", %{"book" => params}, socket),
    do: {:noreply, assign_form(socket, params, :validate)}

  def handle_event("save", %{"book" => params}, socket) do
    case CorrectBookTitle.Context.correct_book_title(params) do
      {:ok, _book_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "The title is now #{params["title"]}.")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :book, action: :insert))}

      {:error, reason} ->
        {:noreply, socket |> assign(:error, reason) |> assign_form(params, :insert)}
    end
  end

  defp assign_form(socket, params, action) do
    changeset = CorrectBookTitle.CorrectBookTitle.changeset(params)
    assign(socket, :form, to_form(changeset, as: :book, action: action))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Correct a book's title</.header>

      <div :if={@error} id="error" role="alert" class="alert alert-error">
        {LibraryWeb.DomainErrors.message(@error)}
      </div>

      <p :if={@options == []} id="nothing-to-correct" class="text-base-content/70">
        The catalogue is empty: there's no title to correct.
      </p>

      <.form
        :if={@options != []}
        for={@form}
        id="correct-title"
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:book_id]}
          type="select"
          label="Book"
          prompt="Choose a book"
          options={@options}
        />
        <.input field={@form[:title]} label="Correct title" />
        <div class="mt-6 flex gap-2">
          <.button variant="primary" phx-disable-with="Saving…">Save title</.button>
          <.button navigate={~p"/"}>Cancel</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
