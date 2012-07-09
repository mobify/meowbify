Stream = require 'stream'

###
BufferStream

A streaming interface for a buffer.

You can stream (eg, `pipe`) data in to a `BufferStream` object
and then `pipe` it into another object.

BufferStreams have a few benefits:
    - Automatically buffer any amount of data (memory permitting).
         - Automatically increase in size in a semi-intelligent fashion.
         - No need to wait for `drain` on the write side.
         - Makes efficient use of buffers

    - You can `pause` a BufferStream and collect data for later.

###

class BufferStream extends Stream
    MIN_BUFFER_SIZE = 65536
    MAX_BUFFER_SIZE = 65536

    constructor: (size = MIN_BUFFER_SIZE) ->
        @writeIndex = 0
        @readIndex = 0
        @buffer = new Buffer(size)

        @readBuffer = 1024*16

        @encoding = 'utf8'
        @emitStrings = false


        # Writing
        @_endWrite = false
        @_endRead = false
  
        @_destroySoon = false
        @_destroyed = false
        
        @writable = true
        @readable = true
        
        @paused = false


    ###
    #
    ###
    ensureSpace: (bytes) ->
        bytesAvailable = @buffer.length - @writeIndex

        # Current buffer might be large enough
        if bytesAvailable >= bytes
            return

        # Allocate new buffer
        currentSize = @writeIndex - @readIndex
        desiredSize = currentSize + bytes

        targetSize = MIN_BUFFER_SIZE
        while targetSize < desiredSize
            targetSize *= 2

        # Copying to a new buffer prevents mangling of buffers
        # that were returned by _read.
        newBuffer = new Buffer targetSize
        @buffer.copy newBuffer, 0, @readIndex, @writeIndex
        @writeIndex = @writeIndex - @readIndex
        @readIndex = 0

        @buffer = newBuffer

        true

    ###
    # Internal Buffer Access
    ###
    _writeBuffer: (buffer) ->
        @ensureSpace buffer.length
        buffer.copy @buffer, @writeIndex
        @writeIndex = @writeIndex + buffer.length

        true

    _writeString: (string) ->
        bytes = Buffer.byteLength string, @encoding
        @ensureSpace bytes
        
        @buffer.write string, @writeIndex, bytes, @encoding
        @writeIndex = @writeIndex + bytes

        true
        
    _readBuffer: (maxBytes = 0) ->
        if maxBytes == 0
            @targetIndex = @writeIndex
        else
            @targetIndex = @readIndex + maxBytes

        if  @targetIndex > @writeIndex
            @targetIndex = @writeIndex

        buffer = @buffer.slice @readIndex, @targetIndex
        @readIndex = @targetIndex

        buffer

    _getLength: () ->
        @writeIndex - @readIndex


    ###
    # Readable Stream Methods
    ###
    setEncoding: (encoding) ->
        if encoding != 'utf8'
            throw new Error "Only UTF8 is a supported encoding"

        throw new Error "Not Implemented."
        @encoding = encoding
        @emitStrings = true

    pause: () ->
        @paused = true

    resume: () ->
        @paused = false
        @flush()


    _flush: () ->
        if @paused or @_destroyed
            return

        # Flush some data
        @_emitData(@_endWrite or @_destroySoon)

        empty = !@_getLength()
        
        # Trigger End Event
        if empty and @_endWrite
            @_emitEnd()

        if empty and @_endWrite and @_destroySoon
            @destroy()

    _emitData: (force = false) ->
        bytesRemaining = @_getLength()

        if (bytesRemaining >= MIN_BUFFER_SIZE) or force
            data = @_readBuffer MAX_BUFFER_SIZE
            if data.length
                @emit "data", data

            # There may be more data
            @flush()

    _emitEnd: () ->
        @readable = false
        @_endRead = true
        @emit "end"
        @destroy()

    ###
    # Writable Stream Methods
    ###

    write: (data, encoding = 'utf8') ->
        if encoding != 'utf8'
            throw new Error "Only supports utf8."

        if @_endWrite or @_destroyed
            throw new Error "Cannot write to stream, has been ended or destroyed."

        if Buffer.isBuffer data
            @_writeBuffer data
        else
            # String
            @_writeString data, encoding

        @flush()
        true

    end: (data, encoding) ->
        if data?
            @write data, encoding

        @writable = false
        @_endWrite = true
        @flush()

    ###
    # Readable, Writable Stream Methods
    ###
    flush: () ->
        process.nextTick () =>
            @_flush()


    destroy: () ->
        if @_destroyed
            return

        @_destroyed = true
        @writable = false
        @readable = false
        if !@_endRead
            @emit "close"
        @cleanup()

    destroySoon: () ->
        @end()
        @_destroySoon = true
        @flush()

    cleanup: () ->
        @readIndex = 0
        @writeIndex = 0
        @buffer = null

module.exports = BufferStream
