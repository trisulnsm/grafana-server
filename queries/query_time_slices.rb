class TimeSliesRequest  < QueryBase 

  def get_available_time()
    resp = TrisulRP::Protocol.get_available_time(@zmq_endpoint,20)
    rows = [["Hub0","#{resp[0]}","#{resp[1]}",format_duration(resp[1]-resp[0])]]
    return {
      columns:    [  {"text":"Node",  "type": "string"}  , 
                     {"text":"From", "type": "date"}  ,
                     {"text":"To",    "type": "date"},
                     {"text":"Duration", "type": "strings"} ],
      rows: rows,
      type: "table"
    }
  end

  def  format_duration( diffSecs)

    return "0 Secs" if diffSecs==0

    divs = [
            [24*3600, "d"],
            [3600,    "h" ],
            [60,      "m"],
            [1,       "s"]
          ]
    outs = ""
    divs.each do | ditem |
     val = diffSecs / ditem[0]
     if  val >= 1
        outs << "#{val.to_i} #{ditem[1]}:"
        diffSecs = diffSecs.to_i % ditem[0]
     end
    end

    return outs.chop
  end

end