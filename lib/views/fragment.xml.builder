xml.instruct!
xml.urlset :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9', 'xmlns:rs' => 'http://www.openarchives.org/rs/terms/' do
  xml.tag!('rs:md', { :capability => 'resourcelist', :at => Time.now.iso8601 })
  store.entries.each do |entry|
    xml.url do
      xml.loc entry[:url] ? entry[:url] : polymorphic_url(entry[:object], entry[:params])
      entry[:search].each do |type, value|
        next if !value || value.blank?
        xml.tag!(SEARCH_ATTRIBUTES[type], value.to_s)
      end
      xml.tag!('rs:md', { :hash => entry[:hash] })
    end
  end
end
