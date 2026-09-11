# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_11_141855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "author", null: false
    t.datetime "created_at", null: false
    t.text "serial_number", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.datetime "withdrawn_at"
    t.index ["serial_number"], name: "index_books_on_serial_number", unique: true
    t.check_constraint "serial_number ~ '^[0-9]{6}$'::text", name: "books_serial_number_is_six_digits"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.date "borrowed_on", null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.bigint "reader_id", null: false
    t.date "returned_on"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_loans_on_active_book", unique: true, where: "(returned_on IS NULL)"
    t.index ["book_id"], name: "index_loans_on_book_id"
    t.index ["due_on"], name: "index_loans_on_due_on"
    t.index ["reader_id"], name: "index_loans_on_reader_id"
    t.check_constraint "due_on >= borrowed_on", name: "loans_due_on_is_not_before_borrowed_on"
    t.check_constraint "returned_on IS NULL OR returned_on >= borrowed_on", name: "loans_returned_on_is_not_before_borrowed_on"
  end

  create_table "readers", force: :cascade do |t|
    t.text "card_number", null: false
    t.datetime "created_at", null: false
    t.citext "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["card_number"], name: "index_readers_on_card_number", unique: true
    t.index ["email"], name: "index_readers_on_email", unique: true
    t.check_constraint "card_number ~ '^[0-9]{6}$'::text", name: "readers_card_number_is_six_digits"
  end

  add_foreign_key "loans", "books"
  add_foreign_key "loans", "readers"
end
