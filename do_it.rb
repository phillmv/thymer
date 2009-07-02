require 'icalendar'

calendars = Icalendar.parse(File.open('basic.ics'))

cal = calendars.first

@date_list = Hash.new()

class DateTime
  DATE_STR = '%Y-%m-%d'
  def to_8601
    self.strftime(DATE_STR)
  end
  def to_unix
    self.strftime('%s').to_i
  end
end

class Date
  DATE_STR = '%Y-%m-%d'
  def to_8601
    self.strftime(DATE_STR)
  end
  def to_unix
    self.strftime('%s').to_i
  end
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

def invoice(date)
  start_date = Date.parse(date)
  end_date = start_date + 13

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
end
	
