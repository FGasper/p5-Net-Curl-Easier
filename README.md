# NAME

Net::Curl::Easier - Convenience wrapper around [Net::Curl::Easy](https://metacpan.org/pod/Net::Curl::Easy)

# SYNOPSIS

    my $easy = Net::Curl::Easier->new( url => 'http://perl.org' )->perform();

    print $easy->body();

    # … or, to dig in to the response:
    my $response = HTTP::Response->parse( $easy->head() . $easy->body() );

# DESCRIPTION

[Net::Curl](https://metacpan.org/pod/Net::Curl) is wonderful, but [Net::Curl::Easy](https://metacpan.org/pod/Net::Curl::Easy) is a bit clunky for
day-to-day use. This library attempts to make that, well, “easier”. :-)

This module extends Net::Curl::Easy, with differences as noted here:

# DIFFERENCES FROM Net::Curl::Easy

- The response headers and body go to an internal buffer by default.
Net::Curl::Easy simply adopts libcurl’s defaults, which is understandable
but frequently unhelpful.
- Character encoding. As of this writing Net::Curl::Easy uses
[SvPV](https://metacpan.org/pod/perlapi#SvPV), which means that what libcurl receives depends on
how Perl internally stores your string. Thus, two identical strings given
to Net::Curl::Easy can yield different input to libcurl.

    This library fixes that by requiring all strings to be **byte** **strings**
    and normalizing Perl’s internal storage before calling into Net::Curl::Easy.

- `new()` accepts a list of key/value pairs to give to `set()`
(see below).
- `perform` returns the instance object, which facilitates chaining.

# SEE ALSO

- [Net::Curl::Promiser](https://metacpan.org/pod/Net::Curl::Promiser) wraps [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) with promises.
Recommended for concurrent queries!
- [Net::Curl::Simple](https://metacpan.org/pod/Net::Curl::Simple) takes a similar approach to this module but
presents a substantially different interface.

# METHODS

Besides those inherited from Net::Curl::Easy, this class defines:

## $obj = _OBJ_->set( $NAME1 => $VALUE1, $NAME2 => $VALUE2, .. )

`setopt()`s mutiple values in a single call. Instead of:

    $easy->setopt( Net::Curl::Easy::CURLOPT_URL, 'http://perl.org' );
    $easy->setopt( Net::Curl::Easy::CURLOPT_VERBOSE, 1 );

… you can do:

    $easy->set( url => 'http://perl.org', verbose => 1 );

See [curl\_easy\_setopt(3)](http://man.he.net/man3/curl_easy_setopt) for the full set of options you can give here.

Note that, since _OBJ_ is returned, you can chain calls to this with
calls to other methods like `perform()`.

## $obj = _OBJ_->push( $NAME1 => \\@VALUES1, $NAME2 => \\@VALUES2, .. )

Like `set()`, but for `pushopt()`.

## $value = _OBJ_->get($NAME)

Like `set()`, but for `getinfo()`. This, of course, doesn’t return
_OBJ_, so it can’t be chained.

## $str = _OBJ_->head()

Returns _OBJ_’s internal HTTP response header buffer, as a byte string.

## $str = _OBJ_->body()

Returns the HTTP response body, as a byte string.

# WRAPPED METHODS

- `escape()` and `send()` apply the character encoding fix described
above.
- `setopt()` and `pushopt()` fix character encoding and return
the instance object.
- `perform()` returns the instance object.

# STATIC FUNCTIONS

For convenience, `Net::Curl::Easy::strerror()` is aliased in this module.

# LICENSE & COPYRIGHT

Copyright 2021 by Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic) for details.

1;
