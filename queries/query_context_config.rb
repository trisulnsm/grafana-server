class ContextConfigRequest

  def initialize(domain_endpoint)
    @domain_endpoint = domain_endpoint
  end

  def get_all_probes(hub,context)
    all_probes = {"all_probes":"all_probes"}
    req =TrisulRP::Protocol.mk_request(TRP::Message::Command::CONTEXT_CONFIG_REQUEST, 
              {:destination_node => hub, :context_name => context } )
    TrisulRP::Protocol.get_response_zmq(@domain_endpoint,req) do |resp|
      resp.layers.each do  |probe|
        all_probes[probe.probe_id]=probe.probe_id
      end
    end
    return all_probes
  end
end
