<!-- Generated from the slice-state event log. Record learnings with the learn command; do not edit. -->

## About automation slices
- When an automation's TODO-queue slice isn't built yet, build against its assumed Context anyway (request-feedback forbids blocking on an unbuilt dependency): hold the queue module as a value in the processor state (Keyword.get(opts, :queue, Queue)) so the call stays dynamic and compile --warnings-as-errors stays green; the poll's rescue logs the UndefinedFunctionError until the queue exists.

## About write slices
- A decision spanning two consistency boundaries (e.g. book and member) is one DCB read: query/1 returns a list of Fact.QueryItem (OR-ed by Reader), each scoped by its own tag; append_condition follows. apply_event doesn't see the command, so fold keyed by the event's own id (e.g. open loans by loan_id) and filter by the command's ids inside execute/2.

## Slice layout
- Slice folder/module name = title NFD-stripped, downcased, every non-alnum run -> '_' ("Member's loans" -> member_s_loans, MemberSLoans). scenario_tests_test.exs silently skips test dirs with any other name.

## Read slices
- A view scoped by one tag that needs fields from events carrying only another tag (title on book:-tagged events, view by member:): fold the ids, then next_query/1 returns one QueryItem per id.
