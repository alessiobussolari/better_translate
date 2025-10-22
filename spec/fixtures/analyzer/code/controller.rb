# frozen_string_literal: true

# Example Rails controller with i18n keys
class UsersController < ApplicationController
  def index
    @greeting = t("users.greeting")
    @welcome = I18n.t("users.welcome", name: current_user.name)

    flash[:notice] = t("products.list")
  end

  def show
    # This uses the key users.profile.title
    @title = t("users.profile.title")
  end
end
