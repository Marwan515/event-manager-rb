require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(numb)
  if numb.length == 10
    numb
  elsif numb.length == 11 && numb[0] == "1"
    numb[1..10]
  else
    "wrong Number"
  end  
end  

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
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

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

use_list = []
dat_list = []
days_of_week = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = row[:homephone]
  dates = row[:regdate]

  rdate = DateTime.strptime(dates, "%m/%d/%y %H:%M")
  use_list.push(rdate.hour)
  dat_list.push(rdate.wday)

  phone_number = clean_phone(phone_number)

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

 # save_thank_you_letter(id, form_letter)
end

puts "Most Valuable time to Run Add is #{use_list.max_by {|i| use_list.count(i)}}"
puts "most users Registered on #{days_of_week.max_by {|i| dat_list.count(i)}}"