class BadCode
  def a
    [{}].each { |fields| print_fields(fields) }
  end

  private

  def print_fields(fields)
    puts fields
    fields.each_key { |key| puts key }
  end
end
