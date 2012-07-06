FS = require 'fs'

captureResponse = require './../capture'
{Rewriter, NO_TRANSFORM, outputTag} = require './../rewrite'

module.exports = randomCats = (path) ->
    ###
    RewriteHTML middleware.

    Rewrites response HTML's Urls, so they point a new Urls given by `rewriteUrl`
    argument.

    ###
   
    # Get list of Cat Images
    kittiesRaw = FS.readFileSync(path, 'utf8').split("\n")
    kitties = []

    for kitty in kittiesRaw
        kitty = kitty.replace /(#.*)/, ""
        kitty = kitty.replace /\s+/g, ""
        if kitty
            kitties.push kitty
    
    getKittyURL = () ->
        index = Math.floor(Math.random() * kitties.length)
        kitties[index]
    
    transform = (el) ->
        ###
        Inserts Cats

        Looks in:
            - img (src)
        ###
        
        if el.name == 'img' 
            if !el.attribs? or !el.attribs.src or (Math.random() > 10)
                return NO_TRANSFORM

            random = Math.random().toString()[2...7]
            el.attribs.src = getKittyURL() 
            outputTag el
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
