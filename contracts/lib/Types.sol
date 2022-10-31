// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Types {
  struct Beneficiary{
    string name;
    address payable address_;
    uint256 inheritancePercentage;
  }

  struct TestamentCreationParameters{
    address owner;
    address claimant;
    uint128 inactivityMaximum;
    uint128 proofOfLife;
    bool succeeded;
  }

  struct Testament{
    TestamentCreationParameters creationParameters;
    Beneficiary[] beneficiaries;
    address[] tokens;
  }

  struct DynamicVault {
    Testament testament;
    address[] backupAddresses;
  }
}
