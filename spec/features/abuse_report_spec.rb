# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports', feature_category: :not_owned do
  let(:another_user) { create(:user) }

  before do
    sign_in(create(:user))
  end

  it 'report abuse' do
    visit user_path(another_user)

    click_link 'Report abuse'

    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'

    expect(page).to have_content 'Thank you for your report'

    visit user_path(another_user)

    expect(page).to have_button("Already reported for abuse")
  end
end
