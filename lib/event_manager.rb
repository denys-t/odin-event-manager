require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_num(ph_n)
  ph_n = ph_n.to_s.tr('^0-9', '')
  
  if ph_n.length == 10
    ph_n.insert(3, '-').insert(-5, '-')
  elsif ph_n.length == 11 && ph_n[0] == '1'
    ph_n[1..10].insert(3, '-').insert(-5, '-')
  else
    ''
  end
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

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def most_active_period(datetime_hash)
  datetime_hash.max_by { |k, v| v }
end

puts 'Event manager initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

if File.exist?('event_attendees.csv')
  contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
  hour_of_registration = Hash.new(0)
  day_of_registration = Hash.new(0)

  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = clean_phone_num(row[:homephone])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

    datetime_str = row[:regdate]
    datetime = DateTime.strptime(datetime_str, '%m/%d/%y %H:%M')
    hour_of_registration[datetime.hour] += 1
    day_of_registration[datetime.wday] += 1
  end

  puts "The most active time of day is #{most_active_period(hour_of_registration)[0]} hrs"
  puts "The most ative day is #{Date::DAYNAMES[most_active_period(day_of_registration)[0]]}"
end
