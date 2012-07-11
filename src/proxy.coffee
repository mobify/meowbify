Http = require 'http'

Connect = require 'connect'

{getHostUtilities} = require './utils'
stats = require './middleware/stats'
rewriteHTML = require './middleware/rewriteHTML'
randomCat = require './middleware/randomCat'
rewriteHost = require './middleware/rewriteHost'
{gunZip} = require './middleware/gzip'
proxyRequest = require './middleware/proxyRequest'
robots = require './middleware/robots'
insertGA = require './middleware/insertGA'

###
Cat Injecting Proxy


Intro
----------------
This proxy is designed to insert tags, and also rewrite links, headers, cookies, etc
so it appears to transparently work as a man in the middle.

The proxy is designed to run on a wildcard domain *.PROXY_SUFFIX_DOMAIN, and all links
are rewritten to match that domain.

To support HTTP and HTTPS sites, we use a prefix.

It currently only support sites running on ports :80 and :443.

Structure
-----------------

The proxy is setup as series of connect middleware, which rewrite various parts
of the site:

1. Logging:

    Connect.logger(LOG_FORMAT)

2. Block Crawlers:

    robots

3. Marks whether it is secure or not (based on prefix):

    isSecure

4. Replace the images with Cat Images:

    randomCat()

5. Rewrite the links, src, images, in the page:

    rewriteHTML(addHost)

6. Rewrite the headers (Host, Cookie, etc) to what the Origin/Browser expects (and vice versa)

    rewriteHost(addHost, removeHost)

7. Unzip responses from the Origin

    gunZip

8. Repeat the (now modified) request against the 

    proxyRequest


This is a little bit of an abuse of the middleware pattern, but it was
fun to implement.


Configuration
-----------------
These can be set by environment variables


PORT
: Port proxy listens on
Default: 5000

EXTERNAL_PORT
: Port proxy appears to be listening on (eg, the front-end server)
Default: 80

SUFFIX_DOMAIN
: Domain that is appended when rewritting links
Default: 'meowbify.com'

PREFIX_SUBDOMAIN
: The subdomain that is prefix to mark http and https sites.
Default: "cat" (which means cat.* == http, cats.* == https).

: Path (

LOG_FORMAT
: Connect Middleware style log format
Default: ':method :status :response-time \t:req[Host]:url :user-agent'



###

PROXY_PORT = process.env.PORT || 5000
PROXY_EXTERNAL_PORT = process.env.EXTERNAL_PORT || 80
PROXY_SUFFIX_DOMAIN = process.env.SUFFIX_DOMAIN || "meowbify.com"
LOG_FORMAT = ':method :status :response-time \t:req[Host]:url :user-agent' 

PROXY_PREFIX = process.env.PREFIX_SUBDOMAIN || "cat"

KITTY_INDEX = "#{__dirname}/../kitties.txt"

setupCatInjector = () ->
    # Connect App for Inserting Cats
    [addHost, removeHost, isHostSecure] = getHostUtilities PROXY_SUFFIX_DOMAIN, PROXY_EXTERNAL_PORT, PROXY_PREFIX 

    isSecure = (req, res, next) ->
        if isHostSecure req.headers['host']
            req.secure = true
        else
            req.secure = false
        
        next()

    app = Connect()

    app
        .use(Connect.logger(LOG_FORMAT))
        .use(stats)
        .use(robots)
        .use(isSecure)
        .use(insertGA())
        .use(randomCat(KITTY_INDEX))
        .use(rewriteHTML(addHost))
        .use(rewriteHost(addHost, removeHost))
        .use(gunZip)
        .use(proxyRequest)

    app

setupStatic = () ->
    # Serves the landing page.

    app = Connect()
    
    app
        .use(Connect.static(__dirname + "/../static", maxAge: 24*60*60, redirect: true))
    
    app


###
Swallow Exceptions
###
process.on 'uncaughtException', (err) ->
    console.log "Caught exception: #{err}"
    if err.stack
        console.log err.stack



###
Setup the handler
###
console.log "Starting Meowbify on #{PROXY_PORT}"

catInjectorApp = setupCatInjector()
staticApp = setupStatic()

# Routes between the two apps.
handler = (req, res) ->
    proxyRe = RegExp "^#{PROXY_PREFIX}s?[.]"

    if proxyRe.test req.headers['host']
        catInjectorApp.handle req, res
    else
        staticApp.handle req, res

Server = Http.createServer handler
Server.listen PROXY_PORT



