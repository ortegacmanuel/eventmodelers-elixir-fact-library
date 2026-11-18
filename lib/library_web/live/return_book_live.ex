defmodule LibraryWeb.ReturnBookLive do
  use LibraryWeb, :live_view

  alias Library.Slices.{Catalogue, ReturnBook}

  @impl true
  def mount(params, _session, socket) do
    on_loan = Enum.reject(Catalogue.Context.read(), & &1.available)

    {:ok,
     socket
     |> assign(:page_title, "Return a book")
     |> assign(:options, Enum.map(on_loan, &{"#{&1.title} — #{&1.author}", &1.book_id}))
     |> assign(:error, nil)
     |> assign_form(Map.take(params, ["book_id"]), nil)}
  end

  @impl true
  def handle_event("validate", %{"return" => params}, socket),
    do: {:noreply, assign_form(socket, params, :validate)}

  def handle_event("save", %{"return" => params}, socket) do
    case ReturnBook.Context.execute(params) do
      {:ok, _loan_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "The book is back and available.")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :return, action: :insert))}

      {:error, reason} ->
        {:noreply, socket |> assign(:error, reason) |> assign_form(params, :insert)}
    end
  end

  defp assign_form(socket, params, action) do
    changeset = ReturnBook.ReturnBook.changeset(params)
    assign(socket, :form, to_form(changeset, as: :return, action: action))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Return a book</.header>

      <div :if={@error} id="error" role="alert" class="alert alert-error">
        {LibraryWeb.DomainErrors.message(@error)}
      </div>

      <p :if={@options == []} id="nothing-to-return" class="text-base-content/70">
        No book is on loan right now.
      </p>

      <.form
        :if={@options != []}
        for={@form}
        id="return-book"
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
        <p class="-mt-1 mb-2 text-sm text-base-content/70">Only books that are on loan.</p>
        <div class="mt-6 flex gap-2">
          <.button variant="primary" phx-disable-with="Returning…">Return book</.button>
          <.button navigate={~p"/"}>Cancel</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end
end
