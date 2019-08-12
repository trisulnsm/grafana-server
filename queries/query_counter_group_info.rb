require_relative  'query_base'

class CounterGroupInfoRequest < QueryBase 

  def get_all_cgs
    all_cgs={}
    req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST)
    TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|
      resp.group_details
              .sort{ |a,b| a.name <=> b.name}
              .each do |g|
                all_cgs[g.guid]=g.name
      end
    end
    return all_cgs
  end

  def get_meters_for_cgname(cgname)
    all_meters = {}
    req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST,
      :get_meter_info => true)
    TrisulRP::Protocol.get_response_zmq(@zmq_endpoint,req) do |resp|
      resp.group_details.select{|g| g.name==cgname}.first.meters.each do | meter|
        all_meters[meter.id] = "#{meter.description.strip}(#{meter.id})"
      end
    end
    return all_meters
  end
end
