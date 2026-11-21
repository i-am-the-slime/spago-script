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
import JS.Fetch.Headers as Fetch.Headers
import Script.Cookie (Cookie, CookieAttribute, SetCookie, cookie, cookieHeader, parseCookieHeader, parseSetCookieHeader, setCookie, setCookieHeader)
import Script.Cookie as Cookie
import Yoga.Fetch (Headers)

type ResponseHeaders = Fetch.Headers.Headers

cookiesFromHeaders :: Headers -> Array SetCookie
cookiesFromHeaders headers = do
  Object.toArrayWithKey (/\) headers
    # Array.mapMaybe Cookie.headerSetCookie

cookiesFromResponseHeaders :: ResponseHeaders -> Array SetCookie
cookiesFromResponseHeaders headers = do
  Fetch.Headers.toArray headers
    # Array.mapMaybe Cookie.headerSetCookie
