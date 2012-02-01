-- | A module dealing with pandoc file extensions and associated file types
--
module Hakyll.Web.Pandoc.FileType
    ( FileType (..)
    , fileType
    , getFileType
    ) where

import System.FilePath (takeExtension)
import Control.Arrow ((>>^))

import Hakyll.Core.Identifier
import Hakyll.Core.Compiler

-- | Datatype to represent the different file types Hakyll can deal with by
-- default
--
data FileType
    = Binary
    | Css
    | Html
    | LaTeX
    | LiterateHaskell FileType
    | Markdown
    | OrgMode
    | PlainText
    | Rst
    deriving (Eq, Ord, Show, Read)

-- | Get the file type for a certain file. The type is determined by extension.
--
fileType :: FilePath -> FileType
fileType = fileType' . takeExtension
  where
    fileType' ".css"      = Css
    fileType' ".htm"      = Html
    fileType' ".html"     = Html
    fileType' ".lhs"      = LiterateHaskell Markdown
    fileType' ".markdown" = Markdown
    fileType' ".md"       = Markdown
    fileType' ".mdn"      = Markdown
    fileType' ".mdown"    = Markdown
    fileType' ".mdwn"     = Markdown
    fileType' ".mkd"      = Markdown
    fileType' ".mkdwn"    = Markdown
    fileType' ".org"      = OrgMode
    fileType' ".page"     = Markdown
    fileType' ".rst"      = Rst
    fileType' ".tex"      = LaTeX
    fileType' ".text"     = PlainText
    fileType' ".txt"      = PlainText
    fileType' _           = Binary  -- Treat unknown files as binary

-- | Get the file type for the current file
--
getFileType :: Compiler a FileType
getFileType = getIdentifier >>^ fileType . toFilePath
