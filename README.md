Meowbify
==============

Meowbify is a Node.js super-webscale kitten-powered Coffeescript-infused evented based streaming cat injecting proxy.

Think CloudFlare, but with Cats.

[Check it out live](http://www.meowbify.com/)


Meowbifiwhat is it?
--------------------

This proxy is designed to insert tags, and also rewrite links, headers, cookies, etc
so it appears to transparently work as a man in the middle.

It also inserts Cats, courtesy of [The Cat API](http://thecatapi.com/).

The proxy is designed to run on a wildcard domain *.SUFFIX_DOMAIN, and everything
are rewritten to match that domain.

To support HTTP and HTTPS sites, we use a prefix usually cat.* or cats.*.

It currently only support origin sites running on ports :80 and :443.


Configuration
--------------

These can be set by environment variables:

*PORT*
: Port proxy listens on
Default: 5000

*EXTERNAL_PORT*
: Port proxy appears to be listening on (eg, the front-end server)
Default: 80

*SUFFIX_DOMAIN*
: Domain that is appended when rewritting links
Default: 'meowbify.com'

*PREFIX_SUBDOMAIN*
: The subdomain that is prefix to mark http and https sites.
Default: "cat" (which means cat.* == http, cats.* == https).

*LOG_FORMAT*
: Connect Middleware style log format
Default: ':method :status :response-time \t:req[Host]:url :user-agent'


Special Thanks
--------------

The Mobify Team:

 - @fractaltheory who christened it "Meowbify"
 - @kpeatt who butchered^Hbeautifully altered Mobify's logo in to a Cat
 - @shawnjan8 who squatted the domain
 - @rrjamie who wasted several afternoons of time to write it
 - @mobify whose time and money @rrjamie was wasting

Also thanks to @AdenForshaw, who built the CatAPI.
