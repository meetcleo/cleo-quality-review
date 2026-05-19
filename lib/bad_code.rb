class BadCode
  def a
    [{}].map.each do |f|
      puts f
      f.first
    end
  end
end
