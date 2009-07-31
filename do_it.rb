require 'rubygems'
require 'icalendar'
require 'haml'
require 'extensions.rb'
require 'config.rb'
require 'sha1'

calendars = Icalendar.parse(File.open('basic.ics.4'))
cal = calendars.first

@date_list = Hash.new()
@template = Haml::Engine.new(File.read("template.haml"){ |io| io.read })

class Day
  attr_writer :tickets, :date
  attr_accessor :tickets, :date
  def initialize
    @tickets = []
  end
end

class Ticket
  attr_writer :description, :time
  attr_reader :description, :time
end

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

def invoice(date, end_date = nil)
  start_date = Date.parse(date)
  end_date ||= start_date + 13

  @variables[:date] ||= Time.now.to_english
  @variables[:start_date] = start_date.to_english
  @variables[:end_date] = end_date.to_english
  @variables[:invoice_number] = @variables[:invoice_number].call
  @variables[:total_seconds] = 0
  @variables[:days] = []

  (start_date..end_date).each { |d|
   
    this_day = d.to_8601
    if (days_tickets = @date_list[this_day])
      day = Day.new
      day.date = d
      @variables[:days] << day

      days_tickets.keys.each { |ticket|
	
	t = Ticket.new
	t.description = ticket

	t.time = days_tickets[ticket]
	@variables[:total_seconds] = @variables[:total_seconds] + t.time
	day.tickets << t
      }
    end
  }

  @variables[:days].each { |d| puts d.date.to_english }
  
  @variables[:regular_priced_seconds] = @variables[:total_seconds] - @variables[:discount_seconds]
  @variables[:discount_cost] = @variables[:discount_unit_rate] * @variables[:discount_seconds]
  puts "discout cost: #{@variables[:discount_cost]/3600}"
  @variables[:total_cost] = @variables[:discount_cost] + (@variables[:regular_priced_seconds] * @variables[:unit_rate])
  puts "total cost: #{ @variables[:total_cost]/3600}"


  File.open("output/#{start_date.to_8601}_#{end_date.to_8601}.html", "w"){ |io| io.puts @template.render(Object.new, @variables) }
  puts (end_date+1).to_8601

end

def render_days(days)
  day_template = Haml::Engine.new(File.read("day.haml"){ |io| io.read })
  str = ""
  days.each { |day|
    str = str + day_template.render(Object.new, :day => day)
  }
  return str
end

#invoice("2009-04-30")
invoice("2009-05-14")

