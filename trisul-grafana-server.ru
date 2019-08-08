require 'json'
require 'time'
require 'trisulrp'


TRISUL_DOMAIN_SOCKET="ipc:///usr/local/var/lib/trisul-probe/domain0/run/ctl_local_req"
TRISUL_HUB="hub0"
TRISUL_CONTEXT="default"

class CounterItemRequest

  def initialize(zmq_endpoint)
    @zmq_endpoint=zmq_endpoint
  end

  def query(range, composite_key_metric)
    ckey = parse_composite_key( composite_key_metric)

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
      datapoints = resp.stats.collect  do |tsval|
		[ tsval.values[ckey[:meter]]*multiplier , 1000*tsval.ts_tv_sec  ]
      end
    end 


    return {
      target:  ckey[:key],
      datapoints: datapoints
    }
  end

  # return [probe, guid, key, meterid] 
  def parse_composite_key( ckey)

    kparts = ckey.split('/')
    if kparts.size != 4 
      kparts = ckey.split('^')
    end

    ret = { 
      :probe_id =>  kparts[0],
      :key     =>   kparts[2],
      :meter   =>   kparts[3].to_i,
      :counter_group    =>   "",
      :meter_units => ""
     }

    # counter matching needs round trip use longest  match,
    #
    # meter names 
    req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST, 
						 :get_meter_info => true )

    get_response_zmq(@zmq_endpoint,req) do |resp|
          resp.group_details
              .sort{ |a,b| b.name.length <=> a.name.length}
              .each do |g|
                  if g.name.downcase.start_with?(kparts[1])
                    ret[:counter_group]=g.guid
                    ret[:counter_group_name]=g.name
                    ret[:meter_units]=g.meters[ ret[:meter]].units
                  end
          end
    end
    return ret
  end
end

class HelloWorld

  def initialize(zmq_endpoint)
    @zmq_endpoint=zmq_endpoint
  end

  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when "/"
      [200, {"Content-Type" => "text/html"}, ["Success"]]
    when /search/
      [200, {"Content-Type" => "application/json"},  [  [].to_json() ]]
    when /query/
      query_data = JSON.parse(req.body.read)
      query_response = query_data["targets"].collect do |t|
        CounterItemRequest.new(@zmq_endpoint).query(query_data["range"],t["target"])
      end
      [200, {"Content-Type" => "application/json"}, [query_response.to_json()] ]
    when /annotations/
      [200, {"Content-Type" => "text/html"}, ["Hello World!"]]
    else
      [404, {"Content-Type" => "text/html"}, ["I'm Lost!"]]
    end
  end
end


# domain socket 
req =TrisulRP::Protocol.mk_request(TRP::Message::Command::CONTEXT_CONFIG_REQUEST, 
          {:destination_node => TRISUL_HUB, :context_name => TRISUL_CONTEXT } )
resp = TrisulRP::Protocol.get_response_zmq(TRISUL_DOMAIN_SOCKET,req) 
trp_server_socket = resp.endpoints_query.first
print("Connecting to TRP Server at ZMQ #{trp_server_socket}")

# start server 
run HelloWorld.new(trp_server_socket)
