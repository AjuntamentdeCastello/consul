class Legislation::Process < ActiveRecord::Base
  include ActsAsParanoidAliases
  include Taggable
  include Milestoneable
  include Documentable
  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes,
               accepted_content_types: [ "application/pdf" ]

  acts_as_paranoid column: :hidden_at
  acts_as_taggable_on :customs

  translates :title,              touch: true
  translates :summary,            touch: true
  translates :description,        touch: true
  translates :additional_info,    touch: true
  translates :milestones_summary, touch: true
  translates :homepage,           touch: true
  include Globalizable

  PHASES_AND_PUBLICATIONS = %i[draft_phase debate_phase allegations_phase proposals_phase
                               draft_publication result_publication].freeze

  has_many :draft_versions, -> { order(:id) }, class_name: 'Legislation::DraftVersion',
                                               foreign_key: 'legislation_process_id',
                                               dependent: :destroy
  has_one :final_draft_version, -> { where final_version: true, status: 'published' },
                                           class_name: 'Legislation::DraftVersion',
                                           foreign_key: 'legislation_process_id'
  has_many :questions, -> { order(:id) }, class_name: 'Legislation::Question',
                                          foreign_key: 'legislation_process_id', dependent: :destroy
  has_many :proposals, -> { order(:id) }, class_name: 'Legislation::Proposal',
                                          foreign_key: 'legislation_process_id', dependent: :destroy

  validates_translation :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :debate_start_date, presence: true, if: :debate_end_date?
  validates :debate_end_date, presence: true, if: :debate_start_date?
  validates :draft_start_date, presence: true, if: :draft_end_date?
  validates :draft_end_date, presence: true, if: :draft_start_date?
  validates :allegations_start_date, presence: true, if: :allegations_end_date?
  validates :allegations_end_date, presence: true, if: :allegations_start_date?
  validates :proposals_phase_end_date, presence: true, if: :proposals_phase_start_date?
  validate :valid_date_ranges

  scope :open, -> { where("start_date <= ? and end_date >= ?", Date.current, Date.current)
                    .order('id DESC') }
  scope :next, -> { where("start_date > ?", Date.current).order('id DESC') }
  scope :past, -> { where("end_date < ?", Date.current).order('id DESC') }

  scope :published, -> { where(published: true) }
  scope :not_in_draft, -> { where("draft_phase_enabled = false or (draft_start_date IS NOT NULL and
                                   draft_end_date IS NOT NULL and (draft_start_date > ? or
                                   draft_end_date < ?))", Date.current, Date.current) }

  def draft_phase
    Legislation::Process::Phase.new(draft_start_date, draft_end_date, draft_phase_enabled)
  end

  def debate_phase
    Legislation::Process::Phase.new(debate_start_date, debate_end_date, debate_phase_enabled)
  end

  def allegations_phase
    Legislation::Process::Phase.new(allegations_start_date,
                                    allegations_end_date, allegations_phase_enabled)
  end

  def proposals_phase
    Legislation::Process::Phase.new(proposals_phase_start_date,
                                    proposals_phase_end_date, proposals_phase_enabled)
  end

  def draft_publication
    Legislation::Process::Publication.new(draft_publication_date, draft_publication_enabled)
  end

  def result_publication
    Legislation::Process::Publication.new(result_publication_date, result_publication_enabled)
  end

  def enabled_phases?
    PHASES_AND_PUBLICATIONS.any? { |process| send(process).enabled? }
  end

  def enabled_phases_and_publications_count
    PHASES_AND_PUBLICATIONS.count { |process| send(process).enabled? }
  end

  def total_comments
    questions.sum(:comments_count) + draft_versions.map(&:total_comments).sum
  end

  def status
    today = Date.current

    if today < start_date
      :planned
    elsif end_date < today
      :closed
    else
      :open
    end
  end

  private

    def valid_date_ranges
      if end_date && start_date && end_date < start_date
        errors.add(:end_date, :invalid_date_range)
      end
      if debate_end_date && debate_start_date && debate_end_date < debate_start_date
        errors.add(:debate_end_date, :invalid_date_range)
      end
      if draft_end_date && draft_start_date && draft_end_date < draft_start_date
        errors.add(:draft_end_date, :invalid_date_range)
      end
      if allegations_end_date && allegations_start_date &&
         allegations_end_date < allegations_start_date
        errors.add(:allegations_end_date, :invalid_date_range)
      end
    end

end

# == Schema Information
#
# Table name: legislation_processes
#
#  id                         :integer          not null, primary key
#  title                      :string
#  description                :text
#  additional_info            :text
#  start_date                 :date
#  end_date                   :date
#  debate_start_date          :date
#  debate_end_date            :date
#  draft_publication_date     :date
#  allegations_start_date     :date
#  allegations_end_date       :date
#  result_publication_date    :date
#  hidden_at                  :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  summary                    :text
#  debate_phase_enabled       :boolean          default(FALSE)
#  allegations_phase_enabled  :boolean          default(FALSE)
#  draft_publication_enabled  :boolean          default(FALSE)
#  result_publication_enabled :boolean          default(FALSE)
#  published                  :boolean          default(TRUE)
#  proposals_phase_start_date :date
#  proposals_phase_end_date   :date
#  proposals_phase_enabled    :boolean
#  proposals_description      :text
#
