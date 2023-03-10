# frozen_string_literal: true

class ValidateNotNullContraintOnIssuesWorkItemTypeId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issues, :work_item_type_id, validate: true
  end

  def down
    remove_not_null_constraint :issues, :work_item_type_id
  end
end
