require 'json'
require 'net/http'
require 'pry'
require 'whois'
require 'whois-parser'

class ShWord
  def initialize(sh_word)
    @word = sh_word
  end

  def domain_name
    word.gsub(/sh$/,".sh")
  end

  private

  attr_accessor :word
end

def dictionary_uri
  URI('https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt')
end

def words
  Net::HTTP.get(dictionary_uri).split
end

def sh_words
  words.select { |word| word.match?(/.sh$/) }
end

def sh_domains
  sh_words.map do |word|
    ShWord.new(word).domain_name
  end
end

def available?(record)
  record.to_s.lines.first.chomp == "Domain not found."
end

def available_sh_domains
  client = Whois::Client.new
  sh_domains.select do |sh_domain|
    sleep(3) # Stay below whois rate limit
    begin
      record = client.lookup(sh_domain)
    rescue Whois::ConnectionError, Timeout::Error => error
      puts error.message
      sleep(60) # Let's be polite and wait for a bit
      retry # before retrying
    end

    available?(record)
  end
end

File.open("available_sh_domains.json", "w+") do |f|
  f.write JSON.pretty_generate({updated: Time.now, domains: available_sh_domains})
end
