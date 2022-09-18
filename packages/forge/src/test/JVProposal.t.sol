// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { DSTest } from "ds-test/test.sol";
import { Utilities } from "./utils/Utilities.sol";
import { console } from "./utils/Console.sol";
import { Vm } from "forge-std/Vm.sol";
import { JVProposalFactory } from "../JVProposalFactory.sol";
import { JVProposal } from "../JVProposal.sol";
import "../interfaces/IJVProposalFactory.sol";
import "../interfaces/IERC20.sol";
import "./utils/MockERC20.sol";
import "./Setup.sol";

contract JVProposalFactoryTest is DSTest, Setup {
  function _proposal() internal returns (IJVProposal) {
    IJVProposalFactory.JVTokenConfig memory tokenConfig = jvTokenConfig;
    uint256 feeTier = 3000;
    IJVProposal proposal = new JVProposal(daoConfigs, tokenConfig, feeTier);
    return proposal;
  }

  function test_construction() public {
    IJVProposal proposal = _proposal();
    assertEq(address(proposal), 0xf5a2fE45F4f1308502b1C136b9EF8af136141382);
  }

  function test_fee_tier() public {
    assertEq(_proposal().feeTier(), 3000);
  }

  function test_execute() public {
    IJVProposal proposal = _proposal();
    _depositTargetAmounts(proposal);

    (
      address jvToken,
      address[] memory uniPools,
      address[] memory arrakisVaults
    ) = proposal.execute();

    _printBalances(proposal, uniPools, arrakisVaults);
    assertEq(jvToken, 0xc84225f52C1cd66Af2cC7a5497A715f79BaFa7ee);
    assertEq(uniPools[0], 0xaF30631eF1dA8A9258285848c640d0c73AB19195);
    assertEq(uniPools[1], 0xC75aCb29471B496726E45e0Db8EAB8Aa92A35C1f);
    assertEq(arrakisVaults[0], 0xf62FAb0b5A8255Eb1976cA9771Db23D55978d311);
    assertEq(arrakisVaults[1], 0xE0A34a39c694fFc1beCEcf5bd948e534931C1105);
    assertEq(
      IERC20(arrakisVaults[0]).balanceOf(daoConfigs[0].treasuryAddress),
      50646.022323343517519166 ether
    );
    assertEq(
      IERC20(arrakisVaults[1]).balanceOf(daoConfigs[1].treasuryAddress),
      50646.022323343517519166 ether
    );
  }

  function _printBalances(
    IJVProposal proposal,
    address[] memory uniPools,
    address[] memory arrakisVaults
  ) internal {
    address jvToken = address(proposal.jvToken());
    console.log(IERC20(jvToken).totalSupply(), "total supply of JV token");
    console.log(
      IERC20(jvToken).balanceOf(address(proposal)),
      "proposal jv balance"
    );
    console.log(
      IERC20(daoConfigs[0].tokenAddress).balanceOf(address(proposal)),
      "proposal foo balance"
    );
    console.log(
      IERC20(jvToken).balanceOf(address(uniPools[0])),
      "unipool0 jv balance"
    );
    console.log(
      IERC20(daoConfigs[0].tokenAddress).balanceOf(address(uniPools[0])),
      "unipool0 foo balance"
    );


    console.log(
      IERC20(jvToken).balanceOf(address(uniPools[1])),
      "unipool1 jv balance"
    );

    console.log(
      IERC20(daoConfigs[1].tokenAddress).balanceOf(address(uniPools[1])),
      "unipool1 bar balance"
    );

    console.log(
      IERC20(daoConfigs[0].tokenAddress).balanceOf(address(arrakisVaults[0])),
      "arrakisVault0 foo balance"
    );
    console.log(
      IERC20(daoConfigs[1].tokenAddress).balanceOf(address(arrakisVaults[0])),
      "arrakisVault0 bar balance"
    );
    console.log(
      IERC20(jvToken).balanceOf(address(arrakisVaults[0])),
      "arrakisVault0 jv balance"
    );
    console.log(
      IERC20(daoConfigs[0].tokenAddress).balanceOf(address(arrakisVaults[1])),
      "arrakisVault1 foo balance"
    );
    console.log(
      IERC20(daoConfigs[1].tokenAddress).balanceOf(address(arrakisVaults[1])),
      "arrakisVault1 bar balance"
    );

    console.log(
      IERC20(jvToken).balanceOf(address(arrakisVaults[1])),
      "arrakisVault1 jv balance"
    );
  }

  function _depositTargetAmounts(IJVProposal proposal) internal {
    IERC20 token0 = IERC20(address(tokens[0]));
    IERC20 token1 = IERC20(address(tokens[1]));
    vm.startPrank(alice);
    token0.approve(address(proposal), 100_000 ether);
    token1.approve(address(proposal), 100_000 ether);
    proposal.deposit(token0, 100_000 ether);
    proposal.deposit(token1, 100_000 ether);
  }

  function test_deposit() public {
    IERC20 token = IERC20(address(tokens[0]));
    IJVProposal proposal = _proposal();
    vm.startPrank(alice);
    token.approve(address(proposal), 100_000 ether);
    proposal.deposit(token, 100_000 ether);

    assertEq(proposal.userTokenDeposits(alice, token), 100_000 ether);
    assertEq(proposal.totalDeposits(address(token)), 100_000 ether);
    assertEq(token.balanceOf(address(proposal)), 100_000 ether);
  }

  function test_withdraw() public {
    IERC20 token = IERC20(address(tokens[0]));
    IJVProposal proposal = _proposal();
    vm.startPrank(alice);
    token.approve(address(proposal), 100_000 ether);
    proposal.deposit(token, 100_000 ether);
    proposal.withdraw(token, 100_000 ether);

    assertEq(proposal.userTokenDeposits(alice, token), 0);
  }
}
