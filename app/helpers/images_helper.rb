module ImagesHelper
  def svg_tag(icon_name, options = {})
    cache_key = "svg-#{icon_name}-#{options.hash}"
    Rails.cache.fetch(cache_key) do
      file = Rails.root.join("app", "assets", "images", icon_name).read
      doc = Nokogiri::HTML::DocumentFragment.parse file
      svg = doc.at_css "svg"
      options.each { |attr, value| svg[attr.to_s] = value }
      doc.to_html.html_safe
    end
  end
end
