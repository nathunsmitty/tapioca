# frozen_string_literal: true

module Foo
  PI = 3.1415

  def self.bar(a = 1, b: 2, **opts)
    42
  end
end
