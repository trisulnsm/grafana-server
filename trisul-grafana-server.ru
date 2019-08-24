#
# to be run with rackup 
require 'json'
require 'trisulrp'
require_relative  'queries/queries.rb'

TRISUL_DOMAIN_SOCKET="ipc:///usr/local/var/lib/trisul-hub/domain0/run/ctl_local_req"
TRISUL_HUB="hub0"
TRISUL_CONTEXT="default"


# for testing
#TRISUL_DOMAIN_SOCKET="ipc:///home/vivek/bldart/th3/trisul_hub/stg/var/lib/trisul-hub/domain0/run/ctl_local_req"

# the server 
class TrisulGrafana

  def initialize(zmq_endpoint)
    @zmq_endpoint=zmq_endpoint
  end

  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when "/"
      [200, {"Content-Type" => "text/html"}, ["Success"]]
    when /search/
      return_data = COMMON_METRICS.keys().collect { |k| [k] }
      qp = JSON.parse(req.body.read) 
      target_data = qp["target"]
      if target_data.length > 0 and (JSON.parse(target_data) rescue nil)
        target = JSON.parse(target_data) 
        case target["find"]
          when "probes"
            return_data = ContextConfigRequest.new(TRISUL_DOMAIN_SOCKET).get_all_probes(TRISUL_HUB,TRISUL_CONTEXT)
          when "alertgroups"
            return_data = ["IDS","Badfellas"]
          when "cgguid"
            return_data = CounterGroupInfoRequest.new(@zmq_endpoint).get_all_cgs()
          when "meter"
            return_data =  CounterGroupInfoRequest.new(@zmq_endpoint).get_metersname_for_cgname(target["selected_cg"])
        end
      end
      [200, {"Content-Type" => "application/json"},  [  return_data.to_json() ]]
    when /query/
      query_data = JSON.parse(req.body.read)
      query_response = []
      query_data["targets"].collect do |t|
        if t["target"] =~ /toppers/ &&  t["type"] == "table" 
          query_response = CounterTopperRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
        elsif t["target"] =~ /toppers/ &&  t["type"] == "timeserie" 
          chartitems = CounterTopperHistoryRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
          chartitems.each { |d| query_response << d } 
        elsif  t["target"] =~/\/alerts\// && t["type"] == "table"
          query_response = QueryAlertsRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"],query_data["adhocFilters"])
        elsif t["target"]=~/get_available_time/ && t["type"]=="table"
          query_response << TimeSliesRequest.new(@zmq_endpoint).get_available_time()
	       elsif t["target"] 
          chartitems = MultipleCounterItemRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
          chartitems.each { |d| query_response << d } 
        end
      end
      [200, {"Content-Type" => "application/json"}, [query_response.to_json()] ]
    when /annotations/
      [200, {"Content-Type" => "text/html"}, ["Hello World!"]]
    when /tag-keys/
      resp = [
        {"type":"text","text":"Priority"},
        {"type":"text","text":"Source IP"},
        {"type":"text","text":"Source Port"},
        {"type":"text","text":"Destination IP"},
        {"type":"text","text":"Destination Port"}
      ]
     [200, {"Content-Type" => "application/json"}, [resp.to_json()] ]
   when /tag-values/
      resp = []
      query_data = JSON.parse(req.body.read)
      if query_data["key"] == "Priority"
        resp = [
          {"text":"1"},
          {"text":"2"},
          {"text":"3"}
        ]
      end
     [200, {"Content-Type" => "application/json"}, [resp.to_json()] ]
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

puts("")
puts("Connecting to TRP Server at ZMQ #{trp_server_socket}")
puts("Testing the connection..")

# test the connection 
req =TrisulRP::Protocol.mk_request(TRP::Message::Command::TIMESLICES_REQUEST, 
                                  {:context_name => TRISUL_CONTEXT, :get_total_window =>true } )
resp = TrisulRP::Protocol.get_response_zmq(trp_server_socket,req) 
puts("Connection successful")
puts("Time Window at server #{Time.at(resp.total_window.from.tv_sec)} to #{Time.at(resp.total_window.to.tv_sec)}  ")
puts(" ")

#
# start server 
run TrisulGrafana.new(trp_server_socket)
