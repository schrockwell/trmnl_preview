module TRMNLPreview
  module LiquidFilters
    def number_with_delimiter(number)
      # TODO: Replace with ActiveSupport's number_with_delimiter
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end