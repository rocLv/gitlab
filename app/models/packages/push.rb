# frozen_string_literal: true
class Packages::Push < ApplicationRecord
  delegate :project, to: :package_file

  belongs_to :package_file, inverse_of: :push
  belongs_to :pipeline, class_name: 'Ci::Pipeline'

  scope :with_pipeline_id, ->(id) { where(pipeline_id: id) }
end
