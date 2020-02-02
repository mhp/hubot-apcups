# Description:
#   Interrogate UPSs managed by apcupsd instances
#
# Commands:
#   hubot ups configure <name> <host:port> - configure a new UPS
#   hubot ups delete <name> - remove a UPS
#   hubot ups list - list the known UPSs
#   hubot ups status - summarise status of all upss
#   hubot ups batt[ery] - summarise battery status

net = require 'net'

# The brain key containing all the configured UPS info
ups_cfg = 'ups.config'

poll_ups = (host, port, callback) ->
  retvals = {}
  stream = Buffer.alloc(0)
  c = net.createConnection port, host

  c.on 'connect', () ->
    c.write "\0\x06status"

  c.on 'data', (data) ->
    stream = Buffer.concat([stream, data])
    loop
      if stream.length < 2
        break
      kvl = stream.readInt16BE(0)
      if kvl == 0
        c.end()
        callback retvals
        break
      if stream.length < 2+kvl
        break
      kv = stream.toString 'ascii', 2, 2+kvl
      stream = stream.slice 2+kvl

      sep = kv.indexOf ":"
      if sep > 0
        k = kv.substring 0, sep
        v = kv.substring sep+1
        retvals[k.trim()] = v.trim()

status_handler = (res, ups) ->
  (vals) ->
    res.reply "#{ups}: #{vals['STATUS']} line=#{vals['LINEV']} load=#{vals['LOADPCT']}"

battery_handler = (res, ups) ->
  (vals) ->
    res.reply "#{ups}: charge=#{vals['BCHARGE']} left=#{vals['TIMELEFT']} batt=#{vals['BATTV']} changed=#{vals['BATTDATE']}"

module.exports = (robot) ->

  robot.respond /ups configure (\w+) ([\w-.]+) (\d+)/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    upss[res.match[1]] = {"host": res.match[2], "port": res.match[3]}
    robot.brain.set(ups_cfg, JSON.stringify(upss))
    res.reply "UPS #{res.match[1]} configured"

  robot.respond /ups delete ([a-z]+)/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    if res.match[1] in Object.keys(upss)
      delete upss[res.match[1]]
      robot.brain.set(ups_cfg, JSON.stringify(upss))
      res.reply "UPS #{res.match[1]} deleted"
    else
      res.reply "UPS #{res.match[1]} not found"

  robot.respond /ups list/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    res.reply "#{Object.keys(upss).length} devices configured"
    for k, v of upss
      res.reply "UPS: #{k} : #{JSON.stringify(v)}"

  # status summary
  robot.respond /ups status/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    for k, v of upss
      poll_ups v.host, v.port, status_handler(res, k)

  # battery summary
  robot.respond /ups batt(ery)?/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    for k, v of upss
      poll_ups v.host, v.port, battery_handler(res, k)

  # command handler to poll a UPS
  robot.respond /ups poll$/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    for k, v of upss
      res.reply "Polling #{k} (#{v.host}:#{v.port})"
      poll_ups v.host, v.port, (vals) ->
        res.reply "Returned #{JSON.stringify vals}"

  robot.respond /ups poll (\w+)/i, (res) ->
    upss = JSON.parse(robot.brain.get(ups_cfg)) or {}
    myups = upss[res.match[1]]
    if myups == undefined
      res.reply "UPS #{res.match[1]} not recognised"
    else
      res.reply "Polling #{myups.host}:#{myups.port}"
      poll_ups myups.host, myups.port, (vals) ->
        res.reply "Returned #{JSON.stringify vals}"


