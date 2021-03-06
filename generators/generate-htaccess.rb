# This script generates a .htaccess file for content negotiation according to the 
# W3C Best Practice Recipes for Publishing RDF Vocabularies recipe4a
# https://www.w3.org/TR/swbp-vocab-pub/#recipe4a
# Some commented-out code from their example .htaccess file may persist here.
#
# The following command line parameters are substituted into the generated file.
$rewrite_base, $vocab_url_suffix, $standard_url_suffix, $vocab_rdf, $vocab_ttl, $standard_subdir, $html_file = ARGV

$nargs = 7
raise "#{$0}: Wrong number of command line parameters. expected #{$nargs}." unless ARGV.size == $nargs

# CAUTION: Be really careful about escaping hashes that are intended to end up in a rewritten URL!
#          Also the NE (no excape) part of [R=303,NE] is vital, or you end up with %23 in the URL instad of #.
# CAUTION: The second param to RewriteCond is a regular expression, so a literal + must be encoded in 
#          an .htasccess file's condition as '\+'. But ruby also eats backslashes here!
#          This is why we have \\+ below.

puts <<-HERE
# This .htaccess file was generated by #{$0} with parameters:
#    rewrite_base: #{$rewrite_base}
#    vocab_url_suffix: #{$vocab_url_suffix}
#    standard_url_suffix: #{$standard_url_suffix}
#    vocab_rdf: #{$vocab_rdf}
#    vocab_ttl: #{$vocab_ttl}
#    standard_subdir: #{$standard_subdir}
#    html_file: #{$html_file}
#
# Turn off MultiViews
Options -MultiViews

# Directive to ensure *.rdf and *.skos files served as appropriate content type,
# if not present in main apache config
AddType application/rdf+xml .rdf
AddType application/rdf+xml .skos

# Rewrite engine setup
RewriteEngine On
#RewriteBase /examples
RewriteBase #{$rewrite_base}

# For debugging. See Logging section in http://httpd.apache.org/docs/current/mod/mod_rewrite.html
# BUT ... LogLevel must be done in apache config file, not allowed in .htaccess.
# LogLevel alert rewrite:trace3

# Rewrite rule to serve HTML content from the namespace URI if requested
RewriteCond %{HTTP_ACCEPT} !application/rdf\\+xml.*(text/html|application/xhtml\\+xml)
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_ACCEPT} application/xhtml\\+xml [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla/.*
#RewriteRule ^example4a/$ example4a-content/2005-10-31.html [R=303]
RewriteRule ^#{$vocab_url_suffix}/$ https://%{SERVER_NAME}#{$rewrite_base}#{$html_file} [R=303]

# Rewrite rule to serve directed HTML content from class/prop URIs
RewriteCond %{HTTP_ACCEPT} !application/rdf\\+xml.*(text/html|application/xhtml\\+xml)
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_ACCEPT} application/xhtml\\+xml [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla/.*
#RewriteRule ^example4a/(.+) example4a-content/2005-10-31.html\#$1 [R=303,NE]
RewriteRule ^#{$vocab_url_suffix}/(.+) https://%{SERVER_NAME}#{$rewrite_base}#{$html_file}\#$1 [R=303,NE]

RewriteCond %{HTTP_ACCEPT} !application/rdf\\+xml.*(text/html|application/xhtml\\+xml)
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_ACCEPT} application/xhtml\\+xml [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla/.*
# For now, for any URI that mentions the standard, we just point to the same section of the html doc:
# We could do a lot better than this ... in the future.
RewriteRule ^#{$standard_url_suffix} https://%{SERVER_NAME}#{$rewrite_base}#{$html_file}\#H4 [R=303,NE]

# Rewrite rule to serve Turtle content if requested
RewriteCond %{HTTP_ACCEPT} text/turtle
RewriteRule ^#{$vocab_url_suffix}/ https://%{SERVER_NAME}#{$rewrite_base}#{$vocab_ttl} [R=303]

# Rewrite rule to serve SKOS files. 
# There is an assumption here (in the RewriteRule pattern that filenames of the skos files
# contain only certain characters.
# The Rewrite rule ia intended to match all of:
#   #{$standard_url_suffix}/activities
#   #{$standard_url_suffix}/activities/
#   #{$standard_url_suffix}/activities/A01
# and similar constructions for SKOS files other than activities.
RewriteCond %{HTTP_ACCEPT} application/rdf\\+xml
RewriteRule ^#{$standard_url_suffix}/([-a-z]+) https://%{SERVER_NAME}#{$rewrite_base}#{$standard_subdir}/$1.skos [R=303]

# Rewrite rule to serve RDF/XML content from the namespace URI by default
#RewriteRule ^example4a/ example4a-content/2005-10-31.rdf [R=303]
RewriteRule ^#{$vocab_url_suffix}/ https://%{SERVER_NAME}#{$rewrite_base}#{$vocab_rdf} [R=303]
HERE
