# frozen_string_literal: true

class AddIndexAuthorIdCreatedAtOnMergeRequests < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_merge_requests_on_author_id_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, %i[author_id created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
