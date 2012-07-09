Connect = require 'connect'

BufferStream = require './bufferstream'



captureResponse = (res, onEndHeader) ->
    # Hold on to original functions
    write = res.write
    end = res.end
    writeHead = res.writeHead
    setHeader = res.setHeader

    res.reason = ""
    res.headers = {}

    # Create paused buffer to collect data
    buffer = new BufferStream()

    headersWritten = false

    res.write = (data, encoding) ->
        buffer.write data, encoding

        if not headersWritten and onEndHeader
            headersWritten = true
            onEndHeader res.statusCode, res.reason, res.headers

    res.end = (data, encoding) ->
        buffer.end data, encoding
        
        if not headersWritten and onEndHeader
            headersWritten = true
            onEndHeader res.statusCode, res.reason, res.headers

    res.writeHead = (_statusCode, _reason..., _headers) ->
        statusCode = _statusCode
        res.reason = _reason[0] or res.reason
        res.headers = _headers or res.headers

        writeHead.apply res, arguments

        if not headersWritten and onEndHeader
            headersWritten = true
            onEndHeader res.statusCode, res.reason, res.headers

    res.setHeader = (header, value) ->
        res.headers[header] = value

    res.on "close", () ->
        buffer.destroy()

    newRes =
        write: (data, encoding) ->
            write.call res, data, encoding
        end: (data, encoding) ->
            end.call res, data, encoding
        on: () ->
            res.on.apply res, arguments
        emit: () ->
            res.emit.apply res, arguments
        writable: true
        removeListener: () ->
            res.removeListener.apply res, arguments
        destroy: () ->
            @emit "close"

    return [buffer, newRes]


module.exports = captureResponse

