#include <gtest/gtest.h>

#include "grammar_guard.hpp"
#include "jackdaw.h"

TEST(GrammarGuard, RefusesReversedRepetitions) {
  EXPECT_TRUE(jackdaw::grammar_problem(R"(root ::= "a"{2,1})"));
  EXPECT_TRUE(jackdaw::grammar_problem("root ::= item (\",\" item){8, 3}\nitem ::= [a-z]"));
  EXPECT_TRUE(jackdaw::grammar_problem("root ::= \"a\"{ 99999999999999999999999 , 1 }"));
  EXPECT_TRUE(jackdaw::grammar_problem("root ::= (\"a\"{5,\n0})"));
  EXPECT_TRUE(jackdaw::grammar_problem("root ::= (\"a\"{5 # note\n,0})"));
  EXPECT_TRUE(jackdaw::grammar_problem("root ::= (\"a\"{\r\n5,\r\n0})"));
}

TEST(GrammarGuard, AcceptsValidRepetitionsAndIgnoresQuotedBraces) {
  EXPECT_FALSE(jackdaw::grammar_problem(R"(root ::= "a"{1,2} "b"{3} "c"{2,} "d"{0,0})"));
  EXPECT_FALSE(jackdaw::grammar_problem(R"(root ::= "{9,1}" [{9,1}] # {9,1})"));
  EXPECT_FALSE(jackdaw::grammar_problem(R"(root ::= "\"{9,1}" "a")"));
  EXPECT_FALSE(jackdaw::grammar_problem(""));
  EXPECT_FALSE(jackdaw::grammar_problem("root ::= x{"));
}
