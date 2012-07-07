Url = require 'url'

__ = require 'underscore'


DEBUG = process.env['DEBUG']

###
Url Options
    url (default false)
        If the string is a URL, not a host string.


    port (default true, unless port 80)
        If the string is should contain a port.
    
    prefix (default true)
        If we should prended the protocol prefix.
###

exports.getHostUtilities = getHostUtilities = (domain, port=80, prefix="http") ->
    addHost = (url, options={}) ->
        options = __.defaults options, port: true, prefix: true, url: false

        addHostToHost = (host, secure) ->
            newHost = ""
            
            if options.prefix and secure
                newHost += "#{prefix}s."
            else if options.prefix and !secure
                newHost += "#{prefix}."

            newHost += "#{host}.#{domain}"

            if options.port and port != 80
                newHost += ":#{port}"
            
            newHost 
        
        if options.url
            urlobj = Url.parse url, false, true
            if urlobj.host
                urlobj.host = addHostToHost urlobj.host, urlobj.protocol == 'https:'
                urlobj.protocol = "http:"
            Url.format urlobj
        else
            addHostToHost url

    HOST_REGEX = new RegExp "^#{prefix}(s)?[.](.*)[.]#{domain}(:\\d+)?", "i"
    removeHost = (url, options={}) ->
        options = __.defaults options, port: true, prefix: true, url: false 

        removeHostFromHost = (host) ->
            match = host.match HOST_REGEX
            if match
                host: match[2], secure: match[1] == 's'
            else
                if DEBUG
                    console.log "Error transforming host: #{host}"
                host


        if options.url
            urlobj = Url.parse url, false, true
            {host, secure} = removeHostFromHost urlobj.host
            urlobj.host = host
            urlobj.protcol = if secure then "https:" else "http:"
            url = Url.format urlobj
            url
        else
            {host, secure} = removeHostFromHost url
            host


    isHostSecure = (host) ->
        match = host.match HOST_REGEX
        if match[1] == 's'
            true
        else
            false

    [addHost, removeHost, isHostSecure]
