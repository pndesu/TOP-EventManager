require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
  
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
end

def create_letter()
    template_letter = File.read('form_letter.erb')
    erb_template = ERB.new template_letter
    
    contents.each do |row|
        id = row[0]
        name = row[:first_name]
        zipcode = clean_zipcode(row[:zipcode])
        legislators = legislators_by_zipcode(zipcode)
        form_letter = erb_template.result(binding)
        save_thank_you_letter(id,form_letter)
    end
end

def check_hour(contents)
    hours = Hash.new(0)
    contents.each do |row|
        time = DateTime.strptime(row[1], '%m/%d/%Y %k:%M').hour
        hours[time] += 1
    end
    puts hours.sort_by{|k,v| -v}.to_h
end

def convert_day(time)
    case time
    when 0
      time = 'Sun'
    when 1
      time = 'Mon'
    when 2
      time = 'Tue'
    when 3
      time = 'Wed'
    when 4
      time = 'Thu'
    when 5
      time = 'Fri'
    else
      time = 'Sat'
    end
    time
end

def check_weekday(contents)
    day = Hash.new(0)
    contents.each do |row|
        time = DateTime.strptime(row[1], '%m/%d/%Y %k:%M').wday
        time = convert_day(time)
        day[time] += 1
    end
    puts day.sort_by{|k,v| -v}.to_h
end

puts 'EventManager initialized.'

contents = CSV.open(
'event_attendees.csv',
headers: true,
header_converters: :symbol
)

check_hour(contents)
check_weekday(contents)
