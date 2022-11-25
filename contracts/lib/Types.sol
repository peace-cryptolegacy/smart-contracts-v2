// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Types {
  struct Beneficiary {
    string name;
    address payable address_;
    uint128 inheritancePercentage;
  }

  struct Testament {
    address claimant;
    uint128 inactivityMaximum;
    uint128 proofOfLife;
    bool succeeded;
    Beneficiary[] beneficiaries;
    address[] tokens;
  }

  /*
  The establishment fee rate is stored in each testament to allow for the possibility of changing the fee rate in the
  future. If it wasn't stored this way, the chaning the fee rate would unfairly affect the vaults that were created
  before the change.
   */
  struct DynamicVault {
    Testament testament;
    address[] backupAddresses;
    uint128 ESTABLISHMENT_FEE_RATE;
  }
}
