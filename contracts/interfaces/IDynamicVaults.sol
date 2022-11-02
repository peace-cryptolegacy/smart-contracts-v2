// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.8;

import "../lib/Errors.sol";
import "../lib/Types.sol";

/**
 * @title IDynamicVaults
 * @author Peace Foundation
 * @notice Dynamic vaults interface that allows for the transfer of tokens in case of emergency
 */

interface IDynamicVaults {
  event TokenAdded(uint256 dynamicVaultId, address token);
  event BeneficiaryAdded(uint256 dynamicVaultId, address beneficiary);
  event BeneficiaryRemoved(uint256 dynamicVaultId, address beneficiary);
  event ProofOfLifeUpdated(uint256 dynamicVaultId, uint128 timestamp);
  event TestamentSucceeded(uint256 dynamicVaultId);
  event BeneficiaryPercentageUpdated(
    uint256 dynamicVaultId,
    address beneficiaryAddress,
    uint128 newInheritancePercentage
  );
  event accountRepossessed(uint256 dynamicVaultId, address backupAddress);
  event BackupAdded(uint256 dynamicVaultId, address backupAddress);

  /**
   * @notice Creates a dynamic vault
   * @param dynamicVaultId The dynamic vault id
   * @param inactivityMaximum The maximum inactivity time
   * @param beneficiaries The beneficiaries that will inherit the vault
   */
  function createTestament(
    uint256 dynamicVaultId,
    address claimant,
    uint128 inactivityMaximum,
    Types.Beneficiary[] memory beneficiaries
  ) external returns (uint256);

  /**
  * @notice Adds a token to the testament
* @param dynamicVaultId The id of the testament
* @param token The token to be added to the protected tokens list
* @dev there is no function to remove a token since that can be done by decreasing the allowance of this contract. Doing
otherwise would be expensive and unnecessary
*/
  function addToken(uint256 dynamicVaultId, address token) external;

  /**
   * @notice Adds beneficiary to the testament
   * @param dynamicVaultId The id of the testament
   * @param beneficiary The beneficiary to add
   * @dev The addeed percentage of the beneficiaries should not exceed 100%
   * @dev The total maximum percentage should be 100%
   */
  function addBeneficiary(uint256 dynamicVaultId, Types.Beneficiary memory beneficiary) external;

  /**
   * @notice Removes beneficiary from the vault
   * @param dynamicVaultId The id of the testament
   * @param beneficiaryAddress The beneficiary to remove
   */
  function removeBeneficiary(uint256 dynamicVaultId, address beneficiaryAddress) external;

  /**
@notice Updates the inactivity time of the testament
@param dynamicVaultId The id of the testament
@param newInactivityMaximum The new inactivity time
 */
  function updateInactivityMaximum(uint256 dynamicVaultId, uint128 newInactivityMaximum) external;

  /**
   * @notice Updates the proof of life timestamp
   * @param dynamicVaultId The id of the testament
   */
  function signalLife(uint256 dynamicVaultId) external;

  /**
   * @notice Transfers the tokens to the beneficiaries
   * @param dynamicVaultId The id of the testament
   * @dev The function can only be called after the inactivity period is over
   */
  function succeed(uint256 dynamicVaultId) external;

  /**
   * @notice Transfers the protected tokens to the backup address
   * @param dynamicVaultId The id of thedynamicVault
   */
  function repossessAccount(uint256 dynamicVaultId) external;

  /**
   * @notice Adds backup address
   * @param dynamicVaultId The id of the testament
   * @param backupAddress The address to add
   */
  function addBackup(uint256 dynamicVaultId, address backupAddress) external;

  /**
   * @notice Removes backup address
   * @param dynamicVaultId The id of the testament
   * @param backupAddress The address to remove
   */
  function removeBackup(uint256 dynamicVaultId, address backupAddress) external;

  /**
   * @notice Updates the inheritance percentage of a beneficiary
   * @param dynamicVaultId The id of the testament
   * @param beneficiaryAddress The address of the beneficiary
   * @param newInheritancePercentage The new inheritance percentage
   */
  function updateBeneficiaryPercentage(
    uint256 dynamicVaultId,
    address beneficiaryAddress,
    uint128 newInheritancePercentage
  ) external;

  // VIEW METHODS

  /**
   * @notice Returns the testament parameters of a given dynamic vault id
   * @param dynamicVaultId The id of the dynamic vault
   * @return owner The owner of the dynamic vault
   * @return claimant The claimant of the dynamic vault
   * @return tokens The approved tokens
   * @return inactivityMaximum The maximum inactivity time
   * @return proofOfLife The last registred proof of life timestamp
   * @return succeeded Whether the dynamic vault has been succeeded
   */
  function getTestamentParameters(uint256 dynamicVaultId)
    external
    view
    returns (
      address owner,
      address claimant,
      address[] memory tokens,
      uint128 inactivityMaximum,
      uint128 proofOfLife,
      bool succeeded,
      string[] memory beneficiariesNames,
      address[] memory beneficiariesAddresses,
      uint256[] memory beneficiariesInheritancePercentages
    );

  /**
   * @notice Returns the backup addresses of a given dynamic vault id
   * @param dynamicVaultId The id of the dynamic vault
   * @return backupAddresses The backup addresses
   */
  function getBackupAddresses(uint256 dynamicVaultId) external view returns (address[] memory);
}
