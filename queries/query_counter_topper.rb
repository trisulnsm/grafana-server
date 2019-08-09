require_relative  'query_base'

#
# TopperRequest
#
class CounterTopperRequest  < QueryBase 

  def do_query(range, composite_key_metric)

    ckey = parse_composite_key( composite_key_metric)
    m=composite_key_metric.match(/toppers\((\d+)\)/)
    topcount = m[1].to_i

    req =TrisulRP::Protocol.mk_request(TRP::Message::Command::COUNTER_GROUP_TOPPER_REQUEST,
			 :counter_group => ckey[:counter_group],
			 :key => ckey[:key],
			 :time_interval =>  mk_time_interval( [Time.parse(range["from"]),  Time.parse(range["to"])] ),
       :meter => ckey[:meter],
       :maxitems =>topcount,
       :resolve_keys => true)

    multiplier = 1
    if ckey[:meter_type] == 4 
      multiplier = ckey[:topper_bucket_size]
    end

    rows = [] 
    TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|

          resp.keys.each do |key|
                rows << [ key.readable,
                          key.label,
                          key.metric * multiplier  ] 
          end
    end

    return {
      columns:    [  {"text":"Item",  "type": "string"}  , 
                     {"text":"Label", "type": "string"}  ,
                     {"text":"Total", "type": "number"} ],
      rows: rows,
      type: "table"
    }
  end

end
