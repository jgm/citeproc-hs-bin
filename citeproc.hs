{-# LANGUAGE DeriveDataTypeable, ScopedTypeVariables #-}
import Text.CSL
import System.Environment
import Text.JSON
import Text.JSON.Generic
import Text.JSON.Types (get_field)
import Text.Pandoc.Definition
import Text.Pandoc.Generic
import qualified Data.Map as M
import Control.Monad (unless)
import System.Exit
import System.IO
import Data.Maybe (fromMaybe)

instance JSON Cite where
  showJSON = toJSON
  readJSON (JSObject o) =
        Ok $ emptyCite{ citeId = case get_field o "id" of
                                       Just (JSString x) -> fromJSString x
                                       _  -> error $ "Missing id field"
                      , citePrefix = case get_field o "prefix" of
                                       Just x@(JSArray _) | Ok y <- readJSON x -> PandocText y
                                       Just (JSString x) -> PlainText $ fromJSString x
                                       _ -> PandocText []
                      , citeSuffix = case get_field o "suffix" of
                                       Just x@(JSArray _) | Ok y <- readJSON x -> PandocText y
                                       Just (JSString x) -> PlainText $ fromJSString x
                                       _ -> PandocText []
                      , citeLabel = case get_field o "label" of
                                       Just (JSString x) -> fromJSString x
                                       _ -> ""
                      , citeLocator = case get_field o "locator" of
                                       Just (JSString x) -> fromJSString x
                                       _ -> ""
                      , citeNoteNumber = case get_field o "note_number" of
                                       Just (JSString x) -> fromJSString x
                                       _ -> ""
                      , citePosition = case get_field o "position" of
                                       Just (JSString x) -> fromJSString x
                                       _ -> ""
                      , nearNote = case get_field o "near_note" of
                                       Just (JSBool True) -> True
                                       _ -> False
                      , suppressAuthor = case get_field o "suppress_author" of
                                       Just (JSBool True) -> True
                                       _ -> False
                      , authorInText = case get_field o "author_in_text" of
                                       Just (JSBool True) -> True
                                       _ -> False
                      }
  readJSON x = fromJSON x

jsString :: String -> JSValue
jsString = JSString . toJSString

instance JSON Inline where
  showJSON (Str s) = jsString s
  showJSON Space   = jsString " "
  showJSON (Emph ils) | xs <- showJSON ils = JSArray [jsString "EMPH", xs]
  showJSON (Strong ils) | xs <- showJSON ils = JSArray [jsString "STRONG", xs]
  showJSON (Superscript ils) | xs <- showJSON ils = JSArray [jsString "SUPERSCRIPT", xs]
  showJSON (Subscript ils) | xs <- showJSON ils = JSArray [jsString "SUBSCRIPT", xs]
  showJSON (SmallCaps ils) | xs <- showJSON ils = JSArray [jsString "SMALLCAPS", xs]
  showJSON (Strikeout ils) | xs <- showJSON ils = JSArray [jsString "STRIKEOUT", xs]
  showJSON (EmDash) = jsString "—"
  showJSON (EnDash) = jsString "–"
  showJSON (Ellipses) = jsString "…"
  showJSON x = error ("Need showJSON instance for: " ++ show x)
  readJSON (JSArray (JSString ty : xs)) =
    case fromJSString ty of
      "EMPH"        | Ok ys <- mapM readJSON xs -> Ok $ Emph ys
      "STRONG"      | Ok ys <- mapM readJSON xs -> Ok $ Strong ys
      "SUPERSCRIPT" | Ok ys <- mapM readJSON xs -> Ok $ Subscript ys
      "SUBSCRIPT"   | Ok ys <- mapM readJSON xs -> Ok $ Subscript ys
      "SMALLCAPS"   | Ok ys <- mapM readJSON xs -> Ok $ SmallCaps ys
      "STRIKEOUT"   | Ok ys <- mapM readJSON xs -> Ok $ Strikeout ys
      _ -> error "unknown case"
  readJSON (JSString s) | fromJSString s == " " = Ok Space
  readJSON (JSString x) = Ok $ Str $ fromJSString x
  readJSON x = error $ "Need readJSON instance for: " ++ show x

data CiteprocResult = CiteprocResult { cites  :: [[Inline]]
                                     , bib    :: [[Inline]]
                                     , citationType :: String
                                     } deriving (Show, Typeable, Data)

instance JSON CiteprocResult where
  showJSON res = JSObject $
                 toJSObject [("citations", showJSON $ cites res)
                            ,("bibliography", showJSON $ bib res)
                            ,("type", showJSON $ citationType res)
                            ]
  readJSON = fromJSON

normalize :: [Inline] -> [Inline]
normalize = topDown consolidateInlines

consolidateInlines :: [Inline] -> [Inline]
consolidateInlines (Str x : Str y : zs) = consolidateInlines (Str (x ++ y) : zs)
consolidateInlines (Str x : Space : zs) = consolidateInlines (Str (x ++ " ") : zs)
consolidateInlines (x : xs) = x : consolidateInlines xs
consolidateInlines [] = []

main :: IO ()
main = do
  args <- getArgs
  progname <- getProgName
  unless (length args >= 2) $ do
    hPutStrLn stderr $ "Usage:  " ++ progname ++ " CSLFILE BIBFILE.."
    exitWith (ExitFailure 1)
  let (cslfile : bibfiles) = args
  sty <- readCSLFile cslfile
  let citationType = styleClass sty  -- "note" or "in-text"
  refs <- concat `fmap` mapM readBiblioFile bibfiles
  res <- decode `fmap` getContents
  let Ok cites' = res
  -- for debugging:
  -- hPutStrLn stderr $ show cites'
  let bibdata = citeproc procOpts sty refs cites'
  let citeprocres = CiteprocResult {
                          cites = map (normalize . renderPandoc sty) $ citations bibdata
                        , bib   = map (normalize . renderPandoc sty) $ bibliography bibdata
                        , citationType = citationType
                        }
  putStrLn $ encode citeprocres
