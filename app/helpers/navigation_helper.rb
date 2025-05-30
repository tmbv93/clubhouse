module NavigationHelper
  def admin_page?
    request.path.include?("/admin/")
  end

  def member_page?
    request.path.include?("/member/")
  end

  def modal_content(options = {})
    options[:class] ||= "relative py-6 px-8 min-w-[30vw]"
    content_tag :div, options do
      yield
    end
  end

  def modal_link_to(name = nil, options = nil, html_options = nil, &)
    if block_given?
      options = modal_link_options(options)
    else
      html_options = modal_link_options(html_options)
    end

    link_to(name, options, html_options, &)
  end

  def modal_link_options(link_options)
    link_options ||= {}
    link_options[:data] ||= {}
    link_options[:data][:turbo_frame] = :modal_content
    link_options[:data][:action] = "#{link_options[:data][:action]} click->modal#open".strip
    link_options[:data][:controller] = "#{link_options[:data][:controller]} links".strip
    link_options
  end

  def checklist_item(text, complete_when:)
    content_tag :li, class: ("complete" if complete_when) do
      safe_join(
        [
          if complete_when
            svg_tag "icons/mingcute/task_line"
          else
            svg_tag "icons/mingcute/task_2_line"
          end,

          text
        ]
      )
    end
  end

  def drawer(&block)
    render "navigation/drawer", content: capture(&block)
  end
end
