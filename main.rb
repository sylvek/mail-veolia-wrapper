require 'net/pop'
require 'sqlite3'

db = SQLite3::Database.new ENV['DATABASE']||"water.db"
db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS data(id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER, name TEXT, unit TEXT, value REAL);
    CREATE INDEX IF NOT EXISTS indx_data on data (ts);
    PRAGMA main.busy_timeout=5000;
    PRAGMA main.journal_mode=WAL;
SQL

Net::POP3.start(
    ENV['POP_HOST']||"pop.free.fr", 
    ENV['POP_PORT']||110, 
    ENV['EMAIL'], 
    ENV['PASSWORD']) do |pop|
    if pop.mails.empty?
        puts 'No mail.'
    else
        pop.each_mail do |popmail|
            mail = popmail.pop
            mail.match /Le (\d{1,2})\/(\d{1,2})\/(\d{4})/ do |matches|
                day     = matches.captures[0]
                month   = matches.captures[1]
                year    = matches.captures[2]
                epoch   = Time.new(year, month, day).to_i
                mail.match /consommation de (\d{1,4}) litres./ do |matches|
                    value = matches.captures[0]
                    db.execute(
                        "INSERT INTO data (ts, name, unit, value) VALUES (?, ?, ?, ?)",
                        [epoch, "daily_water_consumption", "liter", value]
                    )
                    puts "#{day}-#{month}-#{year} - consumption was #{value} liters"
                end
                popmail.delete if ENV['AFTER_PROCESS'] == 'REMOVE'
            end
        end
    end
end