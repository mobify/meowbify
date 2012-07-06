captureResponse = require './../capture'
{Rewriter, NO_TRANSFORM, outputTag} = require './../rewrite'


transformUrl = (el, addHost) ->
    ###
    Calls `addHost` for any URL found in the
    HTML source, replacing it's value.

    Looks in:
        - a (href)
        - link (href)
        - img (src)
        - style (src)
        - script (src)
        - form (action)
    ###
    
    if el.name == 'a' or el.name == 'link'
        if !el.attribs? or !el.attribs.href
            return NO_TRANSFORM

        el.attribs.href = addHost el.attribs.href, url: true
        outputTag el

    else if el.name == 'img' or el.name == 'style' or el.name == 'script' or el.name == 'iframe'
        if !el.attribs? or !el.attribs.src
            return NO_TRANSFORM

        el.attribs.src = addHost el.attribs.src, url: true
        outputTag el

    else if el.name == 'form'
        if !el.attribs? or !el.attribs.action
            return NO_TRANSFORM

        el.attribs.action = addHost el.attribs.action, url: true
        outputTag el
    
    else
        NO_TRANSFORM


module.exports = rewriteHTML = (addHost) ->
    ###
    RewriteHTML middleware.

    Rewrites response HTML's Urls, so they point a new Urls given by `addHost`
    argument.

    ###
    transform = (el) ->
        transformUrl el, addHost

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
