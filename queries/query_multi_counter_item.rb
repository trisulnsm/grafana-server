require_relative  'query_base'

#
# TopperHistoryRequest
#
class MultipleCounterItemRequest  < QueryBase 

  def do_query(range, composite_key_metric)
	  
    if COMMON_METRICS[composite_key_metric] 
      composite_key_metric = COMMON_METRICS[composite_key_metric]
      p "Using a standard metric to #{composite_key_metric}"
    end

    return_data=[]
    items = composite_key_metric.split("/")
    keys = items[3].split(",")
    meters = items[4].split("|")
    keys.each do | k|
      meters.each do |m|
        i = items.dup
        i[3]=k.strip
        i[4]=m.strip
        return_data << CounterItemRequest.new(@zmq_endpoint).do_query(range,i.join("/"))
      end
    end
    return return_data
  end
end
