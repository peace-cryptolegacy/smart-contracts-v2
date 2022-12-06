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
  event TokenAdded(address owner, address token);
  event BeneficiaryAdded(address owner, address beneficiary);
  event BeneficiaryRemoved(address owner, address beneficiary);
  event ProofOfLifeUpdated(address owner, uint128 timestamp);
  event TestamentSucceeded(address owner);
  event BeneficiaryPercentageUpdated(address owner, address beneficiaryAddress, uint128 newInheritancePercentage);
  event accountRepossessed(address owner, address backupAddress);
  event BackupAdded(address owner, address backupAddress);
  event EstablishmentFeeRateUpdated(uint128 newEstablishmentFeeRate);
  event BeneficiariesUpdated(address owner, Types.Beneficiary[] beneficiaries);

  /**
   * @notice Creates a dynamic vault
   * @param inactivityMaximum The maximum inactivity time
   * @param beneficiaries The beneficiaries that will inherit the vault
   */
  function createTestament(
    address claimant,
    uint128 inactivityMaximum,
    Types.Beneficiary[] memory beneficiaries
  ) external;

  /**
  * @notice Adds a token to the testament
* @param token The token to be added to the protected tokens list
* @dev there is no function to remove a token since that can be done by decreasing the allowance of this contract. Doing
otherwise would be expensive and unnecessary
*/
  function addToken(address token) external;

  /**
   * @notice Adds beneficiary to the testament
   * @param beneficiary The beneficiary to add
   * @dev The addeed percentage of the beneficiaries should not exceed 100%
   * @dev The total maximum percentage should be 100%
   */
  function addBeneficiary(Types.Beneficiary memory beneficiary) external;

  /**
   * @notice Removes beneficiary from the vault
   * @param beneficiaryAddress The beneficiary to remove
   */
  function removeBeneficiary(address beneficiaryAddress) external;

  /**
@notice Updates the inactivity time of the testament
@param newInactivityMaximum The new inactivity time
 */
  function updateInactivityMaximum(uint128 newInactivityMaximum) external;

  /**
   * @notice Updates the proof of life timestamp
   */
  function signalLife() external;

  /**
   * @notice Transfers the tokens to the beneficiaries
   * @param owner The owner of the dynamic vault
   * @dev The function can only be called after the inactivity period is over
   */
  function succeed(address owner) external;

  /**
   * @notice Transfers the protected tokens to the backup address
   * @param owner The owner of the dynamic vault
   */
  function repossessAccount(address owner) external;

  /**
   * @notice Adds backup address
   * @param backupAddress The address to add
   */
  function addBackup(address backupAddress) external;

  /**
   * @notice Removes backup address
   * @param backupAddress The address to remove
   */
  function removeBackup(address backupAddress) external;

  /**
   * @notice Updates the inheritance percentage of a beneficiary
   * @param names The names of the beneficiaries
   * @param addresses The addresses of the beneficiary
   * @param newInheritancePercentages The new inheritance percentages
   */
  function updateBeneficiaries(
    string[] memory names,
    address[] calldata addresses,
    uint128[] calldata newInheritancePercentages
  ) external;

  // Methods callable only by the owner of the contract

  /**
   * @notice Sets the global establishment fee rate
   **/
  function updateEstablishmentFeeRate(uint128 newEstablishmentFeeRate) external;

  /**
   * @notice Stops all actions on all vaults
   */
  function pause() external;

  /**
   * @notice Unpause vaults. Makes actions available again on all vaults
   **/
  function unpause() external;

  // VIEW METHODS

  /**
   * @notice Returns the testament parameters of a given dynamic vault id
   * @param owner The owner of the dynamic vault
   * @return claimant The claimant of the dynamic vault
   * @return tokens The approved tokens
   * @return inactivityMaximum The maximum inactivity time
   * @return proofOfLife The last registred proof of life timestamp
   * @return succeeded Whether the dynamic vault has been succeeded
   */
  function getTestamentParameters(
    address owner
  )
    external
    view
    returns (
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
   * @param owner The owner of the dynamic vault
   * @return backupAddresses The backup addresses
   */
  function getBackupAddresses(address owner) external view returns (address[] memory);
}
