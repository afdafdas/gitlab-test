# frozen_string_literal: true

RSpec.shared_examples 'update work item description widget' do
  it 'updates the description widget' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      work_item.reload
    end.to change { work_item.description }.from(nil).to(new_description)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['workItem']['widgets']).to include(
      {
        'description' => new_description,
        'type' => 'DESCRIPTION'
      }
    )
  end

  context 'when the updated work item is not valid' do
    it 'returns validation errors without the work item' do
      errors = ActiveModel::Errors.new(work_item).tap { |e| e.add(:description, 'error message') }

      allow_next_found_instance_of(::WorkItem) do |instance|
        allow(instance).to receive(:valid?).and_return(false)
        allow(instance).to receive(:errors).and_return(errors)
      end

      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['workItem']).to be_nil
      expect(mutation_response['errors']).to match_array(['Description error message'])
    end
  end
end
