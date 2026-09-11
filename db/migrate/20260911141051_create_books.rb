class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      # Same shape as a reader's card number: an identifier, not a number.
      t.text :serial_number, null: false
      # Soft delete. A withdrawn book leaves the catalog but keeps its
      # borrowing history, which a hard delete would take with it.
      t.datetime :withdrawn_at

      t.timestamps
    end

    # Deliberately not partial. A withdrawn book keeps its serial number, so a
    # physical copy's history can never be confused with a later copy's.
    add_index :books, :serial_number, unique: true

    add_check_constraint :books,
                         "serial_number ~ '^[0-9]{6}$'",
                         name: "books_serial_number_is_six_digits"
  end
end
