// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Types {
/* The protocol's fee rates are stored in each testament so if they change, they will not affect
 previous agreements */
  struct Beneficiary{
    string name;
    address payable address_;
    uint256 inheritancePercentage;
  }

  struct Parameters{
    address owner;
    address claimant;
    uint128 inactivityMaximum;
    uint128 proofOfLife;
    address[] tokens;
    address[] backupAddresses;
    bool succeeded;
  }

  struct DynamicVault{
    Parameters parameters;
    Beneficiary[] beneficiaries;
  }
}
