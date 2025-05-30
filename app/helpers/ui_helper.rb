module UiHelper
  def card(**options, &block)
    render "navigation/card", content: capture(&block), options: options
  end

  def badge(text, color: "gray", size: "sm", id: nil)
    render "navigation/badge", text: text, color: color, size: size, id: id
  end

  def sidebar_active_html_class(option_controller)
    option_controller = [ option_controller ] if option_controller.is_a?(String)

    "active" if option_controller.include?(controller_name)
  end

  def dropdown_menu(**options, &block)
    render "navigation/dropdown_menu", options: options, content: capture(&block)
  end

  def dropdown_menu_content(**options, &block)
    render "navigation/dropdown_menu_content", options: options, content: capture(&block)
  end

  def dropdown_menu_links(**options, &block)
    render "navigation/dropdown_menu_links", options: options, content: capture(&block)
  end

  def breadcrumbs(**block)
    content_for :breadcrumbs do
      yield block
    end
  end

  def breadcrumb(title, url = nil, options = {})
    content_tag :li, class: "breadcrumb" do
      if url.present?
        link_to title, url, { class: "breadcrumb-link" }.merge(options)
      else
        title
      end
    end
  end

  def tooltip(tooltip_text, display_if: true, **options, &block)
    if display_if
      content_tag :div,
                  capture(&block),
                  class: "tooltip #{options[:class]}",
                  data: { tooltip: tooltip_text }
    else
      capture(&block)
    end
  end

  # Call blur_foreground_classes on the element inside the element with blur_background_styles
  def blur_foreground_classes
    "backdrop-blur-3xl bg-white/60"
  end

  def blur_background_styles(image, fallback_image: nil)
    blur_image = (image.variant(:thumbnail) if image.attached?) || (fallback_image.variant(:thumbnail) if fallback_image.attached?)
    return unless blur_image

    "background-image: url(#{ rails_storage_proxy_path(blur_image)}); background-size: 150%;"
  end
end
