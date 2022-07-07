require 'csv'
require 'google/apis/civicinfo_v2'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislators_names = legislators.map(&:name)
    legislators_names.join(', ')
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'Event manager initialized!'

if File.exist?('event_attendees.csv')
  contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])

    legislators_string = legislators_by_zipcode(zipcode)

    puts "#{name} #{zipcode} #{legislators_string}"
  end
end