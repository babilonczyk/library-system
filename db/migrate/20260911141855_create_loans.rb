class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true
      t.references :reader, null: false, foreign_key: true

      # Dates, not timestamps. A thirty day loan is a calendar concept, and the
      # reminder sweep compares dates.
      t.date :borrowed_on, null: false
      # Stored at borrow time rather than derived, because the loan period is
      # policy and policy changes.
      t.date :due_on, null: false
      t.date :returned_on

      t.timestamps
    end

    # One active loan per book, guaranteed by the database rather than by every
    # code path remembering to check. A concurrent borrow surfaces as a
    # uniqueness violation, so nothing has to take a lock.
    add_index :loans, :book_id,
              unique: true,
              where: "returned_on IS NULL",
              name: "index_loans_on_active_book"

    # The reminder sweep selects open loans by due date.
    add_index :loans, :due_on

    add_check_constraint :loans,
                         "due_on >= borrowed_on",
                         name: "loans_due_on_is_not_before_borrowed_on"
    add_check_constraint :loans,
                         "returned_on IS NULL OR returned_on >= borrowed_on",
                         name: "loans_returned_on_is_not_before_borrowed_on"
  end
end
