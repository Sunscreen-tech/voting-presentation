// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/BinaryVoting.sol";

contract BinaryVotingTest is Test {
   BinaryVoting public votingContract;

   function setUp() public {
      votingContract = new BinaryVoting();
   }

   function test_votingSpfLibraryEncoding() public view {
      bytes32 expected = 0xedd540489dac8e6dab39c9f99aa6a3fc100c96899e772286800b0bd1ac6479ee;
      bytes32 actual = Spf.SpfLibrary.unwrap(votingContract.VOTING_SPF_LIBRARY());
      assertEq(actual, expected, "VOTING_SPF_LIBRARY should match expected bytes32 value");
   }

   function test_votingProgramEncoding() public view {
      bytes32 actual = Spf.SpfProgram.unwrap(votingContract.VOTING_PROGRAM());
      assertEq(actual, bytes32("binary_vote"), "VOTING_PROGRAM should encode 'binary_vote'");
   }
}
