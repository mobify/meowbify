module.exports = blacklist = (removeHost, blacklist, content) ->
    return (req, res, next) ->
        host = removeHost req.headers['host']

        if host in blacklist
            res.writeHead 404, "Four-oh-bore: Sense of humor not found", {
                "Content-Length": content.length,
                "Content-Type": "text/html"
            }
            res.write content
            return res.end()
        else
            next()


    

