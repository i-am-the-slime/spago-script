module Script.Prelude.Cookie
  ( module Script.Cookie
  , ResponseHeaders
  , cookiesFromHeaders
  , cookiesFromResponseHeaders
  ) where

import Prelude

import Data.Array as Array
import Data.Tuple.Nested ((/\))
import Foreign.Object as Object
import Script.Cookie (Cookie, CookieAttribute, SetCookie, cookie, cookieHeader, parseCookieHeader, parseSetCookieHeader, setCookie, setCookieHeader)
import Script.Cookie as Cookie
import Script.Prelude.Fetch (Headers)
import Script.Prelude.Fetch as Fetch

-- | Every header of a response, one entry per value, as `responseHeaders` lists them.
type ResponseHeaders = Fetch.ResponseHeaders

cookiesFromHeaders :: Headers -> Array SetCookie
cookiesFromHeaders headers = do
  Object.toArrayWithKey (/\) headers
    # Array.mapMaybe Cookie.headerSetCookie

-- | The cookies a response sets, from `responseHeaders response`. Each `Set-Cookie` header is one
-- | cookie.
cookiesFromResponseHeaders :: ResponseHeaders -> Array SetCookie
cookiesFromResponseHeaders headers = do
  headers
    <#> (\{ name, value } -> name /\ value)
    # Array.mapMaybe Cookie.headerSetCookie
