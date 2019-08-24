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
    
    if kparts[1]=="all_probes"
      kparts[1]=""
    end

    req_types = ["counters","fts","resources","sessions","alerts"]
    default_req_type="counters"
    if req_types.include?(kparts[2].downcase)
      default_req_type = kparts.delete_at(2)
    end

    if kparts[4] && kparts[4].match(/\(.*\)/)
      kparts[4] = kparts[4].split(/\(|\)/).last
    end
    kparts [4] = kparts[4] || 0
    case default_req_type
      when "counters"
        ret = { 
          :probe_id =>  kparts[1],
          :key     =>   kparts[3],
          :meter   =>   kparts[4].to_i,
          :counter_group    =>   "",
          :meter_units => "",
          :meter_desc=>"",
          :meter_type => 4,
          :topper_bucket_size => 300, 
          :bucket_size => 60
         }
         if kparts[5] and (JSON.parse(kparts[5]) rescue nil)
          ret[:extra_options] = JSON.parse(kparts[5])
         end
        # counter matching needs round trip use longest  match,

        req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST, 
    						 :get_meter_info => true )

        get_response_zmq(@zmq_endpoint,req) do |resp|
              resp.group_details
                  .sort{ |a,b| a.name.length <=> b.name.length}
                  .each do |g|
                      if g.name.downcase.start_with?(kparts[2].downcase)
                        ret[:counter_group]=g.guid
                        ret[:counter_group_name]=g.name
                        ret[:bucket_size]=g.bucket_size
                        ret[:topper_bucket_size]=g.topper_bucket_size
                        ret[:meter_units]=g.meters[ ret[:meter]].units
                        ret[:meter_type]=g.meters[ ret[:meter]].type
                        ret[:meter_desc]=g.meters[ ret[:meter]].description
                        break
                      end
              end
        end
        return ret
      when "alerts"
        alert_group = "{9AFD8C08-07EB-47E0-BF05-28B4A7AE8DC9}"
        if kparts[2].downcase == "Badfellas".downcase
          alert_group = "{5E97C3A3-41DB-4E34-92C3-87C904FAB83E}"
        end
        return {
          alert_group:alert_group,
          alert_group_name:"IDS Alerts"
        }
    end
  end
end
