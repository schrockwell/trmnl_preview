require 'active_support'

module TRMNLPreview
  module CustomFilters
    def number_with_delimiter(*args)
      ActiveSupport::NumberHelper.number_to_delimited(*args)
    end

    def number_to_currency(*args)
      ActiveSupport::NumberHelper.number_to_currency(*args)
    end
  end
end