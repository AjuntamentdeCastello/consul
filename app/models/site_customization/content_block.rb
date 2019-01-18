class SiteCustomization::ContentBlock < ActiveRecord::Base
  VALID_BLOCKS = %w[top_links footer subnavigation_left subnavigation_right]

  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :name, presence: true, uniqueness: { scope: :locale }, inclusion: { in: VALID_BLOCKS }

  def self.block_for(name, locale)
    locale ||= I18n.default_locale
    find_by(name: name, locale: locale).try(:body)
  end
end

# == Schema Information
#
# Table name: site_customization_content_blocks
#
#  id         :integer          not null, primary key
#  name       :string
#  locale     :string
#  body       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
