// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***

  // TransferableVault Contract 
  error T_ADDRESS_ZERO(); // Address is zero
  error T_INHERITANCE_PERCENTAGE_EXCEEDED(); // Inheritance percentage exceeded
  error T_UNAUTHORIZED(); // Unauthorized
  error T_SUCCEEDED(); // The vault has already been succeeded
  error T_NO_TRANSCENDENCE(); // block.timestamp < proofOfLife
  error T_DYNAMIC_VAULT_ALREADY_EXISTS(); // Dynamic vault already exists
  error T_BACKUP_ADDRESS_IS_OWNER(); // Backup address is owner
  error T_BACKUP_ADDRESS_ALREADY_EXISTS(); // Backup address already exists

  //*** Library Specific Errors ***

  // WadRayMath
  error MATH_MULTIPLICATION_OVERFLOW(); // "The multiplication would result in a overflow";
  error MATH_ADDITION_OVERFLOW(); // "The addition would result in a overflow";
  error MATH_DIVISION_BY_ZERO(); // "The division would result in a divzion by zero";
}
  