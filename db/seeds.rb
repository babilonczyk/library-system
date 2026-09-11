# Sample catalog for development, and what a reviewer sees the first time the
# container boots, since the entrypoint runs db:prepare on an empty database.
#
# Idempotent. Each record is looked up by the identifier that carries its unique
# index, so running this a second time changes nothing rather than failing or
# piling up duplicates.

readers = [
  { name: "Ada Lovelace",      email: "ada.lovelace@example.com",      card_number: "100001" },
  { name: "Grace Hopper",      email: "grace.hopper@example.com",      card_number: "100002" },
  { name: "Alan Turing",       email: "alan.turing@example.com",       card_number: "100003" },
  { name: "Barbara Liskov",    email: "barbara.liskov@example.com",    card_number: "100004" },
  { name: "Donald Knuth",      email: "donald.knuth@example.com",      card_number: "100005" },
  { name: "Margaret Hamilton", email: "margaret.hamilton@example.com", card_number: "100006" },
  { name: "Edsger Dijkstra",   email: "edsger.dijkstra@example.com",   card_number: "100007" },
  { name: "Katherine Johnson", email: "katherine.johnson@example.com", card_number: "100008" }
]

# More than one page at Pagy's default of twenty, so the books index has
# something to paginate.
books = [
  { title: "Dune",                          author: "Frank Herbert",        serial_number: "200001" },
  { title: "Ubik",                          author: "Philip K. Dick",       serial_number: "200002" },
  { title: "Solaris",                       author: "Stanisław Lem",        serial_number: "200003" },
  { title: "The Left Hand of Darkness",     author: "Ursula K. Le Guin",    serial_number: "200004" },
  { title: "Neuromancer",                   author: "William Gibson",       serial_number: "200005" },
  { title: "Foundation",                    author: "Isaac Asimov",         serial_number: "200006" },
  { title: "The Dispossessed",              author: "Ursula K. Le Guin",    serial_number: "200007" },
  { title: "Roadside Picnic",               author: "Arkady Strugatsky",    serial_number: "200008" },
  { title: "Hyperion",                      author: "Dan Simmons",          serial_number: "200009" },
  { title: "Snow Crash",                    author: "Neal Stephenson",      serial_number: "200010" },
  { title: "The Master and Margarita",      author: "Mikhail Bulgakov",     serial_number: "200011" },
  { title: "Crime and Punishment",          author: "Fyodor Dostoevsky",    serial_number: "200012" },
  { title: "One Hundred Years of Solitude", author: "Gabriel García Márquez", serial_number: "200013" },
  { title: "Invisible Cities",              author: "Italo Calvino",        serial_number: "200014" },
  { title: "The Trial",                     author: "Franz Kafka",          serial_number: "200015" },
  { title: "Ferdydurke",                    author: "Witold Gombrowicz",    serial_number: "200016" },
  { title: "The Doll",                      author: "Bolesław Prus",        serial_number: "200017" },
  { title: "Quo Vadis",                     author: "Henryk Sienkiewicz",   serial_number: "200018" },
  { title: "Beloved",                       author: "Toni Morrison",        serial_number: "200019" },
  { title: "Things Fall Apart",             author: "Chinua Achebe",        serial_number: "200020" },
  { title: "The Remains of the Day",        author: "Kazuo Ishiguro",       serial_number: "200021" },
  { title: "Wolf Hall",                     author: "Hilary Mantel",        serial_number: "200022" },
  { title: "A Wizard of Earthsea",          author: "Ursula K. Le Guin",    serial_number: "200023" },
  { title: "The Name of the Rose",          author: "Umberto Eco",          serial_number: "200024" },
  { title: "Blindness",                     author: "José Saramago",        serial_number: "200025" }
]

readers.each do |attributes|
  Reader.find_or_create_by!(card_number: attributes[:card_number]) do |reader|
    reader.assign_attributes(attributes)
  end
end

books.each do |attributes|
  Book.find_or_create_by!(serial_number: attributes[:serial_number]) do |book|
    book.assign_attributes(attributes)
  end
end

# Loans in every state the API can show, so the index filter, the borrowing
# history and the overdue scope all have something real to work on.
#
# Idempotent by book rather than by date: a book that already has loans is left
# alone. Loans carry no natural unique key, and the dates below are relative to
# today, so keying on them would quietly create a second set on the next day.
borrowings = {
  # out, not yet due
  "200001" => [ { card: "100001", borrowed_days_ago: 5 } ],
  "200002" => [ { card: "100002", borrowed_days_ago: 1 } ],
  # overdue, still out
  "200003" => [ { card: "100003", borrowed_days_ago: 40 } ],
  "200004" => [ { card: "100004", borrowed_days_ago: 75 } ],
  # came back
  "200005" => [ { card: "100005", borrowed_days_ago: 60, returned_days_ago: 50 } ],
  # borrowed, returned, and out again: a book with a history
  "200006" => [ { card: "100006", borrowed_days_ago: 120, returned_days_ago: 100 },
                { card: "100007", borrowed_days_ago: 90,  returned_days_ago: 80 },
                { card: "100008", borrowed_days_ago: 3 } ]
}

borrowings.each do |serial_number, entries|
  book = Book.find_by!(serial_number: serial_number)
  next if book.loans.exists?

  entries.each do |entry|
    borrowed_on = Date.current - entry[:borrowed_days_ago]

    book.loans.create!(reader: Reader.find_by!(card_number: entry[:card]),
                       borrowed_on: borrowed_on,
                       due_on: LoanPolicy.due_on(borrowed_on),
                       returned_on: entry[:returned_days_ago] && Date.current - entry[:returned_days_ago])
  end
end

puts "Seeded #{Reader.count} readers, #{Book.count} books and #{Loan.count} loans " \
     "(#{Loan.open.count} out, #{Loan.overdue.count} overdue, #{Loan.closed.count} returned)."
