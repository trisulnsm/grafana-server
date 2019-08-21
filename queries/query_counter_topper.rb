require_relative  'query_base'

#
# TopperRequest
#
class CounterTopperRequest  < QueryBase 

  def do_query(range, composite_key_metric)

    ckey = parse_composite_key( composite_key_metric)
    method_name = :fmt_volume
    multiplier = 1
    if ckey[:meter_type] == 4 
      multiplier = ckey[:topper_bucket_size]
    end
    if composite_key_metric.match(/current|latest/i)
      resp = TrisulRP::Protocol.get_available_time(@zmq_endpoint,20)
      range["from"] = (resp[1] - ckey[:topper_bucket_size].to_i).to_s
      range["to"] = resp[1].to_s
      multiplier =  ckey[:meter_units]=="Bps" ? 8: 1
      method_name= :fmt_bw
    end
    m=composite_key_metric.match(/toppers\((\d+)\)/)
    topcount = m[1].to_i
    req =TrisulRP::Protocol.mk_request(TRP::Message::Command::COUNTER_GROUP_TOPPER_REQUEST,
			 :counter_group => ckey[:counter_group],
			 :key => ckey[:key],
			 :time_interval =>  mk_time_interval( [Time.parse(range["from"]),  Time.parse(range["to"])] ),
       :meter => ckey[:meter],
       :maxitems =>topcount,
       :resolve_keys => true)


    rows = [] 
    TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|
      resp.keys.each do |key|
        next if key.key=="SYS:GROUP_TOTALS"
        rows << [ key.readable.to_s,
                  key.label.to_s,
                  ModelUtils.send(method_name,key.metric * multiplier,ckey[:meter_units]),
                  key.metric * multiplier,] 
      end
    end
    rows = rows.sort{|x,y| y[3]<=>x[3]}.slice(0,topcount.to_i)

    return {
      columns:    [  {"text":"Item",  "type": "string"}  , 
                     {"text":"Label", "type": "string"}  ,
                     {"text":"#{ckey[:meter_desc]}", "type": "string"},
                     {"text":"Raw #{ckey[:meter_desc]}", "type": "string"} ],
      rows: rows,
      type: "table"
    }
  end

end
