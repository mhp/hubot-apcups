# Description:
#   Send UPS events into specified channels
#
# Commands:
#   hubot ups subscribe - show ups events in this channel
#   hubot ups unsubscribe - don't show ups events in this channel
#   hubot ups unsubscribe all - don't show ups events in any channel


ups_rooms = 'ups.rooms'

module.exports = (robot) ->

  robot.respond /ups subscribe/i, (res) ->
    subbedRooms = new Set(robot.brain.get(ups_rooms))
    subbedRooms.add(res.envelope.room)
    robot.brain.set(ups_rooms, Array.from(subbedRooms))
    res.reply "UPS events will be visible in this channel #{robot.brain.get(ups_rooms)}"

  robot.respond /ups unsubscribe$/i, (res) ->
    subbedRooms = new Set(robot.brain.get(ups_rooms))
    subbedRooms.delete(res.envelope.room)
    robot.brain.set(ups_rooms, Array.from(subbedRooms))
    res.reply "UPS events will no longer be visible in this channel #{robot.brain.get(ups_rooms)}"

  robot.respond /ups unsubscribe all/i, (res) ->
    subbedRooms = new Set()
    robot.brain.set(ups_rooms, Array.from(subbedRooms))
    res.reply "UPS events will no longer be visible in any channel #{robot.brain.get(ups_rooms)}"

  robot.router.post '/hubot/upsevent', (req, res) ->
    data = req.body

    subbedRooms = new Set(robot.brain.get(ups_rooms))
    subbedRooms.forEach (r) =>
      robot.messageRoom r, "UPS for #{data.ups}: #{data.event}" 

    res.send 'OK'
