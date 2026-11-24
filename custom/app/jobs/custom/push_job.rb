class Custom::PushJob < ApplicationJob
  queue_as :high

  def perform(message)
    Custom::Push.new(message).perform
  end
end
