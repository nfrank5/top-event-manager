require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin 
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.gsub(/\D/, '')
  if phone_number.length < 10 || phone_number.length > 11
    return 'Bad number'
  elsif phone_number.length == 11
    if phone_number[0] == '1'
      return phone_number[1..]
    elsif phone_number[0] != '1'
      return 'Bad number'
    end
  end

  phone_number
end

def top_registration_hour(dates)
  hours = dates.map do |date|
    hour = Time.strptime(date, "%m/%e/%y %k:%M")
    hour.strftime("%k")
  end

  hours_count = Hash.new(0)

  hours.each do |h|
    hours_count[h] += 1
  end

  p hours_count.sort_by(&:last)
end

def top_registration_day(dates)
  
  days = dates.map do |date|
    day = Date.strptime(date, "%m/%e/%y %k:%M")
    day.strftime("%A")
  end

  day_count = Hash.new(0)

  days.each do |d|
    day_count[d] += 1
  end
  
  p day_count.sort_by(&:last)
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers:true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_dates = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  registration_dates.push(row[:regdate])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
  puts phone_number
end

top_registration_hour(registration_dates)
top_registration_day(registration_dates)