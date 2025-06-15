# frozen_string_literal: true

RSpec::Matchers.define :be_a_valid_ip do
  match do |ip|
    IPAddr.new(ip.to_s)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end
