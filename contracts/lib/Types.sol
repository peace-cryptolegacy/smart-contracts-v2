// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Types {
  struct Beneficiary{
    string name;
    address payable address_;
    uint128 inheritancePercentage;
  }

  struct Testament{
    address owner;
    address claimant;
    uint128 inactivityMaximum;
    uint128 proofOfLife;
    bool succeeded;
    Beneficiary[] beneficiaries;
    address[] tokens;
  }

  struct DynamicVault {
    Testament testament;
    address[] backupAddresses;
    uint128 ESTABLISHMENT_FEE;
  }
}
