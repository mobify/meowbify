FS = require 'fs'

captureResponse = require './../capture'
{Rewriter, NO_TRANSFORM, outputTag} = require './../rewrite'

module.exports = insertGA = () ->
    ###
    Insert GA Middleware


    Inserts the tag after the opening head tag.
    ###
    


    gaTag = FS.readFileSync "#{__dirname}/../../vendor/ga.html"

    transform = (el) ->
        if el.name == 'body'
            tag = outputTag el

            tag+gaTag
        else
            NO_TRANSFORM


    (req, res, next) ->
        [buffer, newRes] = captureResponse res, (statusCode, reason, headers) ->
            transformResponse statusCode, reason, headers

        # Collect Response Body
        buffer.pause()

        transformResponse = (statusCode, reason, headers) ->
            # Check to make sure we should transform the response
            html = /html/.test headers['content-type']
            ajax = headers['x-requested-with']
            jsonp = /callback=/i.test req.url
            okay = statusCode == 200

            if html and !ajax and !jsonp and okay
                rw = new Rewriter transform
                buffer.pipe(rw).pipe(newRes)
            else
                buffer.pipe(newRes)
            
            buffer.resume()

        next()
