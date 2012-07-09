Zlib = require 'zlib'

captureResponse = require './../capture'

ContentEncoding =
    IDENTITY: 0
    GZIP: 1
    DEFLATE: 2

    parse: (header) ->
        if /gzip/.test header
            @GZIP
        else if /deflate/.test header
            @DEFLATE
        else
            @IDENTITY

exports.gunZip = gunZip = (req, res, next) ->
    req.headers['accept-encoding'] = 'gzip, deflate'

    [buffer, newRes] = captureResponse res, (statusCode, reason, headers) ->
        transformResponse statusCode, reason, headers

    # Collect Response Body
    buffer.pause()
    
    encoding = ContentEncoding.IDENTITY

    transformResponse = (statusCode, reason, headers) ->
        if encoding != ContentEncoding.IDENTITY
            
            if encoding == ContentEncoding.GZIP
                unzip = Zlib.createGunzip()
            else
                unzip = Zlib.createInflate()

            buffer.pipe(unzip).pipe(newRes)
        else
            buffer.pipe(newRes)
        buffer.resume()


    writeHead = res.writeHead

    res.writeHead = (statusCode, reason..., headers={}) ->
        reason = reason[0]
        
        encoding = ContentEncoding.parse headers['content-encoding']
        
        if encoding != ContentEncoding.IDENTITY
            # Remove encoding, length headers
            delete headers['content-encoding']
            delete headers['content-length']

        if reason
            writeHead.call res, statusCode, reason, headers
        else
            writeHead.call res, statusCode, headers

    next()
