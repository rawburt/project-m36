import Test.HUnit
import RelationType
import Relation
import RelationTuple
import RelationTupleSet
import qualified Data.Set as S
import qualified Data.Map as M
import qualified Data.HashSet as HS
import System.Exit
import Control.Monad


testList = TestList [testRelation relationTrue, testRelation relationFalse,
                     testRename1, testRename2]
main = do 
  counts <- runTestTT testList
  if errors counts + failures counts > 0 then exitFailure else exitSuccess

testRelation :: Relation -> Test
testRelation rel = TestCase $ assertEqual "nope" relationValidation (Right rel)
  where
    relationValidation = validateRelation rel

-- run common relation checks
validateRelation :: Relation -> Either RelationalError Relation
validateRelation rel = do
  validateAttrNamesMatchTupleAttrNames rel
  validateAttrTypesMatchTupleAttrTypes rel
  
validateAttrNamesMatchTupleAttrNames :: Relation -> Either RelationalError Relation
validateAttrNamesMatchTupleAttrNames rel@(Relation _ tupMapSet) 
  | HS.null invalidSet = Right rel
  | otherwise = Left (RelationalError 1 "Tuple attributes do not match relation attributes")
  where
    nameCheck (RelationTuple tupMap) = attributeNames rel == M.keysSet tupMap
    relAttrNames = attributeNames rel
    invalidSet =  HS.filter (not . nameCheck) tupMapSet
    
    
validateAttrTypesMatchTupleAttrTypes :: Relation -> Either RelationalError Relation
validateAttrTypesMatchTupleAttrTypes rel@(Relation _ tupMapSet) 
   | HS.null invalidSet = Right rel
   | otherwise = Left (RelationalError 1 "Tuple types do not match relation attribute types")
  where
    tupleTypeCheck (RelationTuple tupMap) = M.null $ M.filterWithKey attrTypeCheck tupMap
    attrTypeCheck attrName atomValue = case attributeTypeForName attrName rel of
      Just t -> atomValueType atomValue == t
      _ -> False
    invalidSet = HS.filter (not . tupleTypeCheck) tupMapSet
    
simpleRel = case mkRelation attrs tupleSet of
  Right rel -> rel
  Left err -> undefined
  where
    attrs = M.fromList [("a", Attribute "a" StringAtomType), ("b", Attribute "b" StringAtomType)]
    tupleSet = HS.fromList $ mkRelationTuples attrs [
      M.fromList [("a", StringAtom "spam"), ("b", StringAtom "spam2")]
      ]

--rename tests
testRename1 :: Test
testRename1 = TestCase $ assertEqual "attribute invalid" (rename "a" "b" relationTrue) (Left $ RelationalError 1 "No such attribute")

testRename2 :: Test
testRename2 = TestCase $ assertEqual "attribute in use" (rename "b" "a" simpleRel) (Left $ RelationalError 1 "Attribute \"a\" already in use.")

--mkRelation tests
--test tupleset key mismatch failure
testMkRelation1 :: Test
testMkRelation1 = TestCase $ assertEqual "key mismatch" (mkRelation testAttrs testTupSet) (Left $ RelationalError 1 "Tuple values not of the same type for same keys")
  where
    testAttrs = M.singleton "a" (Attribute "a" StringAtomType)
    testTupSet = HS.fromList [(RelationTuple (M.singleton "a" $ StringAtom "v")),
                               RelationTuple (M.singleton "a" $ IntAtom 2)]
