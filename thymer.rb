require 'icalendar'
require 'haml'
require 'sha1'
require 'open-uri'
require 'openssl'
require 'yaml'
require 'extensions.rb'

# LAME, dirty, etc, gives warning.
# For some reason Google calendar has a bum certificate, and so
# you need the following for your downloader not to give you shit.
# The internets tell me that the version of open-uri that ships with 1.9
# does not have this problem, but I have yet to make the jump from 1.8
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# http://xkcd.com/282/
class Thymer
  def initialize
    @date_list = Hash.new()
    @template = Haml::Engine.new(File.read("template/template.haml"){ |io| io.read })
    @variables = YAML::load(open("config.yaml"))
    parse(@variables[:calendar_uri])
  end

  def invoice(date, end_date = nil)
    start_date = Date.parse(date)
    end_date ||= start_date + 13

    @variables[:date] ||= Time.now.to_english
    @variables[:start_date] = start_date.to_english
    @variables[:end_date] = end_date.to_english
    @variables[:invoice_number] = eval(@variables[:invoice_number]).call
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
	  t.description = ticket.capitalize

	  t.time = days_tickets[ticket]
	  @variables[:total_seconds] = @variables[:total_seconds] + t.time
	  day.tickets << t
	}
      end
    }

    puts "The following dates have been processed:"
    @variables[:days].each { |d| 
      puts d.date.to_english 
    }

    
    if @variables[:discount_unit_rate] != nil then
      @variables[:discount_exists] = true
      
      @variables[:discount_seconds] = @variables[:discount_hours] * 3600
      @variables[:discount_cost] = @variables[:discount_unit_rate] * @variables[:discount_seconds]
      
      @variables[:regular_priced_seconds] = @variables[:total_seconds] - @variables[:discount_seconds]
      puts "discout cost: #{@variables[:discount_cost]/3600}"

      @variables[:total_cost] = @variables[:discount_cost] + (@variables[:regular_priced_seconds] * @variables[:unit_rate])
      puts "total cost: #{ @variables[:total_cost]/3600}"
    else
      
      @variables[:discount_exists] = false
      @variables[:total_cost] = @variables[:total_seconds] * @variables[:unit_rate]
      puts "total cost: #{ @variables[:total_cost]/3600}"
    end


    File.open("output/#{start_date.to_8601}_#{end_date.to_8601}.html", "w"){ |io| io.puts @template.render(Object.new, @variables) }
    puts "Next invoice start date: #{(end_date+1).to_8601}"

  end


  # This is a static method because it gets called in the template; it's a 
  # holdover from before I wrapped this code into a class. Lame, I know. 
  # TODO:
  # I should abstract this into a Module, or just handle it better period.
  def self.render_days(days)
    day_template = Haml::Engine.new(File.read("template/day.haml"){ |io| io.read })
    str = ""
    days.each { |day|
      str = str + day_template.render(Object.new, :day => day)
    }
    return str
  end


  private

  def parse(cal_uri)
    calendar = Icalendar.parse(open(cal_uri)).first

    calendar.events.each { |e| 
      prop = e.properties
      date = prop["dtstart"].to_8601
      task_name = prop["summary"]
      task_duration = prop["dtend"].to_unix - prop["dtstart"].to_unix

      if @date_list[date].nil?
	@date_list[date] = Hash.new(0)
      end

      @date_list[date][task_name] = @date_list[date][task_name] + task_duration
    }
  end

  
end

#invoice("2009-04-30")
#invoice("2009-05-14")
#invoice("2009-05-28")
#invoice("2009-06-11")
#invoice("2009-06-25")
#invoice("2009-07-09")

#Thymer.new.invoice("2009-07-23")
