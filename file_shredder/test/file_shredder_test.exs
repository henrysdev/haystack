defmodule FileShredderTest do
  use ExUnit.Case
  doctest FileShredder

  test "greets the world" do
    assert FileShredder.hello() == :world
  end
end
