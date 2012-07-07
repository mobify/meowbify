Https = require 'https'

DEBUG = process.env['DEBUG']

MAX_COUNTER = 1000000
WORKER_ID = Math.floor(Math.random()*1000000)


bytesSent = 0
counter = 0
responseCount = 0
responseTime = 0
inFlight = 0


loghit = (time, bytes) ->
    responseTime += time || 0
    counter += 1
    responseCount += 1
    bytesSent += bytes
    if counter > MAX_COUNTER
        counter = 1

sendHits = () ->
    options = 
        host: "metrics-api.librato.com"
        path: "/v1/metrics"
        method: "POST"
        auth: process.env["LIBRATO_AUTH"] 
        headers:
            "Content-Type": "application/json"

    mem = process.memoryUsage()

    data =
        counters: [
            {
                name: "meowbify.requests"
                value: counter
                source: "heroku.#{WORKER_ID}"
            }
        ]
        gauges: [
            {
                name: "meowbify.responseTime"
                value: responseCount && (responseTime / responseCount) || 0
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.bytesSent"
                value: bytesSent
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.requestsPerSecond"
                value: responseCount / 60
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.inProgress"
                value: inFlight 
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.memory.rss"
                value: mem.rss
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.memory.heapUsed"
                value: mem.heapUsed
                source: "heroku.#{WORKER_ID}"
            },
            {
                name: "meowbify.memory.heapTotal"
                value: mem.heapTotal
                source: "heroku.#{WORKER_ID}"
            }
        ]
    req = Https.request options, (res) ->
        if DEBUG 
            console.log "Logged #{counter}"
            res.on "data", (data) ->
                console.log data.toString()

    responseTime = 0
    responseCount = 0
    bytesSent = 0
    req.end JSON.stringify(data)

setInterval sendHits, 60*1000


module.exports = statsCollector = (req, res, next) ->
    inFlight += 1

    flying = true
    time = Date.now()

    end = res.end
    write = res.write

    length = 0

    res.write = (chunk, encoding) ->
        if Buffer.isBuffer(chunk)
            length += chunk.length
        else
            length += Buffer.byteLength(chunk)
        write.call res, chunk, encoding
    
    res.end = (chunk, encoding) ->
        if flying
            inFlight -= 1
            flying = false
        loghit Date.now() - time, length
        end.call res, chunk, encoding

    res.on "close", () ->
        if flying
            inFlight -= 1
            flying = false

    next()
