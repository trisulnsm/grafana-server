class QueryAlertsRequest < QueryBase
  def do_query(range, composite_key_metric,adhoc_filter)
    ckey = parse_composite_key( composite_key_metric)
    m=composite_key_metric.match(/list\((\d+)\)/)
    topcount = m[1].to_i
   
    req_opts = {
       :alert_group => ckey[:alert_group],
       :time_interval =>  mk_time_interval( [Time.parse(range["from"]),  Time.parse(range["to"])] ),
       :maxitems =>topcount,
       :probe_id => ckey[:probe_id]
    }

    adhoc_filter.each do | af|
      if af["key"].match(/Priority/i)
       req_opts[:priority] = TRP::KeyT.new({label:af["value"]}) 
      end
      if af["key"].match(/source.*ip/i)
       req_opts[:source_ip] = TRP::KeyT.new({label:af["value"]}) 
      end
      if af["key"].match(/destination.*ip/i)
       req_opts[:destination_ip] = TRP::KeyT.new({label:af["value"]}) 
      end
      if af["key"].match(/source.*port/i)
       req_opts[:source_port] = TRP::KeyT.new({label:af["value"]}) 
      end
      if af["key"].match(/destination.*port/i)
       req_opts[:destination_port] = TRP::KeyT.new({label:af["value"]}) 
      end
    end
    req =TrisulRP::Protocol.mk_request(TRP::Message::Command::QUERY_ALERTS_REQUEST,req_opts)
    rows = [] 
    TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|
      resp.alerts.each do | alert|
        rows.push(
          [ModelUtils::fmt_ts(alert.time.tv_sec),
          alert.priority.key.to_s,
          alert.sigid.label,
          alert.source_ip.label,alert.source_port.label.to_s,
          alert.destination_ip.label,alert.destination_port.label.to_s,
          alert.classification.label
          ]
          )
      end
    end
    return[{
      columns:    [  {"text":"Time",  "type": "Date"},
                     {"text":"Priority",  "type": "string"}  , 
                     {"text":"Description",  "type": "string"} ,
                     {"text":"Src IP", "type": "string"}  ,
                     {"text":"Src Port", "type": "string"}  ,
                     {"text":"Dest IP", "type": "string"}  ,
                     {"text":"Dest Port", "type": "string"} ,
                     {"text":"Classification", "type": "string"}   
                    ],
      rows: rows,
      type: "table"
    }]
  end
end