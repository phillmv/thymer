class Day
  attr_writer :tickets, :date
  attr_accessor :tickets, :date
  def initialize
    @tickets = []
  end
end

class Ticket
  attr_writer :description, :time, :hours
  attr_reader :description, :time, :hours
end

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
  def to_english
    self.strftime "%B %d, %Y"
  end
end

class Time
  def to_english
    self.strftime "%B %d, %Y"
  end
end
