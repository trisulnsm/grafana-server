#
# to be run with rackup 
require 'json'
require 'trisulrp'
require_relative  'queries/queries.rb'

TRISUL_DOMAIN_SOCKET="ipc:///usr/local/var/lib/trisul-probe/domain0/run/ctl_local_req"
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
      [200, {"Content-Type" => "application/json"},  [   COMMON_METRICS.keys().collect { |k| [k] }.to_json() ]]
    when /query/
      query_data = JSON.parse(req.body.read)
      query_response = []

      query_data["targets"].collect do |t|
        if t["target"] =~ /toppers/ &&  t["type"] == "table" 
          query_response << CounterTopperRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
        elsif t["target"] =~ /toppers/ &&  t["type"] == "timeserie" 
          chartitems = CounterTopperHistoryRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
          chartitems.each { |d| query_response << d } 
        else
          query_response << CounterItemRequest.new(@zmq_endpoint).do_query(query_data["range"],t["target"])
        end
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
run TrisulGrafana.new(trp_server_socket)
