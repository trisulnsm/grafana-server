require_relative  'query_base'

#
# TopperHistoryRequest
#
class MultipleCounterItemRequest  < QueryBase 

  def do_query(range, composite_key_metric)
    items = composite_key_metric.split("/")
    return items[3].split(",").collect do |k|
      i = items.dup
      i[3]=k.strip
      CounterItemRequest.new(@zmq_endpoint).do_query(range,i.join("/"))
    end
  end

end