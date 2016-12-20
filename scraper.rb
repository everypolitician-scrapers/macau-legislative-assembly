#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  h4 = noko.xpath('//h4[span[contains(.,"第五屆立法會議員名單")]]')
  dls = h4.xpath('following-sibling::dl | following-sibling::h2').slice_before { |e| e.name == 'h2' }.first
  dls.each do |dl|
    type = dl.css('dt')
    dl.css('dd').each do |dd|
      source = dd.css('a[href*="www.al.gov.mo"]/@href').text
      data = scrape_person(source).merge({ 
        term: 10,
        wikiname__zh: dd.xpath('.//a[not(@class="new")]/@title').text 
      })
      # puts data
      ScraperWiki.save_sqlite([:id, :term], data)
    end
  end
end

def scrape_person(url)
  noko = noko_for(url)
  name_zh_field = '中文姓名'
  name_en_field = '葡文姓名'

  data = {
    id: File.basename(url, '.*').gsub('%20','_'),
    name__zh: noko.xpath('//table//tr[contains(.,"%s")]/td//span' % name_zh_field).text,
    name__en: noko.xpath('//table//tr[contains(.,"%s")]/td[2]' % name_en_field).text.tidy,
    image: noko.xpath('//table//tr[contains(.,"中文姓名")]//img/@src').text,
    term: 9,
    source: url,
  }
  # binding.pry if data[:name__en].to_s.empty? || data[:name__zh].to_s.empty?
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  # puts data
  data
end

scrape_list('https://zh.wikipedia.org/wiki/%E6%BE%B3%E9%96%80%E7%89%B9%E5%88%A5%E8%A1%8C%E6%94%BF%E5%8D%80%E7%AB%8B%E6%B3%95%E6%9C%83')
