# -*- coding: utf-8 -*-
module Blogit
  class Post < ActiveRecord::Base

    require 'acts-as-taggable-on'
    require "kaminari"
    require 'bootsy'

    include ::ActionView::Helpers::TextHelper
    include Bootsy::Container

    acts_as_taggable

    self.paginates_per Blogit.configuration.posts_per_page

    AVAILABLE_STATUS = (Blogit.configuration.hidden_states + Blogit.configuration.active_states)


    # ===============
    # = Validations =
    # ===============

    validates :title, presence: true, length: { minimum: 10, maximum: 66 }
    validates :body,  presence: true, length: { minimum: 10 }
    validates :blogger_id, presence: true
    validates :state, presence: true
    validate :only_owner, on: :create

    # ================
    # = Associations =
    # ================

    belongs_to :blogger, :polymorphic => true

    has_many :comments, :class_name => "Blogit::Comment"


    # added by shibiuya
    belongs_to :project

    # ==========
    # = Scopes =
    # ==========

    # Returns the blog posts paginated for the index page
    # @scope class
    scope :for_index, lambda { |page_no = 1| order("created_at DESC").page(page_no) }
#    scope :active, lambda { where(state:  Blogit.configuration.active_states ) }
    scope :active, lambda { where(state:  "公開" ) }
    # ====================
    # = Instance Methods =
    # ====================

    def to_param
      "#{id}-#{title.parameterize}"
    end
    
    def short_body
      truncate(body, length: 400, separator: "\n")
    end
    
    def comments
      check_comments_config
      super()
    end
    
    def comments=(value)
      check_comments_config
      super(value)
    end
    

    # If there's a current blogger and the display name method is set, returns the blogger's display name
    # Otherwise, returns an empty string
    def blogger_display_name
      if self.blogger and !self.blogger.respond_to?(Blogit.configuration.blogger_display_name_method)
        raise ConfigurationError,
        "#{self.blogger.class}##{Blogit.configuration.blogger_display_name_method} is not defined"
      elsif self.blogger.nil?
        ""
      else
        self.blogger.send Blogit.configuration.blogger_display_name_method
      end
    end

    private

    def check_comments_config
      raise RuntimeError.new("Posts only allow active record comments (check blogit configuration)") unless Blogit.configuration.include_comments == :active_record
    end

    def only_owner
      if blogger.owned_projects.nil? || blogger.owned_projects.count == 0
        errors.add :base, "You are not Project Owner"
      end
    end
  end
end
