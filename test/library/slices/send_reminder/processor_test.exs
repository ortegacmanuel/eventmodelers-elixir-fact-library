defmodule Library.Slices.SendReminder.ProcessorTest do
  use ExUnit.Case, async: true

  @moduletag :extra

  alias Library.Slices.SendReminder.Processor

  test "the launch decision allows one sweep at a time" do
    ref = make_ref()

    assert Processor.room_for?(%{})
    refute Processor.room_for?(%{ref => :sweep})
    assert Processor.room_for?(Map.delete(%{ref => :sweep}, ref))
  end
end
