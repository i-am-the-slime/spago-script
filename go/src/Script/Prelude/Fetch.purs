module Script.Prelude.Fetch
  ( URL(..)
  , Response
  , Method
  , Headers
  , ResponseHeaders
  , Options
  , class HeaderFields
  , headerFields
  , defaultFetchOptions
  , getMethod
  , postMethod
  , putMethod
  , patchMethod
  , deleteMethod
  , headMethod
  , fetch
  , text
  , json
  , bytes
  , headers
  , responseHeaders
  , statusCode
  , url
  , makeHeaders
  , fromJSON
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Array as Array
import Data.Either (either)
import Data.List.NonEmpty (NonEmptyList)
import Data.Newtype (class Newtype, un)
import Data.Semigroup.Foldable (intercalateMap)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Data.Tuple.Nested (type (/\), (/\))
import Effect.Aff (Aff, throwError)
import Effect.Exception (error)
import Foreign (Foreign, ForeignError)
import Foreign.Object (Object)
import Foreign.Object as Object
import Go.Bytes (Bytes)
import Go.Error as Go.Error
import Go.Net.HTTP (HeaderName(..), HeaderValue(..))
import Go.Net.HTTP as HTTP
import Prim.Row as Row
import Prim.RowList (class RowToList, RowList)
import Prim.RowList as RowList
import Record as Record
import Type.Proxy (Proxy(..))
import Yoga.JSON (class ReadForeign)
import Yoga.JSON as Yoga.JSON
import Yoga.JSON.Error (renderHumanError)

newtype URL = URL String

derive instance Newtype URL _
derive newtype instance Eq URL
derive newtype instance Show URL

newtype Method = Method String

derive newtype instance Eq Method
derive newtype instance Show Method

-- | Request headers by name.
type Headers = Object String

-- | Every header of a response, one entry per value, so that each `Set-Cookie` keeps its own.
type ResponseHeaders = Array { name :: String, value :: String }

-- | What `fetch` takes. Leave out any field to get its default: `GET`, no headers, an empty body.
type Options =
  ( method :: Method
  , headers :: Headers
  , body :: String
  )

-- | A response with its whole body already read.
newtype Response = Response HTTP.ClientResponse

defaultFetchOptions :: { method :: Method }
defaultFetchOptions = { method: getMethod }

getMethod :: Method
getMethod = Method "GET"

postMethod :: Method
postMethod = Method "POST"

putMethod :: Method
putMethod = Method "PUT"

patchMethod :: Method
patchMethod = Method "PATCH"

deleteMethod :: Method
deleteMethod = Method "DELETE"

headMethod :: Method
headMethod = Method "HEAD"

-- | Sends the request and reads the whole response. An error status is a response, a server that
-- | can't be reached is an error. Redirects are followed.
fetch
  :: forall given all
   . Row.Union given Options all
  => Row.Nub all Options
  => URL
  -> Record given
  -> Aff Response
fetch address given = do
  answer <- HTTP.send request
  either (throwError <<< error <<< un Go.Error.ErrorMessage <<< Go.Error.message) (pure <<< Response) answer
  where
  options :: Record Options
  options = Record.merge given { method: getMethod, headers: Object.empty :: Headers, body: "" }

  request =
    { method: HTTP.Method (methodName options.method)
    , url: HTTP.URL (un URL address)
    , headers: Object.toArrayWithKey toHeader options.headers
    , body: options.body
    }

  methodName (Method name) = name

  toHeader name value = { name: HeaderName name, value: HeaderValue value }

text :: Response -> Aff String
text (Response answer) = pure (HTTP.responseBody answer)

bytes :: Response -> Aff Bytes
bytes (Response answer) = pure (HTTP.responseBodyBytes answer)

-- | The body parsed as JSON. Decode it with `fromJSON`, or `Yoga.JSON.read`.
json :: Response -> Aff Foreign
json response = do
  body <- text response
  either (throwError <<< error <<< renderErrors) pure (runExcept (Yoga.JSON.parseJSON body))

-- | Headers by name. Several values of one header are joined with `, `, as `fetch` does.
headers :: Response -> Headers
headers response = Object.fromFoldableWith (\later earlier -> earlier <> ", " <> later) pairs
  where
  pairs = responseHeaders response <#> \{ name, value } -> name /\ value

responseHeaders :: Response -> ResponseHeaders
responseHeaders (Response answer) = HTTP.responseHeaders answer <#> \{ name, value } ->
  { name: un HeaderName name, value: un HeaderValue value }

statusCode :: Response -> Int
statusCode (Response answer) = un HTTP.Status (HTTP.status answer)

-- | Where the response came from, after redirects.
url :: Response -> URL
url (Response answer) = URL (un HTTP.URL (HTTP.responseURL answer))

-- | Headers from a record of strings: `makeHeaders { "Content-Type": "application/json" }`.
makeHeaders :: forall row list. RowToList row list => HeaderFields list row => Record row -> Headers
makeHeaders record = Object.fromFoldable (headerFields (Proxy :: Proxy list) record)

class HeaderFields :: RowList Type -> Row Type -> Constraint
class HeaderFields list row where
  headerFields :: Proxy list -> Record row -> Array (String /\ String)

instance HeaderFields RowList.Nil row where
  headerFields _ _ = []

instance
  ( IsSymbol name
  , Row.Cons name String rest row
  , HeaderFields tail row
  ) =>
  HeaderFields (RowList.Cons name String tail) row where
  headerFields _ record = Array.cons field (headerFields (Proxy :: Proxy tail) record)
    where
    field = reflectSymbol (Proxy :: Proxy name) /\ Record.get (Proxy :: Proxy name) record

-- | Decodes a JSON body, failing with a readable message: `fetch url opts >>= json # fromJSON`.
fromJSON :: forall a. ReadForeign a => Aff Foreign -> Aff a
fromJSON body = body >>= Yoga.JSON.read >>> either (throwError <<< error <<< renderErrors) pure

renderErrors :: NonEmptyList ForeignError -> String
renderErrors = intercalateMap "\n" renderHumanError
