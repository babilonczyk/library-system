class CreateReaders < ActiveRecord::Migration[8.1]
  def change
    # citext makes email uniqueness case-insensitive in the database, rather
    # than depending on every write path remembering to downcase.
    enable_extension "citext"

    create_table :readers do |t|
      t.string :name, null: false
      t.citext :email, null: false
      # An identifier, not a number: leading zeros are significant, and nothing
      # ever does arithmetic on it.
      t.text :card_number, null: false

      t.timestamps
    end

    add_index :readers, :email, unique: true
    add_index :readers, :card_number, unique: true

    add_check_constraint :readers,
                         "card_number ~ '^[0-9]{6}$'",
                         name: "readers_card_number_is_six_digits"
  end
end
