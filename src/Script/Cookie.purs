module Script.Cookie
  ( Cookie
  , CookieAttribute
  , SetCookie
  , cookie
  , cookieHeader
  , headerSetCookie
  , parseCookieHeader
  , parseSetCookieHeader
  , setCookie
  , setCookieHeader
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), maybe)
import Data.String as String
import Data.String.CodeUnits as String.CodeUnits
import Data.String.Pattern (Pattern(..))
import Data.Tuple.Nested (type (/\), (/\))

type Cookie =
  { name :: String
  , value :: String
  }

type CookieAttribute =
  { name :: String
  , value :: Maybe String
  }

type SetCookie =
  { name :: String
  , value :: String
  , attributes :: Array CookieAttribute
  }

cookie :: String -> String -> Cookie
cookie name value = { name, value }

cookieHeader :: Array Cookie -> String
cookieHeader cookies = cookies <#> renderCookie # String.joinWith "; "

parseCookieHeader :: String -> Array Cookie
parseCookieHeader header = do
  header
    # String.split (Pattern ";")
    # Array.mapMaybe parseCookiePair

setCookie :: String -> String -> Array CookieAttribute -> SetCookie
setCookie name value attributes = { name, value, attributes }

setCookieHeader :: SetCookie -> String
setCookieHeader set = do
  let renderedAttributes = set.attributes <#> renderCookieAttribute
  String.joinWith "; " $ [ renderCookie { name: set.name, value: set.value } ] <> renderedAttributes

parseSetCookieHeader :: String -> SetCookie
parseSetCookieHeader header = do
  let parts = String.split (Pattern ";") header
  let parsed = parts # Array.mapMaybe parseCookieAttribute
  case Array.uncons parsed of
    Just { head: first, tail: attributes } -> { name: first.name, value: maybe "" identity first.value, attributes }
    Nothing -> { name: "", value: "", attributes: [] }

renderCookie :: Cookie -> String
renderCookie { name, value } = name <> "=" <> value

renderCookieAttribute :: CookieAttribute -> String
renderCookieAttribute { name, value } = case value of
  Just attributeValue -> name <> "=" <> attributeValue
  Nothing -> name

parseCookiePair :: String -> Maybe Cookie
parseCookiePair text = do
  name /\ value <- splitCookiePart text
  pure { name, value }

parseCookieAttribute :: String -> Maybe CookieAttribute
parseCookieAttribute text = case splitCookiePart text of
  Just (name /\ value) -> Just { name, value: Just value }
  Nothing -> do
    let name = String.trim text
    if name == "" then Nothing
    else Just { name, value: Nothing }

splitCookiePart :: String -> Maybe (String /\ String)
splitCookiePart text = do
  index <- String.CodeUnits.indexOf (Pattern "=") text
  let name = String.trim $ String.CodeUnits.take index text
  let value = String.trim $ String.CodeUnits.drop (index + 1) text
  if name == "" then Nothing
  else Just $ name /\ value

headerSetCookie :: String /\ String -> Maybe SetCookie
headerSetCookie (name /\ value)
  | String.toLower name == "set-cookie" = Just $ parseSetCookieHeader value
  | otherwise = Nothing
