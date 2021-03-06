require 'rails_helper'

RSpec.describe Legislation::QuestionOption, type: :model do
  let(:legislation_question_option) { build(:legislation_question_option) }

  it "is valid" do
    expect(legislation_question_option).to be_valid
  end
end

# == Schema Information
#
# Table name: legislation_question_options
#
#  id                      :integer          not null, primary key
#  legislation_question_id :integer
#  value                   :string
#  answers_count           :integer          default(0)
#  hidden_at               :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
