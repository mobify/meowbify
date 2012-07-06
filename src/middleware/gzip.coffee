Zlib = require 'zlib'

captureResponse = require './../capture'

exports.gunZip = gunZip = (req, res, next) ->
    req.headers['accept-encoding'] = 'gzip, deflate'

    [buffer, newRes] = captureResponse res, (statusCode, reason, headers) ->
        transformResponse statusCode, reason, headers

    # Collect Response Body
    buffer.pause()
    
    gzipped = false

    transformResponse = (statusCode, reason, headers) ->
        if gzipped
            unzip = Zlib.createUnzip()
            buffer.pipe(unzip).pipe(newRes)
        else
            buffer.pipe(newRes)
        buffer.resume()


    writeHead = res.writeHead

    res.writeHead = (statusCode, reason..., headers={}) ->
        reason = reason[0]
        
        encoding = headers['content-encoding']
        if /gzip|deflate/.test encoding
            gzipped = true
        
            # Remove encoding, length headers
            delete headers['content-encoding']
            delete headers['content-length']

        if reason
            writeHead.call res, statusCode, reason, headers
        else
            writeHead.call res, statusCode, headers

    next()
