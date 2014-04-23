xml.instruct!
xml.sitemapindex :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                 'xmlns:rs' => 'http://www.openarchives.org/rs/terms/'
 xml.tag!('rs:md', { capability: 'resourcelist', at: Time.now.iso8601 })
 fragments.each_with_index do |fragment, i|
    xml.sitemap do
      xml.loc file_url("resourcelist-part#{i + 1}.xml")
    end
  end
end
