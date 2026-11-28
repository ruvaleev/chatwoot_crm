# The conversation an event being broadcast is about, so recipient lists can drop freelancers who may not see it.
class Custom::EventContext < ActiveSupport::CurrentAttributes
  attribute :conversation
end
