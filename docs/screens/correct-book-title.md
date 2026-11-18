# Screen: Correct a book's title

Slice `Correct book title` · node `dcee0f7c-af00-4f80-a13f-8a1d060e17d4` · written by the loop on 2026-11-16.

Mockup: designed on the board — `get_node` with the id above (one page: a "Book" select
showing "Title — Author", a "Correct title" text input, a "Save title" button and a
"Cancel" button).

## How it's entered

The book picker is filled from the `Catalogue` slice (the screen's `books` and `authors`
fields map to `Catalogue.title` / `Catalogue.author`):

```elixir
Library.Slices.Catalogue.Context.read() :: [
  %{book_id: String.t(), title: String.t(), author: String.t(), available: boolean()}
]
```

The form is built from the command:

```elixir
to_form(Library.Slices.CorrectBookTitle.CorrectBookTitle.changeset(params))
```

## What it returns

From the catalogue, one option per book:

| field | type | | what it is |
|---|---|---|---|
| `books` | `String` (list) | | mapped to `Catalogue.title` |
| `authors` | `String` (list) | | mapped to `Catalogue.author` |

The form's fields:

| field | type | | what it is |
|---|---|---|---|
| `bookId` | `UUID` | required | the selected book, mapped to `CorrectBookTitle.bookId` |
| `title` | `String` | required | the corrected title, mapped to `CorrectBookTitle.title` |

## What it sends back

```elixir
Library.Slices.CorrectBookTitle.Context.execute(%{"book_id" => book_id, "title" => title})
# {:ok, book_id}
# {:error, %Ecto.Changeset{}}   # book_id or title missing/blank (validation: :required)
# {:error, :book_not_found}     # no BookAdded for that book id
# {:error, :store_unavailable}  # the event store isn't up
```

Domain error atoms: **`:book_not_found`** — board scenario "A book that was never added
can't be corrected". Plus `:store_unavailable` (infrastructure).

## States to render

- Empty catalogue: no book to pick; nothing can be corrected.
- Form with a book selected and the title input.
- Field errors once touched or submitted (`used_input?/1`).
- Submitted: `{:ok, book_id}` — the catalogue now shows the corrected title; where to go next isn't on the board.
- `:book_not_found` / `:store_unavailable`: the title was not saved, the input must survive.

## What the board says about this screen

The screen node has no `description`.

## What the domain does NOT give you

- Only the title can be corrected — no author correction, no other book field.
- No rule that the new title differs from the current one, and no history of past titles:
  correcting twice simply records two `BookTitleCorrected`, the last one wins in the views.
- No lookup of the current title by this slice: the select's labels come from `Catalogue`.
- "Cancel" has no domain counterpart; it's navigation only.
