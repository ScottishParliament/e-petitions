class RejectionReason < ActiveRecord::Base
  include Translatable

  translate :description

  alias_attribute :label, :title

  with_options presence: true, uniqueness: true do
    validates :code, length: { maximum: 30 }, format: { with: /\A[-a-z]+\z/ }
    validates :title, length: { maximum: 100 }
  end

  with_options presence: true do
    validates :description_en, length: { maximum: 1000 }

    with_options unless: :gaelic_disabled? do
      validates :description_gd, length: { maximum: 1000 }
    end
  end

  before_destroy do
    throw :abort if used?
  end

  class << self
    def default_scope
      order(:created_at)
    end

    def codes
      pluck(:code)
    end

    def hidden
      where(hidden: true)
    end

    def hidden_codes
      hidden.pluck(:code)
    end
  end

  def used?
    Rejection.used?(code)
  end
end
