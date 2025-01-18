defmodule RostrumWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: RostrumWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :help, :string, default: ""

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <div class="text-sm text-zinc-500">{@help}</div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <div class="text-sm text-zinc-500">{@help}</div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <div class="text-sm text-zinc-500">{@help}</div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <div class="text-sm text-zinc-500">{@help}</div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-xl font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a subheader with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def subheader(assigns) do
    ~H"""
    <div class={[@actions != [] && "flex items-center justify-between gap-6", "mt-12", @class]}>
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">
        {render_slot(@inner_block)}
      </h2>
      <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
        {render_slot(@subtitle)}
      </p>
      <div class="flex-none">{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc """
  Renders a warning callout.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def warning(assigns) do
    ~H"""
    <div class={[
      "text-sm pretty-text my-4 p-5 bg-red-100 border-l-4 border-red-600 rounded text-slate-600",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a info callout.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def info(assigns) do
    ~H"""
    <div class={[
      "text-sm pretty-text my-4 p-5 bg-cyan-100 border-l-4 border-cyan-600 rounded text-slate-600",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="px-4 sm:overflow-visible sm:px-0">
      <table class="w-full mt-11">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  attr :event, :any, required: true

  def render_event(assigns) do
    type_to_name = %{
      "opening-hymn" => "Opening Hymn",
      "closing-hymn" => "Closing Hymn",
      "sacrament-hymn" => "Sacrament Hymn",
      "rest-hymn" => "Rest Hymn",
      "hymn" => "Hymn",
      "musical-number" => "Musical number",
      "speaker" => "Speaker",
      "opening-prayer" => "Invocation",
      "closing-prayer" => "Benediction",
      "sacrament" => "Administration of the Sacrament",
      "baby-blessing" => "Baby blessing",
      "testimonies" => "Testimonies from the Congregation",
      "announcements" => "Announcements",
      "ward-business" => "Ward Business",
      "stake-business" => "Stake Business",
      "ward-stake-business" => "Ward & Stake Business",
      "custom" => "Custom"
    }

    assigns =
      assigns
      |> assign(:name, type_to_name[assigns.event["type"]])
      |> assign(:verses, format_verses(assigns.event["verses"]))

    assigns =
      if assigns.event["type"] in [
           "opening-hymn",
           "closing-hymn",
           "rest-hymn",
           "sacrament-hymn",
           "hymn"
         ] do
        data = Rostrum.Meetings.Event.hymn_name(assigns.event["number"])
        if is_map(data) do
          assign(assigns, :hymn_data, data)
        else
          assign(assigns, :hymn_data, %{name: assigns.event["name"], url: "", pdf: ""})
        end
      else
        assigns
      end

    ~H"""
    <div class="program-event">
      <%= if @event["type"] in ["opening-prayer", "closing-prayer", "speaker"] do %>
        <div class="prayer">
          <h5>{@event["term"] || @name}</h5>
          {@event["name"]}
        </div>
      <% end %>

      <%= if @event["type"] in ["opening-hymn", "closing-hymn", "rest-hymn", "sacrament-hymn", "hymn"] do %>
        <div class="hymn">
          <h5>{@event["term"] || @name}</h5>
          <span class="hymn-number">{@event["number"]}</span><span class="hymn-name">{@hymn_data.name}</span>
          <span :if={@verses} class="hymn-verses">{@verses}</span>
          <span class="hymn-links">
            <span :if={@hymn_data.url != ""} class="hymn-link">
              <a href={@hymn_data.url}>open music</a>
            </span>
            <span :if={@hymn_data.url != "" && @hymn_data.pdf != ""} class="hymn-link-sep">◊</span>
            <span :if={@hymn_data.pdf != ""} class="hymn-link">
              <a href={@hymn_data.pdf}>open as PDF</a>
            </span>
          </span>
        </div>
      <% end %>

      <%= if @event["type"] in ["musical-number"] do %>
        {@event["name"]}
        {@event["Performer"]}
      <% end %>

      <%= if @event["type"] in ["sacrament", "baby-blessing", "announcements", "testimonies", "ward-business", "stake-business", "ward-stake-business"] do %>
        <h4>{@name}</h4>
      <% end %>

      <%= if @event["type"] in ["custom"] do %>
        <h4>{@event["name"]}</h4>
      <% end %>
    </div>
    """
  end

  attr :announcement, :any, required: true

  def render_announcement(assigns) do
    import Phoenix.HTML

    rendered =
      case Earmark.as_html(assigns.announcement.description) do
        {:ok, html, _} ->
          html

        {:error, html, _e} ->
          html
      end

    assigns =
      assigns
      |> assign(:rendered, rendered)

    ~H"""
    <div class="announcement">
      <div class="announcement-header">{@announcement.title}</div>
      <div class="announcement-description">
        {raw(@rendered)}
      </div>
    </div>
    """
  end

  attr :event, :any, required: true

  def render_calendar_event(assigns) do
    import Phoenix.HTML

    rendered =
      case Earmark.as_html(assigns.event.description) do
        {:ok, html, _} ->
          html

        {:error, html, _e} ->
          html
      end

    desc = assigns.event.time_description
    dt = assigns.event.event_date &&
      assigns.event.event_date
      |> DateTime.shift_zone!(assigns.unit.timezone)

    td_desc =
      if is_binary(desc) && desc != "" do
        desc
      else
        if dt,
          do: Timex.format!(dt, "%A, %B %d, %Y at %l:%M %p", :strftime),
          else: ""
      end

    ical_dat =
      if dt do
        ical_string(
          "rostrumevent#{assigns.event.id}",
          ical_date_fmt(dt),
          ical_date_fmt(DateTime.add(dt, 1, :hour)),
          assigns.event.title,
          assigns.event.description
        )
        |> Base.encode64()
      end

    assigns =
      assigns
      |> assign(:td_desc, td_desc)
      |> assign(:rendered, rendered)
      |> assign(:ical_dat, ical_dat)

    ~H"""
    <div class="calendar-event">
      <div class="event-metadata">
        <span class="event-title">{@event.title}</span>
        <span class="event-datetime">{@td_desc}</span>
        <a :if={@ical_dat} class="event-ical-link" href={"data:text/calendar;base64,#{@ical_dat}"} download="event.ics">Add to calendar</a>
      </div>
      <div class="event-description">
        {raw(@rendered)}
      </div>
    </div>
    """
  end

  defp ical_date_fmt(date) do
    date
    |> to_string()
    |> String.replace(~r/-|:/, "")
    |> String.replace(" ", "T")
  end

  defp ical_string(id, start_ts, end_ts, title, description) do
    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//hacksw/handcal//NONSGML v1.0//EN
    BEGIN:VTIMEZONE
    TZID:America/Denver
    BEGIN:DAYLIGHT
    TZOFFSETFROM:-0700
    DTSTART:20070311T020000
    RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
    TZNAME:MDT
    TZOFFSETTO:-0600
    END:DAYLIGHT
    BEGIN:STANDARD
    TZOFFSETFROM:-0600
    DTSTART:20071104T020000
    RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
    TZNAME:MST
    TZOFFSETTO:-0700
    END:STANDARD
    END:VTIMEZONE
    BEGIN:VEVENT
    DTEND;TZID=America/Denver:20241227T190000
    UID:#{id}
    DTSTART;TZID=America/Denver:#{start_ts}
    DTEND;TZID=America/Denver:#{end_ts}
    SUMMARY:#{title}
    DESCRIPTION:#{description}
    END:VEVENT
    END:VCALENDAR
    """
  end

  defp format_verses(""), do: nil
  defp format_verses(nil), do: nil

  defp format_verses(verse_string) do
    digits =
      Regex.scan(~r/\d+/, verse_string)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)

    case digits do
      [] -> verse_string
      [v] -> "Verse #{v}"
      [v1, v2] -> "Verses #{v1} and #{v2}"
      vs -> "Verses #{Enum.join(Enum.take(vs, length(vs) - 1), ", ")}, and #{List.last(vs)}"
    end
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mb-2">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  attr :datetime, DateTime, required: true
  attr :tz, :string, required: true
  attr :format, :any, default: ""
  def format_datetime(assigns) do
    import Phoenix.HTML

    fmt =
      case assigns.format do
        "short" -> "%d&nbsp;%b&nbsp;%Y %H:%M"
        _ -> "%A, %B %d, %Y at %I:%M %p"
      end

    dtz = DateTime.shift_zone!(assigns.datetime, assigns.tz)

    with {:ok, fmtd} <- Timex.format(dtz, fmt, :strftime) do
      assigns = assign(assigns, :fmtd, fmtd)

      ~H"""
      {raw(@fmtd)}
      """
    else
      _ ->
        ~H"""
        {@date}
        """
    end
  end

  attr :date, :any, required: true
  attr :format, :any, default: ""
  def format_date(assigns) do
    import Phoenix.HTML

    fmt =
      case assigns.format do
        "short" -> "%d&nbsp;%b&nbsp;%Y"
        _ -> "%A, %B %d, %Y"
      end

    with {:ok, fmtd} <- Timex.format(assigns.date, fmt, :strftime) do
      assigns = assign(assigns, :fmtd, fmtd)

      ~H"""
      {raw(@fmtd)}
      """
    else
      _ ->
        ~H"""
        {@date}
        """
    end
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(RostrumWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(RostrumWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
