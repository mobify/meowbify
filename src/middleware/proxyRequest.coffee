Http = require 'http'
Https = require 'https'


module.exports = proxyRequest = (req, res) ->
    options =
        host: req.headers['host']
        path: req.url
        headers: req.headers
        method: req.method
        agent: false # Disable connection pooling

    RequestClient = if req.secure then Https else Http

    clientReq = RequestClient.request options, (clientRes) ->
        statusCode = clientRes.statusCode
        headers = clientRes.headers

        # Remove problematic headers
        if 'transfer-encoding' of headers
            delete headers['transfer-encoding']
        if 'content-length' of headers
            delete headers['content-length']

        res.writeHead statusCode, headers
        clientRes.on "data", (data) ->
            res.write data

        clientRes.on "end", (data) ->
            res.end data

            if clientRes.trailers
                res.addTrailers clientRes.trailers

    req.on "data", (data) ->
        clientReq.write data

    req.on "end", (data) ->
        clientReq.end data

    req.on "close", () ->
        clientReq.abort()

