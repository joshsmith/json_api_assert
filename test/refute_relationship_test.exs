defmodule RefuteRelationshipTest do
  use ExUnit.Case
  import JsonApiAssert, only: [refute_relationship: 3]
  import JsonApiAssert.TestData, only: [data: 1]

  test "will raise when relationship is found in a data record" do
    msg = "was not expecting to find the relationship `author` with `id` 1 and `type` \"author\" for record matching `id` 1 and `type` \"post\""

    try do
      refute_relationship(data(:payload), data(:author), as: "author", for: [:data, data(:post)])
    rescue
      error in [ExUnit.AssertionError] ->
        assert msg == error.message
    end
  end

  test "will raise if `as:` is not passed" do
    try do
      refute_relationship(data(:payload), data(:author), for: [:data, data(:post)])
    rescue
      error in [ExUnit.AssertionError] ->
        assert "you must pass `as:` with the name of the relationship" == error.message
    end
  end

  test "will raise if `for:` is not passed" do
    try do
      refute_relationship(data(:payload), data(:author), as: "author")
    rescue
      error in [ExUnit.AssertionError] ->
        assert "you must pass `for:` with the parent record" == error.message
    end
  end

  test "will not raise when child record's id not found as a relationship for parent" do
    author =
      data(:author)
      |> put_in(["id"], "2")

    refute_relationship(data(:payload), author, as: "author", for: [:data, data(:post)])
  end

  test "will not raise when child record's type not found as a relationship for parent" do
    author =
      data(:author)
      |> put_in(["type"], "writer")

    refute_relationship(data(:payload), author, as: "author", for: [:data, data(:post)])
  end

  test "will not raise when relationship name not found in data" do
    refute_relationship(data(:payload), data(:author), as: "writer", for: [:data, data(:post)])
  end

  test "will not raise when relationship name not found in included" do
    refute_relationship(data(:payload), data(:post), as: "posting", for: [:included, data(:author)])
  end

  test "will not raise when no relationship data in parent record" do
    payload = %{
      "jsonapi" => %{ "version" => "1.0" },
      "data" => %{
        "id" => "1",
        "type" => "post",
        "attributes" => %{
          "title" => "Mother of all demos"
        }
      }
    }

    refute_relationship(payload, data(:author), as: "writer", for: [:data, data(:post)])
  end

  test "will raise when parent record is not found" do
    post =
      data(:post)
      |> put_in(["attributes", "title"], "Father of all demos")

    try do
      refute_relationship(data(:payload), data(:author), as: "writer", for: [:data, post])
    rescue
      error in [ExUnit.AssertionError] ->
        assert %{"title" => "Mother of all demos"} == error.left
        assert %{"title" => "Father of all demos"} == error.right
        assert "record with `id` 1 and `type` \"post\" was found but had mis-matching attributes" == error.message
    end
  end

  test "will return the original payload" do
    payload = refute_relationship(data(:payload), data(:author), as: "writer", for: [:data, data(:post)])
    assert payload == data(:payload)
  end

  test "can refute many records at once" do
    payload = refute_relationship(data(:payload_2), [data(:comment_3), data(:comment_4)], as: "comments", for: [:data, data(:post)])

    assert payload == data(:payload_2)
  end

  test "will fail if one of the records is present" do
    msg = "was not expecting to find the relationship `comments` with `id` 1 and `type` \"comment\" for record matching `id` 1 and `type` \"post\""

    try do
      refute_relationship(data(:payload_2), [data(:comment_3), data(:comment_1)], as: "comments", for: [:data, data(:post)])
    rescue
      error in [ExUnit.AssertionError] ->
        assert msg == error.message
    end
  end
end
