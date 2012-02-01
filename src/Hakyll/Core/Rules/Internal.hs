-- | Internal rules module for types which are not exposed to the user
--
{-# LANGUAGE GeneralizedNewtypeDeriving, Rank2Types #-}
module Hakyll.Core.Rules.Internal
    ( CompileRule (..)
    , RuleSet (..)
    , RuleState (..)
    , RuleEnvironment (..)
    , RulesM (..)
    , Rules
    , runRules
    ) where

import Control.Applicative (Applicative)
import Control.Monad.Writer (WriterT, execWriterT)
import Control.Monad.Reader (ReaderT, runReaderT)
import Control.Monad.State (State, evalState)
import Data.Monoid (Monoid, mempty, mappend)
import Data.Set (Set)
import qualified Data.Map as M

import Hakyll.Core.Resource
import Hakyll.Core.Resource.Provider
import Hakyll.Core.Identifier
import Hakyll.Core.Identifier.Pattern
import Hakyll.Core.Compiler.Internal
import Hakyll.Core.Routes
import Hakyll.Core.CompiledItem

-- | Output of a compiler rule
--
-- * The compiler will produce a simple item. This is the most common case.
--
-- * The compiler will produce more compilers. These new compilers need to be
--   added to the runtime if possible, since other items might depend upon them.
--
data CompileRule = CompileRule CompiledItem
                 | MetaCompileRule [(Identifier (), Compiler () CompileRule)]

-- | A collection of rules for the compilation process
--
data RuleSet = RuleSet
    { -- | Routes used in the compilation structure
      rulesRoutes    :: Routes
    , -- | Compilation rules
      rulesCompilers :: [(Identifier (), Compiler () CompileRule)]
    , -- | A list of the used resources
      rulesResources :: Set Resource
    }

instance Monoid RuleSet where
    mempty = RuleSet mempty mempty mempty
    mappend (RuleSet r1 c1 s1) (RuleSet r2 c2 s2) =
        RuleSet (mappend r1 r2) (mappend c1 c2) (mappend s1 s2)

-- | Rule state
--
data RuleState = RuleState
    { rulesNextIdentifier :: Int
    } deriving (Show)

-- | Rule environment
--
data RuleEnvironment = RuleEnvironment
    { rulesResourceProvider :: ResourceProvider
    , rulesPattern          :: forall a. Pattern a
    , rulesGroup            :: Maybe String
    }

-- | The monad used to compose rules
--
newtype RulesM a = RulesM
    { unRulesM :: ReaderT RuleEnvironment (WriterT RuleSet (State RuleState)) a
    } deriving (Monad, Functor, Applicative)

-- | Simplification of the RulesM type; usually, it will not return any
-- result.
--
type Rules = RulesM ()

-- | Run a Rules monad, resulting in a 'RuleSet'
--
runRules :: RulesM a -> ResourceProvider -> RuleSet
runRules rules provider = nubCompilers $
    evalState (execWriterT $ runReaderT (unRulesM rules) env) state
  where
    state = RuleState {rulesNextIdentifier = 0}
    env = RuleEnvironment { rulesResourceProvider = provider
                          , rulesPattern          = mempty
                          , rulesGroup            = Nothing
                          }

-- | Remove duplicate compilers from the 'RuleSet'. When two compilers match an
-- item, we prefer the first one
--
nubCompilers :: RuleSet -> RuleSet
nubCompilers set = set { rulesCompilers = nubCompilers' (rulesCompilers set) }
  where
    nubCompilers' = M.toList . M.fromListWith (flip const)
