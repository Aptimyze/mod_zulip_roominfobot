local json = require('util.json')
local ut = module:require('utils')
local commands = module:require('commands')


--- Zulip request handler

-- handles incomming zulip request
local function handle_zulip_request(event)
  local request, response = event.request, event.response
  local headers = request.headers

  module:log('debug', 'Request: %s', request.body)

  for k,v in pairs(headers) do
    module:log('debug', '%s: %s', k, v)
  end

  if not headers.content_length
     or tonumber(headers.content_length) <= 0
     or headers.content_type ~= 'application/json' then
    return 400
  end

  local payload = json.decode(request.body)

  if not payload then return 500 end

  if not ut.has_valid_bot_token(payload.token) then
    return 403
  end

  local cmd, args = ut.parse_message(payload.data, payload.trigger)
  local resp_data

  if commands[cmd] then
    resp_data = commands[cmd](args)
  else
    resp_data = 'Unknown command.\nUse the `help` command to list all available commands.'
  end

  response.status_code = 200
  response.headers = {
    content_type = 'application/json; charset=utf-8;'
  }

  return json.encode({ content = resp_data })
end


-- Add the item to the http provider
module:depends('http')
module:provides('http', {
  route = {
    ['POST'] = handle_zulip_request
  }
})
