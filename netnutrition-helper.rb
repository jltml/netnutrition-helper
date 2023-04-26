require "watir"
require "webdrivers"
require "tty-progressbar"
require "tty-prompt"
require "paint"

today = Time.now.strftime("%A")
time_now = Time.now.strftime("%H:%M")
current_meal = ""
day_offset = 0

if today == "Monday" || today == "Tuesday" || today == "Wednesday" || today == "Thursday"
  if time_now < "07:00"
    puts "The dining halls are currently closed, but the next meal is breakfast."
    current_meal = "Breakfast"
  elsif time_now >= "07:00" && time_now < "11:00"
    current_meal = "Breakfast"
  elsif time_now >= "11:00" && time_now < "14:00"
    current_meal = "Lunch"
  elsif time_now >= "14:00" && time_now < "16:30"
    puts "The dining halls are currently closed, but the next meal is dinner."
    current_meal = "Dinner"
  elsif time_now >= "16:30" && time_now < "21:00"
    current_meal = "Dinner"
  elsif time_now >= "21:00"
    puts "The dining halls are currently closed, but the next meal is breakfast tomorrow."
    current_meal = "Breakfast"
    day_offset = 1 unless today == "Monday"
  else
    abort "Something went wrong with time comparison :("
  end
elsif today == "Friday"
  if time_now < "07:00"
    puts "The dining halls are currently closed, but the next meal is breakfast."
    current_meal = "Breakfast"
  elsif time_now >= "07:00" && time_now < "11:00"
    current_meal = "Breakfast"
  elsif time_now >= "11:00" && time_now < "14:00"
    current_meal = "Lunch"
  elsif time_now >= "14:00" && time_now < "16:30"
    puts "The dining halls are currently closed, but the next meal is dinner."
    current_meal = "Dinner"
  elsif time_now >= "16:30" && time_now < "20:00"
    current_meal = "Dinner"
  elsif time_now >= "20:00"
    puts "The dining halls are currently closed, but the next meal is brunch tomorrow."
    puts "This comparison might not work… but let's see what it does anyway?"
    current_meal = "Brunch"
    day_offset = 1
  else
    abort "Something went wrong with time comparison :("
  end
elsif today == "Saturday"
  if time_now < "09:00"
    puts "The dining halls are currently closed, but the next meal is breakfast."
    current_meal = "Breakfast"
  elsif time_now >= "09:00" && time_now < "14:00"
    current_meal = "Brunch"
  elsif time_now >= "14:00" && time_now < "16:30"
    puts "The dining halls are currently closed, but the next meal is dinner."
    current_meal = "Dinner"
  elsif time_now >= "16:30" && time_now < "20:00"
    current_meal = "Dinner"
  elsif time_now >= "20:00"
    puts "The dining halls are currently closed, but the next meal is brunch tomorrow."
    current_meal = "Brunch"
    day_offset = 1
  else
    abort "Something went wrong with time comparison :("
  end
elsif today == "Sunday"
  if time_now < "09:00"
    puts "The dining halls are currently closed, but the next meal is breakfast."
    current_meal = "Breakfast"
  elsif time_now >= "09:00" && time_now < "14:00"
    current_meal = "Brunch"
  elsif time_now >= "14:00" && time_now < "16:30"
    puts "The dining halls are currently closed, but the next meal is dinner."
    current_meal = "Dinner"
  elsif time_now >= "16:30" && time_now < "20:00"
    current_meal = "Dinner"
  elsif time_now >= "20:00"
    puts "The dining halls are currently closed, but the next meal is breakfast tomorrow."
    puts "This comparison might not work… but let's see what it does anyway?"
    current_meal = "Breakfast"
    day_offset = 1
  else
    abort "Something went wrong with time comparison :("
  end
end

hall = ARGV.first if ARGV.first
# current_meal = "Lunch"
unless hall
  prompt = TTY::Prompt.new
  hall = prompt.select("Please choose a dining hall:", %w[North South])
  # hall = "North"
end

browser = Watir::Browser.new :chrome, headless: true

browser.goto "http://nutrition.nd.edu/NetNutrition"

sleep 1

browser.link(text: "#{hall} Dining Hall").click
sleep 0.1
browser.link(text: "#{hall} Daily Menus").click
sleep 0.1
browser.links(text: current_meal)[0 + day_offset].click
sleep 1

bar = TTY::ProgressBar.new("parsing previous menu… :bar :current/:total :percent @ :rate/s; :elapsed ← :eta", total: browser.tds.count, bar_format: :box, clear: true)

yesterdays_items = {}
current_category = ""
browser.tds.each do |td|
  if td.class_name == "cbo_nn_itemGroupRow"
    current_category = td.text
    yesterdays_items[current_category] = []
  elsif td.class_name == "cbo_nn_itemHover"
    yesterdays_items[current_category] << td.text
  end
  bar.advance
end

bar.finish

browser.button(id: "btn_Back1").click
# sleep 0.25
browser.links(text: current_meal)[1 + day_offset].click
sleep 1

bar = TTY::ProgressBar.new("parsing current menu… :bar :current/:total :percent @ :rate/s; :elapsed ← :eta", total: browser.tds.count, bar_format: :box, clear: true)

todays_items = {}
current_category = ""
browser.tds.each do |td|
  if td.class_name == "cbo_nn_itemGroupRow"
    current_category = td.text
    todays_items[current_category] = []
  elsif td.class_name == "cbo_nn_itemHover"
    todays_items[current_category] << td.text
  end
  bar.advance
end

bar.finish

browser.close

# puts todays_items
# puts yesterdays_items

puts Paint["~~~ Different #{current_meal.downcase} items at #{hall} Dining Hall: ~~~", :faint]
todays_items.each do |key, items|
  if yesterdays_items.key? key
    new_items = yesterdays_items[key] - items
    unless new_items == []
      puts Paint[key.delete("*"), :bold]
      new_items.each do |item|
        puts "    #{item}"
      end
    end
  else
    puts Paint[key.delete("*"), :bold]
    items.each do |item|
      puts "    #{item}"
    end
  end
end
puts Paint["as of #{Time.now.strftime("%a %b %d %l:%M %p")}", :faint, :italic]
