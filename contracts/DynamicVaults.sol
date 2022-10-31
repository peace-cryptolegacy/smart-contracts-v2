// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./lib/Errors.sol";
import "./lib/Types.sol";

import "./interfaces/IDynamicVaults.sol";

/**
 * @title DynamicVaults
 * @author Peace Foundation
 * @notice Dyanmic vaults contract that allows for the transfer of tokens in case of emergency
 */

contract DynamicVaults is IDynamicVaults {
  using SafeERC20 for IERC20;

  uint128 internal establishmentFee = 25000000000000000; // 0.25%

  mapping(uint256 => Types.DynamicVault) public dynamicVaults;

  modifier onlyOnTRANSCENDENCE(Types.DynamicVault storage dynamicVault) {
    if (
      block.timestamp <
      dynamicVault.testament.creationParameters.proofOfLife +
        dynamicVault.testament.creationParameters.inactivityMaximum
    ) {
      revert Errors.T_NO_TRANSCENDENCE();
    }
    _;
  }

  modifier onlyUnsucceeded(Types.DynamicVault storage dynamicVault) {
    if (dynamicVault.testament.creationParameters.succeeded) {
      revert Errors.T_SUCCEEDED();
    }
    _;
  }

  modifier onlyOwner(Types.DynamicVault storage dynamicVault) {
    if (msg.sender != dynamicVault.testament.creationParameters.owner) {
      revert Errors.T_UNAUTHORIZED();
    }
    _;
  }

  modifier onlyClaimant(Types.DynamicVault storage dynamicVault) {
    if (msg.sender != dynamicVault.testament.creationParameters.claimant) {
      revert Errors.T_UNAUTHORIZED();
    }
    _;
  }

  modifier onlyBackup(Types.DynamicVault storage dynamicVault) {
    bool authorized;
    for (uint256 i = 0; i < dynamicVault.backupAddresses.length; i++) {
      if (dynamicVault.backupAddresses[i] == msg.sender) {
        authorized = true;
        break;
      }
    }

      if (!authorized) {
        revert Errors.T_UNAUTHORIZED();
      }
      _;
  }

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
  ) external returns (uint256) {
    if (dynamicVaults[dynamicVaultId].testament.creationParameters.owner != address(0)) {
      revert Errors.T_DYNAMIC_VAULT_ALREADY_EXISTS();
    }

    if (claimant == address(0)) {
      revert Errors.T_ADDRESS_ZERO();
    }

    dynamicVaults[dynamicVaultId].testament.creationParameters = Types.TestamentCreationParameters({
      owner: msg.sender,
      claimant: claimant,
      inactivityMaximum: inactivityMaximum,
      proofOfLife: uint128(block.timestamp),
      succeeded: false
    });

    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      if (beneficiaries[i].address_ == address(0)) {
        revert Errors.T_ADDRESS_ZERO();
      }
      dynamicVault.testament.beneficiaries.push(beneficiaries[i]);
    }

    return dynamicVaultId;
  }

  /**
   * @notice Adds a token to thedynamicVault 
   * @param dynamicVaultId The id of thedynamicVault 
   * @param token The token to be added to the protected tokens list
   * @dev there is no function to remove a token since that can be done by decreasing the allowance of this contract. Doing
   otherwise would be expensive and unnecessary
  */
  function addToken(uint256 dynamicVaultId, address token) external onlyOwner(dynamicVaults[dynamicVaultId]) {
    dynamicVaults[dynamicVaultId].testament.tokens.push(token);

    emit TokenAdded(dynamicVaultId, token);
  }

  /**
   * @notice Adds beneficiary to thedynamicVault
   * @param dynamicVaultId The id of thedynamicVault
   * @param beneficiary The beneficiary to add
   * @dev The addeed percentage of the beneficiaries should not exceed 100%
   * @dev The total maximum percentage should be 100%
   */
  function addBeneficiary(uint256 dynamicVaultId, Types.Beneficiary memory beneficiary) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    uint256 percentage;
    percentage += beneficiary.inheritancePercentage;

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      percentage += dynamicVault.testament.beneficiaries[i].inheritancePercentage;
    }

    if (percentage > 100) {
      revert Errors.T_INHERITANCE_PERCENTAGE_EXCEEDED();
    }

    dynamicVault.testament.beneficiaries.push(beneficiary);

    emit BeneficiaryAdded(dynamicVaultId, beneficiary.address_);
  }

  /**
   * @notice Removes beneficiary from the vault
   * @param dynamicVaultId The id of thedynamicVault
   * @param address_ The beneficiary to remove
   */
  function removeBeneficiary(uint256 dynamicVaultId, address address_) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      if (dynamicVault.testament.beneficiaries[i].address_ == address_) {
        dynamicVault.testament.beneficiaries[i] = dynamicVault.testament.beneficiaries[
          dynamicVault.testament.beneficiaries.length - 1
        ];
        dynamicVault.testament.beneficiaries.pop();
      }
    }

    emit BeneficiaryRemoved(dynamicVaultId, address_);
  }

  /**
    @notice Updates the inactivity time of thedynamicVault 
    @param dynamicVaultId The id of thedynamicVault 
    @param newInactivityMaximum The new inactivity time
  */
  function updateInactivityMaximum(uint256 dynamicVaultId, uint128 newInactivityMaximum)
    external
    onlyOwner(dynamicVaults[dynamicVaultId])
  {
    dynamicVaults[dynamicVaultId].testament.creationParameters.inactivityMaximum = newInactivityMaximum;
  }

  /**
   * @notice Updates the proof of life timestamp
   * @param dynamicVaultId The id of thedynamicVault
   */
  function signalLife(uint256 dynamicVaultId) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    uint128 timestampRef = uint128(block.timestamp);

    dynamicVault.testament.creationParameters.proofOfLife = timestampRef;

    emit ProofOfLifeUpdated(dynamicVaultId, timestampRef);
  }

  /**
   * @notice Transfers the tokens to the beneficiaries
   * @param dynamicVaultId The id of thedynamicVault
   * @dev The function can only be called after the inactivity period is over
   */
  function succeed(uint256 dynamicVaultId)
    external
    onlyClaimant(dynamicVaults[dynamicVaultId])
    onlyOnTRANSCENDENCE(dynamicVaults[dynamicVaultId])
    onlyUnsucceeded(dynamicVaults[dynamicVaultId])
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];
    dynamicVault.testament.creationParameters.succeeded = true;

    for (uint256 i = 0; i < dynamicVault.testament.tokens.length; i++) {
      IERC20 token = IERC20(dynamicVault.testament.tokens[i]);
      uint256 allowedBalance = token.allowance(dynamicVault.testament.creationParameters.owner, address(this));

      dynamicVault.testament.creationParameters.succeeded = true;

      for (uint256 n = 0; n < dynamicVault.testament.beneficiaries.length; n++) {
        uint256 amount = (allowedBalance * dynamicVault.testament.beneficiaries[n].inheritancePercentage) / 100;
        token.safeTransferFrom(
          dynamicVault.testament.creationParameters.owner,
          dynamicVault.testament.beneficiaries[n].address_,
          amount
        );
      }
    }

    emit TestamentSucceeded(dynamicVaultId);
  }

  /**
   * @notice Transfers the protected tokens to the backup address
   * @param dynamicVaultId The id of thedynamicVault
   */
  function repossessAccount(uint256 dynamicVaultId) external onlyBackup(dynamicVaults[dynamicVaultId]) {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];
    for (uint256 i = 0; i < dynamicVault.testament.tokens.length; i++) {
      IERC20 token = IERC20(dynamicVault.testament.tokens[i]);
      uint256 allowedBalance = token.allowance(dynamicVault.testament.creationParameters.owner, address(this));
      token.safeTransferFrom(dynamicVault.testament.creationParameters.owner, msg.sender, allowedBalance);
    }

    emit accountRepossessed(dynamicVaultId, msg.sender);
  }

  /**
   * @notice Adds backup address
   * @param dynamicVaultId The id of thedynamicVault
   * @param backupAddress The address to add
   */
  function addBackup(uint256 dynamicVaultId, address backupAddress) external onlyOwner(dynamicVaults[dynamicVaultId]) {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    if (backupAddress == address(0)) {
      revert Errors.T_ADDRESS_ZERO();
    }

    if (backupAddress == msg.sender) {
      revert Errors.T_BACKUP_ADDRESS_IS_OWNER();
    }

    for (uint256 i = 0; i < dynamicVault.backupAddresses.length; i++) {
      if (dynamicVault.backupAddresses[i] == backupAddress) {
        revert Errors.T_BACKUP_ADDRESS_ALREADY_EXISTS();
      }
    }

    dynamicVault.backupAddresses.push(backupAddress);

    emit BackupAdded(dynamicVaultId, backupAddress);
  }

  /**
   * @notice Removes backup address
   * @param dynamicVaultId The id of thedynamicVault
   * @param backupAddress The address to remove
   */
  function removeBackup(uint256 dynamicVaultId, address backupAddress)
    external
    onlyOwner(dynamicVaults[dynamicVaultId])
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.backupAddresses.length; i++) {
      if (dynamicVault.backupAddresses[i] == backupAddress) {
        dynamicVault.backupAddresses[i] = dynamicVault.backupAddresses[dynamicVault.backupAddresses.length - 1];
        dynamicVault.backupAddresses.pop();
      }
    }
  }

  /**
   * @notice Updates the inheritance percentage of a beneficiary
   * @param dynamicVaultId The id of thedynamicVault
   * @param address_ The address of the beneficiary
   * @param newInheritancePercentage The new inheritance percentage
   */
  function updateBeneficiaryPercentage(
    uint256 dynamicVaultId,
    address address_,
    uint128 newInheritancePercentage
  ) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      if (dynamicVault.testament.beneficiaries[i].address_ == address_) {
        dynamicVault.testament.beneficiaries[i].inheritancePercentage = newInheritancePercentage;
      }
    }

    emit BeneficiaryPercentageUpdated(dynamicVaultId, address_, newInheritancePercentage);
  }

  // VIEW METHODS

  /**
   * @notice Returns the creationParameters of a given dynamic vault id
   * @param dynamicVaultId The id of the dynamic vault
   * @return owner The owner of the dynamic vault
   * @return claimant The claimant of the dynamic vault
   * @return backupAddresses The backup addresses
   * @return tokens The approved tokens
   * @return inactivityMaximum The maximum inactivity time
   * @return proofOfLife The last registred proof of life timestamp
   * @return succeeded Whether the dynamic vault has been succeeded
   */
  function getTestamentCreationParameters(uint256 dynamicVaultId)
    external
    view
    returns (
      address owner,
      address claimant,
      address[] memory backupAddresses,
      address[] memory tokens,
      uint128 inactivityMaximum,
      uint128 proofOfLife,
      bool succeeded
    )
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    return (
      dynamicVault.testament.creationParameters.owner,
      dynamicVault.testament.creationParameters.claimant,
      dynamicVault.backupAddresses,
      dynamicVault.testament.tokens,
      dynamicVault.testament.creationParameters.inactivityMaximum,
      dynamicVault.testament.creationParameters.proofOfLife,
      dynamicVault.testament.creationParameters.succeeded
    );
  }

  /**
   * @notice Returns the beneficiaries of a given dynamic vault id
   * @param dynamicVaultId The id of the dynamic vault
   * @return tokens Approved tokens
   * @return beneficiariesNames Beneficiaries names
   * @return beneficiariesAddresses Beneficiaries addresses
   * @return beneficiariesInheritancePercentages Beneficiaries inheritance percentages
   */
  function getTestamentDynamicParameters(uint256 dynamicVaultId)
    external
    view
    returns (
      address[] memory tokens,
      string[] memory beneficiariesNames,
      address[] memory beneficiariesAddresses,
      uint256[] memory beneficiariesInheritancePercentages
    )
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    beneficiariesNames = new string[](dynamicVault.testament.beneficiaries.length);
    beneficiariesAddresses = new address[](dynamicVault.testament.beneficiaries.length);
    beneficiariesInheritancePercentages = new uint256[](dynamicVault.testament.beneficiaries.length);

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      beneficiariesNames[i] = dynamicVault.testament.beneficiaries[i].name;
      beneficiariesAddresses[i] = dynamicVault.testament.beneficiaries[i].address_;
      beneficiariesInheritancePercentages[i] = dynamicVault.testament.beneficiaries[i].inheritancePercentage;
    }

    return (
      dynamicVault.testament.tokens,
      beneficiariesNames,
      beneficiariesAddresses,
      beneficiariesInheritancePercentages
    );
  }
}
