COOKIE_DOMAIN_REGEX = /domain\s*=\s*[.]?([^\s^;]*)/gi

rewriteRequestHeaders = (req, removeHost) ->
    HOST_HEADERS = [
        'host',
    ]

    URL_HEADERS = [
        'referer'
        'origin',
    ]

    for header in HOST_HEADERS
        if header of req.headers
            req.headers[header] = removeHost req.headers[header]
    
    for header in URL_HEADERS
        if header of req.headers
            req.headers[header] = removeHost req.headers[header], url: true

rewriteResponseHeaders = (res, addHost) ->
    URL_HEADERS = [
        'location'
    ]


    writeHead = res.writeHead

    res.writeHead = (statusCode, reason..., headers={}) ->
        reason = reason[0]

        # Simple Headers
        for header in URL_HEADERS
            if header of res.headers
                headers[header] = addHost headers[header], url: true

        # Access-Control-Access-Origin
        if 'access-control-allow-origin' of headers
            access_control_allow_origin = headers['access-control-allow-origin'].trim()

            if access_control_allow_origin != '*'
               headers['access-control-allow-origin'] = addHost access_control_allow_origin, url: true

        # Set-Cookie
        if 'set-cookie' of headers
            cookies = headers['set-cookie']

            newCookies = for cookie in cookies
                # Rewrite domains
                cookie = cookie.replace COOKIE_DOMAIN_REGEX, (matched, domain) ->
                    "domain=.#{addHost domain, prefix: false, port: false}"
                # Neuter Secure Only Cookies
                cookie.replace /Secure/i, ""

            headers['set-cookie'] = newCookies

        if reason
            writeHead.call res, statusCode, reason, headers
        else
            writeHead.call res, statusCode, headers

        
module.exports = rewriteHost = (addHost, removeHost) ->
    (req, res, next) ->
        rewriteRequestHeaders req, removeHost
        rewriteResponseHeaders res, addHost

        next()
