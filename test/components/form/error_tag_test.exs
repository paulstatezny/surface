defmodule Surface.Components.Form.ErrorTagTest.Common do
  @moduledoc """
  Common functions used by both ErrorTagTest and ErrorTagSyncTest
  """

  def changeset do
    {%{}, %{name: :string}}
    |> Ecto.Changeset.cast(%{name: "myname"}, [:name])
    |> Ecto.Changeset.add_error(:name, "is already taken")
    |> Ecto.Changeset.add_error(:name, "another test error")
    # Simulate that form submission already occurred so that error message will display
    |> Map.put(:action, :insert)
  end
end

defmodule Surface.Components.Form.ErrorTagTest do
  use Surface.ConnCase, async: true

  alias Surface.Components.Form.ErrorTagTest.Common
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag

  setup do
    %{changeset: Common.changeset()}
  end

  test "multiple error messages", %{changeset: changeset} do
    assigns = %{changeset: changeset}

    html =
      render_surface do
        ~H"""
        <Form for={{@changeset}} opts={{ as: :user }}>
          <Field name={{ :name }}>
            <ErrorTag />
          </Field>
        </Form>
        """
      end

    assert html =~
             "<span phx-feedback-for=\"user_name\">is already taken</span>"

    assert html =~
             "<span phx-feedback-for=\"user_name\">another test error</span>"
  end

  test "no errors are shown if changeset.action is empty", %{changeset: changeset} do
    changeset_without_action = Map.put(changeset, :action, nil)

    assigns = %{changeset: changeset_without_action}

    html =
      render_surface do
        ~H"""
        <Form for={{@changeset}} opts={{ as: :user }}>
          <Field name={{ :name }}>
            <ErrorTag />
          </Field>
        </Form>
        """
      end

    refute html =~ "is already taken"
    refute html =~ "another test error"
  end

  test "prop phx_feedback_for", %{changeset: changeset} do
    assigns = %{changeset: changeset}

    html =
      render_surface do
        ~H"""
        <Form for={{@changeset}} opts={{ as: :user }}>
          <Field name={{ :name }}>
            <ErrorTag phx_feedback_for="test-id" />
          </Field>
        </Form>
        """
      end

    assert html =~
             "<span phx-feedback-for=\"test-id\">is already taken</span>"
  end

  test "prop class", %{changeset: changeset} do
    assigns = %{changeset: changeset}

    html =
      render_surface do
        ~H"""
        <Form for={{@changeset}} opts={{ as: :user }}>
          <Field name={{ :name }}>
            <ErrorTag class="test-class" />
          </Field>
        </Form>
        """
      end

    assert html =~
             "<span class=\"test-class\" phx-feedback-for=\"user_name\">is already taken</span>"
  end

  test "no changeset shows no errors" do
    html =
      render_surface do
        ~H"""
        <Form for={{ :user }}>
          <Field name={{ :name }}>
            <ErrorTag />
          </Field>
        </Form>
        """
      end

    # The error tags are displayed as spans, so this demonstrates that none were rendered
    refute html =~ "<span"
  end
end

defmodule Surface.Components.Form.ErrorTagSyncTest do
  use Surface.ConnCase

  alias Surface.Components.Form.ErrorTagTest.Common
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag

  setup do
    %{changeset: Common.changeset()}
  end

  test "translator from config", %{changeset: changeset} do
    using_config ErrorTag,
      default_translator: {Surface.Components.Form.ErrorTagSyncTest, :config_translate_error} do
      assigns = %{changeset: changeset}

      html =
        render_surface do
          ~H"""
          <Form for={{@changeset}} opts={{ as: :user }}>
            <Field name={{ :name }}>
              <ErrorTag />
            </Field>
          </Form>
          """
        end

      assert html =~
               "<span phx-feedback-for=\"user_name\">translated by config translator</span>"
    end
  end

  test "prop translator overrides config and fallback", %{changeset: changeset} do
    using_config ErrorTag,
      default_translator: {Surface.Components.Form.ErrorTagSyncTest, :config_translate_error} do
      assigns = %{changeset: changeset}

      html =
        render_surface do
          ~H"""
          <Form for={{@changeset}} opts={{ as: :user }}>
            <Field name={{ :name }}>
              <ErrorTag translator={{ fn _ -> "translated by prop translator" end }} />
            </Field>
          </Form>
          """
        end

      assert html =~
               "<span phx-feedback-for=\"user_name\">translated by prop translator</span>"

      refute html =~
               "<span phx-feedback-for=\"user_name\">translated by config translator</span>"
    end
  end

  test "default_class from config", %{changeset: changeset} do
    using_config ErrorTag, default_class: "class-from-config" do
      assigns = %{changeset: changeset}

      html =
        render_surface do
          ~H"""
          <Form for={{@changeset}} opts={{ as: :user }}>
            <Field name={{ :name }}>
              <ErrorTag />
            </Field>
          </Form>
          """
        end

      assert html =~
               "<span class=\"class-from-config\" phx-feedback-for=\"user_name\">is already taken</span>"
    end
  end

  test "prop class overrides config", %{changeset: changeset} do
    using_config ErrorTag, default_class: "class-from-config" do
      assigns = %{changeset: changeset}

      html =
        render_surface do
          ~H"""
          <Form for={{@changeset}} opts={{ as: :user }}>
            <Field name={{ :name }}>
              <ErrorTag class="class-from-prop" />
            </Field>
          </Form>
          """
        end

      assert html =~
               "<span class=\"class-from-prop\" phx-feedback-for=\"user_name\">is already taken</span>"
    end
  end

  def config_translate_error({_msg, _opts}) do
    "translated by config translator"
  end
end
