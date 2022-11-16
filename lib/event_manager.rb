require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'



def clean_zipcode(zip)
  zipcode = zip.to_s
  if zipcode == ""
    zipcode = "00000"
  elsif zipcode.length > 5
    zipcode = zipcode[0..4]
  end
  while zipcode.length < 5
    zipcode.prepend("0")
  end
  zipcode
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
    'You can find your representitives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)


def valid_phone_number(phone)
  
  phone_just_numbers = phone.gsub(/[\.()\-\s+]/, "")

  if phone_just_numbers.length < 10 || phone_just_numbers.length > 11
    phone_just_numbers = "0000000000"
  elsif phone_just_numbers.length == 11 && phone_just_numbers[0, 1] == "1"
    phone_just_numbers.slice!(0)
  end
  puts phone_just_numbers
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


sign_up_hours = []
sign_up_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id,form_letter)

  valid_phone_number(row[:homephone])


  # count the hours that people signed up add to the 'sign_up_hours' hash
  date = row[:regdate]
  date_fixed = DateTime.strptime(date, '%m/%d/%y %H:%M')
  sign_up_hours << date_fixed.hour
  
  sign_up_days << date_fixed.wday
  


end

sign_up_hours_sorted = sign_up_hours.tally.sort_by {|k, v| [-v, k]}
# p sign_up_hours_sorted
sign_up_hours_sorted.each {|k, v| puts "In hour \"#{k}\" there were #{v} sign ups."}



sign_up_days_sorted = sign_up_days.tally.sort_by {|k,v| [-v, k]}
# p sign_up_days_sorted
sign_up_days_sorted.each {|k, v| puts "On day \"#{k}\" there was #{v} sign ups."}


