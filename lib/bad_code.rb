class BadCode
  def a
    [{}].map.each do |f|
      puts f
      # Added a line to see if Fasterer would catch it?
      f.keys.each do |k|
        puts k
      end
    end
  end
end
