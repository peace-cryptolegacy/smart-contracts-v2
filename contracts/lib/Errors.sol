// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***

  // TransferableVault Contract 
  error T_ADDRESS_ZERO(); // Address is zero
  error T_INHERITANCE_PERCENTAGE_EXCEEDED(); // Inheritance percentage exceeded
  error T_UNAUTHORIZED(); // Unauthorized
  error T_SUCCEEDED(); // The vault has already been succeeded
  error T_NO_TRANSCENDANCE(); // block.timestamp < proofOfLife
  error T_DYNAMIC_VAULT_ALREADY_EXISTS(); // Dynamic vault already exists
}
  