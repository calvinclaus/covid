require 'rails_helper'

RSpec.describe "LinkedInAccount" do
  it "can manage locks" do
    # I don't know how to test this properly - LinkedInAccountLockReceiverMock would have to be a persisted
    # model for global ids to work. It feels odd to create a database model just for testing.
    # linked_in_account = create(:linked_in_account)
    # receiver1 = LinkedInAccountLockReceiverMock.new
  end
end

# class LinkedInAccountLockReceiverMock
# attr_accessor :calls
# def linked_in_account_lock_received(linked_in_account, argument)
# @calls ||= []
# @calls << { linked_in_account: linked_in_account, argument: argument }
# end
# end
