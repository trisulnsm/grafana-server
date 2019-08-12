require 'time'
require 'trisulrp'
require_relative  'query_canned'

# Base utility methods
# 
class QueryBase 

  def initialize(zmq_endpoint)
    @zmq_endpoint=zmq_endpoint
  end


  # return [probe, guid, key, meterid] 
  def parse_composite_key( ckey)

    kparts = ckey.split('/')
    if kparts.size != 5 
      kparts = ckey.split('^')
    end
    if kparts[1]=="all_probes"
      kparts[1]=""
    end
    if kparts[4].match(/\(.*\)/)
      kparts[4] = kparts[4].split(/\(|\)/).last
    end

    ret = { 
      :probe_id =>  kparts[1],
      :key     =>   kparts[3],
      :meter   =>   kparts[4].to_i,
      :counter_group    =>   "",
      :meter_units => "",
      :meter_type => 4,
      :topper_bucket_size => 300, 
      :bucket_size => 60 
     }

    # counter matching needs round trip use longest  match,
    req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST, 
						 :get_meter_info => true )

    get_response_zmq(@zmq_endpoint,req) do |resp|
          resp.group_details
              .sort{ |a,b| b.name.length <=> a.name.length}
              .each do |g|
                  if g.name.downcase.start_with?(kparts[2].downcase)
                    ret[:counter_group]=g.guid
                    ret[:counter_group_name]=g.name
                    ret[:bucket_size]=g.bucket_size
                    ret[:topper_bucket_size]=g.topper_bucket_size
                    ret[:meter_units]=g.meters[ ret[:meter]].units
                    ret[:meter_type]=g.meters[ ret[:meter]].type
                  end
          end
    end
    return ret
  end
end
