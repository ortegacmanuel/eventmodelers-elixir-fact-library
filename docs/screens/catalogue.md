# Screen: Catalogue

Slice `Catalogue` · node `67206f8c-577d-4ee1-8117-dfdeebf96aa5` · written by the loop on 2026-11-16.

Mockup: designed on the board. Open it with `mcp__eventmodelers__get_node` and the id above. It is a table with Title, Author and Status columns, and an "Add a book" button.

## How it's entered

```elixir
Library.Slices.Catalogue.Context.read() :: [
  %{book_id: String.t(), title: String.t(), author: String.t(), available: boolean()}
]
```

No arguments. It lists every book in the library, in the order the books were added.

## What it returns

One row per book:

| field | type | | what it is |
|---|---|---|---|
| `book_id` | `UUID` | | The book's id, from `BookAdded`. |
| `title` | `String` | | The title from `BookAdded`. If `BookTitleCorrected` arrived later, the latest corrected title. |
| `author` | `String` | | The author from `BookAdded`. |
| `available` | `Boolean` | | Whether the book can be lent. It is `true` once the book is added, `false` after `BookLent`, and `true` again after `BookReturned`. |

No field is optional: every row has all four values.

## What it sends back

Nothing. This is a read-only view. The "Add a book" button in the mockup belongs to the `Add book` slice (`Library.Slices.AddBook.Context.execute/1`).

## States to render

- **Empty**: an empty list when no books have been added ("An empty library has an empty catalogue").
- **Populated**: one row per book, each shown as available or on loan.

## What the board says about this screen

The screen node has no `description` on the board.

## What the domain does NOT give you

- **Who has a book, and when it is due.** `BookLent` carries `memberId` and `dueOn`, but this view leaves them out on purpose. Member's loans and overdue loans are separate slices.
- **Search, filtering, sorting or paging.** The domain returns the whole list in the order books were added. Anything else is up to the screen.
- **A count of copies.** Each book is a single item, so `available` is a yes/no value, not a number.
