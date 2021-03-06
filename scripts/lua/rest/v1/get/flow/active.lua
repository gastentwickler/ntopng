--
-- (C) 2013-20 - ntop.org
--

local dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

require "lua_utils"
require "flow_utils"
local format_utils = require("format_utils")
local flow_consts = require "flow_consts"
local flow_utils = require "flow_utils"
local icmp_utils = require "icmp_utils"
local json = require "dkjson"
local rest_utils = require("rest_utils")

--
-- Read list of active flows
-- Example: curl -u admin:admin -d '{"ifid": "1"}' http://localhost:3000/lua/rest/v1/get/flow/active.lua
--
-- NOTE: in case of invalid login, no error is returned but redirected to login
--

sendHTTPContentTypeHeader('application/json')

local rc = rest_utils.consts_ok
local res = {}

local ifid = _GET["ifid"]

if isEmptyString(ifid) then
   rc = rest_utils.consts_invalid_interface
   print(rest_utils.rc(rc))
   return
end

interface.select(ifid)

if not isEmptyString(_GET["sortColumn"]) then
   -- Backward compatibility
   _GET["sortColumn"] = "column_" .. _GET["sortColumn"]
end

-- This is using GET parameters to handle:
--
-- Pagination:
-- - sortColumn
-- - sortOrder
-- - currentPage
-- - perPage
--
-- Filtering, including:
-- - application
-- - l4proto
-- - host
-- - vlan
--
local flows_filter = getFlowsFilter()

local flows_stats = interface.getFlowsInfo(flows_filter["hostFilter"], flows_filter)

if flows_stats == nil then
   print(rest_utils.rc(rest_utils.consts_not_found))
   return
end

local total = flows_stats["numFlows"]

flows_stats = flows_stats["flows"]

if flows_stats == nil then
   print(rest_utils.rc(rest_utils.consts_internal_error))
   return
end

local data = {}

for _key, value in ipairs(flows_stats) do
   local record = {}

   local key = value["ntopng.key"]

   record["key"] = string.format("%u", value["ntopng.key"])
   record["hash_id"] = string.format("%u", value["hash_entry_id"])

   record["first_seen"] = value["seen.first"]
   record["last_seen"] = value["seen.last"]

   local client = {}

   local cli_name = flowinfo2hostname(value, "cli")
   client["name"] = stripVlan(cli_name)
   client["ip"] = value["cli.ip"]
   client["port"] = value["cli.port"]

   local info = interface.getHostInfo(value["cli.ip"], value["cli.vlan"])
   if info then
      client["is_broadcast_domain"] = info.broadcast_domain_host
      client["is_dhcp"] = info.dhcpHost
      client["is_blacklisted"] = info.is_blacklisted
   end

   record["client"] = client

   local server = {}

   local srv_name = flowinfo2hostname(value, "srv")
   server["name"] = stripVlan(srv_name) 
   server["ip"] = value["srv.ip"]
   server["port"] = value["srv.port"]

   info = interface.getHostInfo(value["srv.ip"], value["srv.vlan"])
   local info = interface.getHostInfo(value["cli.ip"], value["cli.vlan"])
   if info then
      server["is_broadcast"] = info.broadcast_domain_host
      server["is_dhcp"] = info.dhcpHost
      server["is_blacklisted"] = info.is_blacklisted
   end

   record["server"] = server

   record["vlan"] = value["vlan"]

   record["protocol"] = {}
   record["protocol"]["l4"] = value["proto.l4"]
   record["protocol"]["l7"] = value["proto.ndpi"]

   record["duration"] = value["duration"]

   record["bytes"] = value["bytes"]

   record["thpt"] = {}
   record["thpt"]["pps"] = value["throughput_pps"]
   record["thpt"]["bps"] = value["throughput_bps"]*8

   local cli2srv = round((value["cli2srv.bytes"] * 100) / value["bytes"], 0)
   record["breakdown"] = {}
   record["breakdown"]["cli2srv"] = cli2srv
   record["breakdown"]["srv2cli"] =  (100-cli2srv)

   if isScoreEnabled() then
      record["score"] = format_utils.formatValue(value["score"])
   end

   data[#data + 1] = record

end -- for

res = {
   perPage = flows_filter["perPage"],
   currentPage = flows_filter["currentPage"],
   totalRows = total,
   data = data,
   sort = {
      {
         flows_filter["sortColumn"],
         flows_filter["sortOrder"]
      }
   },
}

print(rest_utils.rc(rc, res))
