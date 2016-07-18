module Main where

import Data.List
import Data.List.Utils

-- Very ad-hoc solution
cropChapter :: String -> String
cropChapter
  = reverse
  . drop (length endMarker)
  . dropWhileList (not . (reverse endMarker `isPrefixOf`))
  . reverse
  . dropWhileList (not . (startMarker `isPrefixOf`))

  where
    startMarker = "<h2>"
    endMarker   = "<a href=\"https://twitter.com/BartoszMilewski\""

pairs :: [(String, String)]
pairs =
  [ ("<p>", "")
  , ("</p>", "\n")
  , ("<h2>", "## ")
  , ("</h2>", "\n")
  , ("<h3>", "### ")
  , ("</h3>", "\n")
  , ("<code>", "`")
  , ("</code>", "`")
  , ("<pre>", "```\n")
  , ("</pre>", "\n```\n")
  , ("&gt;", ">")
  , ("&lt;", "<")
  , ("&amp;", "&")
  , ("<b>", "**")
  , ("</b>", "**")
  , ("<strong>", "**")
  , ("</strong>", "**")
  , ("<i>", "*")
  , ("</i>", "*")
  , ("<em>", "*")
  , ("</em>", "*")
  , ("&#8217;", "'")
  ]

html2md :: String -> String
html2md html = foldr (uncurry replace) html pairs

main :: IO ()
main = do
  html <- getContents
  let chapter = cropChapter html
  let md = html2md chapter
  putStrLn md
