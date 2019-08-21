class ModelUtils

  # format for bps,Kbps,Mb etc...
  def self.fmt_prefix_2 raw_value
      raw_value = raw_value.to_f
      units_str = [
                    [1099511627776.0,"T","%.2f %s"],
                    [1073741824.0,   "G","%.2f %s"],
                    [1048576.0,      "M","%.2f %s"],
                    [1024.0,         "K","%.2f %s"],
                    [1,     "", "%d %s"],
                    [1e-03, "m","%.3f %s"],
                    [1e-06, "u","%.3f %s"],
                    [1e-09, "n","%.3f %s"],
                    [1e-12, "p","%.3f %s"],
                  ]

    return "0 " if raw_value == 0

    units_str.each do |unit|
          if raw_value >= unit[0]
            retval = raw_value  / unit[0]
            return format(unit[2], retval, unit[1])
          end
    end
    return raw_value.to_s
  end

   def self.fmt_prefix_10 raw_value
  raw_value = raw_value.to_f
  units_str = [
                    [1e+12,"T","%.2f %s"],
                    [1e+9,   "G","%.2f %s"],
                    [1e+6,      "M","%.2f %s"],
                    [1000,         "K","%.2f %s"],
                    [1,     "", "%d %s"],
                    [1e-03, "m","%.3f %s"],
                    [1e-06, "u","%.3f %s"],
                    [1e-09, "n","%.3f %s"],
                    [1e-12, "p","%.3f %s"],
              ]

    return "0 " if raw_value == 0

    units_str.each do |unit|
      if raw_value >= unit[0]
        retval = raw_value  / unit[0]
        return format(unit[2], retval, unit[1])
      end
    end
    return raw_value.to_s
  end


  def self.fmt_volume(val,units="")
    fmt_prefix_2(val)+ units.to_s.gsub(/ps$/,"")
  end
  
  def self.fmt_bw(val,units="bps")
    fmt_prefix_10(val) + units.to_s.downcase
  end


end
