HtmlParser = require "htmlparser"
FS = require 'fs'
{EventEmitter} = require 'events'


END_EVENT = {"event": "END"}

NO_TRANSFORM = {}


outputTag = (el) ->
    tag = "<"
    tag += el.name
    

    if el.attribs
        for attr, value of el.attribs
            tag += " " + attr
            if value
                tag += "=\"" + value + "\""
    tag += ">"
    tag


class InnerRewriter extends EventEmitter
    # calls: write(), reset(), done()
    #
    #
    # emits: data, (from, to, data)
    # , end, close, error
    #
    #
    # Data in buffer until to, but not including index to is emitted,
    # data is written out.
    # previous index updated to match to.
    # A nop, flushing the buffer would be emit (index, index, "")
    constructor: (transform) ->
        @_transform = transform

        # Streams
        @_dataQueue = []
        @_paused = false
        @_destroySoon = false
        @_destoryed = false

        @_willFlush = false

    transformElement: (el) ->
        @_transform el

    writeTag: (el) ->
        transformed = @transformElement el

        if transformed != NO_TRANSFORM
            from = el.location.character
            to = from + el.raw.length + 2
            @write from, to, transformed

        null

    writeText: (el) ->
        # ILB

    writeComment: (el) ->
        # ILB

    writeDirective: (el) ->
        # ILB

    reset: () ->

    done: () ->
        @end()

    # Streaming Methods
    flush: () ->
        if !@_willFlush
            process.nextTick () =>
                @_flush()

    _flush: () ->
        @_willFlush = false
        if @_paused or @_destroyed
            return
        
        while @_dataQueue.length
            data = @_dataQueue.shift()
            if data == END_EVENT
                @emit 'end'
            else
                @emit 'data', data...

        if @_destorySoon
            @_destroyed = true
            @emit 'close'

    destroySoon: () ->
        @_destroySoon = true

    destroy: () ->
        @_destroyed = true
        @emit 'close'

    pause: () ->
        @_paused = true

    resume: () ->
        @_paused = false
        @flush()

    write: (data...) ->
        @_dataQueue.push data
        @flush()

    end: () ->
        @_dataQueue.push END_EVENT
        @flush()

class OuterRewriter extends EventEmitter
    constructor: (transform) ->
        @rewriter = new InnerRewriter transform
        @parser = new HtmlParser.Parser @rewriter, includeLocation: true

        # Input Stream
        @input = ""
        @index = 0

        # Output Stream
        # @output = Buffer (TODO)
        @_paused = false
        @_destroySoon = false
        @_destroyed = false
        @_willFlush = false

        @_setup()

    _setup: () ->
        @rewriter.on "data", @_handleData
        @rewriter.on "end", @_handleEnd
        @rewriter.on "close", @_handleClose
        @rewriter.on "error", @_handleError

    _handleData: (from, to, data) =>
        @_output @input[@index...from]
        if data
            @_output data

        @index = to        


    _handleEnd: () =>
        @_output @input[@index...@input.length]
        @_end()

    _handleClose: () =>
        @_close()

    _handleError: (error) =>
        @_error error

    _output: (output) ->
        @emit "data", output

    _end: () ->
        @emit "end"

    _close: () ->
        @emit "close"

    _error: () ->
        @emit "error"


    # Input
    write: (data) ->
        if Buffer.isBuffer(data)
            data = data.toString()

        @input += data
        @parser.parseChunk data

        true

    end: () ->
        @parser.done()

    pipe: (destination, options) ->
        @on "data", (output) ->
            destination.write output

        if !options? or !options.end? or options.end
            @on "end", () ->
                destination.end()

        destination

    writable: true
    readable: true
    
    destroySoon: () ->
        @_destroySoon = true

    destroy: () ->
        @_destroyed = true
        @emit 'close'


exports.Rewriter = OuterRewriter
exports.NO_TRANSFORM = NO_TRANSFORM
exports.outputTag = outputTag
