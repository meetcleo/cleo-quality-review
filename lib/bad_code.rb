class BadCode
  def a
    [{}].map.each do |f|
      puts f
      # Added a line to see if Fasterer would catch it?
      f.each_key do |k|
        puts k
      end
    end
  end
end
