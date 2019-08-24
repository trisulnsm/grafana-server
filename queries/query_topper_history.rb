require_relative  'query_base'

#
# TopperHistoryRequest
#
class CounterTopperHistoryRequest  < QueryBase 

  def do_query(range, composite_key_metric)

    ckey = parse_composite_key( composite_key_metric)


    # get toppers 
    toppers = CounterTopperRequest.new(@zmq_endpoint).do_query(range, composite_key_metric)

    if composite_key_metric.match(/total.*toppers/)
      return toppers
    end
    toppers[0][:rows].collect do | row |
      ckey[:key] = row[0]
      itemkey = "/#{ckey[:probe_id]}/#{ckey[:counter_group_name]}/#{ckey[:key]}/#{ckey[:meter]}"
      CounterItemRequest.new(@zmq_endpoint).do_query(range, itemkey)
    end 
  end

end
