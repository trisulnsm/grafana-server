require_relative 'query_base'

class CounterItemRequest < QueryBase 

  def do_query(range, composite_key_metric)

    if COMMON_METRICS[composite_key_metric] 
      composite_key_metric = COMMON_METRICS[composite_key_metric]
      p "Using a standard metric to #{composite_key_metric}"
    end

    ckey = parse_composite_key( composite_key_metric)
    ckey[:userlabel] = ckey[:key] 

	req =TrisulRP::Protocol.mk_request(TRP::Message::Command::COUNTER_ITEM_REQUEST,
			 :counter_group => ckey[:counter_group],
			 :key => ckey[:key],
			 :time_interval =>  mk_time_interval( [Time.parse(range["from"]),  Time.parse(range["to"])] ),
             :meter => ckey[:meter],
             :probe_id => ckey[:probe_id])
             

    # multiplier Bps to bits-per-sec
    multiplier =  ckey[:meter_units]=="Bps" ? 8:1

    datapoints = []
	TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|
      ckey[:userlabel]=resp.key.label
      datapoints = resp.stats.collect  do |tsval|
		[ tsval.values[ckey[:meter]]*multiplier , 1000*tsval.ts_tv_sec  ]
      end
    end 

    return {
      target:  "#{ckey[:userlabel]}(#{ckey[:meter]})",
      datapoints: datapoints
    }
  end

end
