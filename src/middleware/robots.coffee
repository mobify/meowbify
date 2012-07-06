
module.exports = robots = (req, res, next) ->
    ###
    Says no to robots.
    
    ###
    
    robots = "User-agent: *\nDisallow: /"
    
    if /robots[.]txt/.test req.url
        res.writeHead 200, {
            'Content-Length': robots.length,
            'Content-Type': "text/plain"
        }

        res.write robots
        res.end()

    else if /google|bot|crawl|spider|rambler|yahoo|accoona|aspseek|lycos|scooter|altavista|estyle|scrubby|ask jeeves|trend micro/.test req.headers['user-agent']
        res.writeHead 401, "Disallowed by Robots"
        res.end()

    else
        next()
