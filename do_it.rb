require 'rubygems'
require 'icalendar'
require 'haml'
require 'extensions.rb'
require 'sha1'

calendars = Icalendar.parse(File.open('basic.ics'))
cal = calendars.first

@date_list = Hash.new()


cal.events.each { |e| 
  prop = e.properties
  date = prop["dtstart"].to_8601
  task_name = prop["summary"]
  task_duration = prop["dtend"].to_unix - prop["dtstart"].to_unix
  
  if @date_list[date].nil?
    @date_list[date] = Hash.new(0)
  end
    
  @date_list[date][task_name] = @date_list[date][task_name] + task_duration
}

@template = Haml::Engine.new(File.read("template.haml"){ |io| io.read })

@variables = { 
  :name => "Phillip Mendonça-Vieira",
  :contact => "(416) 627-3393 • phillmv@okayfail.com • 42 Dubray Ave, M3K1V5 Toronto, ON",
  :client_name => "The Mark News",
  :client_contact => "192 Spadina Avenue, Suite 507, M5R2C2 Toronto, ON",
  
  # good enough for git, good enough for me ;)
  :invoice_number => lambda { SHA1.new("#{@variables[:name]}-#{@variables[:client_name]}:#{@variables[:start_date]}-#{@variables[:end_date]}").to_s[0..6] }
}

def invoice(date, end_date = nil)
  start_date = Date.parse(date)
  end_date ||= start_date + 13

  @variables[:date] ||= Time.now.to_english
  @variables[:start_date] = start_date.to_english
  @variables[:end_date] = end_date.to_english
  @variables[:invoice_number] = @variables[:invoice_number].call 

  (start_date..end_date).each { |d|
    day = d.to_8601
    if (days_tickets = @date_list[day])
      puts "=> #{day}"
      days_tickets.keys.each { |ticket|
	puts "#{ticket}: #{days_tickets[ticket]/3600.0}"
      }
      puts "\n"
    end
  }
  (end_date + 1).to_8601
  File.open("output/#{start_date.to_8601}_#{end_date.to_8601}.html", "w"){ |io| io.puts @template.render(Object.new, @variables) }

end

invoice("2009-04-30")



