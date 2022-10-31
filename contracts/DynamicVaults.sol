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

  modifier onlyOnTranscendance(Types.DynamicVault storage dynamicVault) {
    if (block.timestamp < dynamicVault.parameters.proofOfLife + dynamicVault.parameters.inactivityMaximum) {
      revert Errors.T_NO_TRANSCENDANCE();
    }
    _;
  }

  modifier onlyUnsucceeded(Types.DynamicVault storage dynamicVault) {
    if (dynamicVault.parameters.succeeded) {
      revert Errors.T_SUCCEEDED();
    }
    _;
  }

  modifier onlyowner(Types.DynamicVault storage dynamicVault) {
    if (msg.sender != dynamicVault.parameters.owner) {
      revert Errors.T_UNAUTHORIZED();
    }
    _;
  }

  modifier onlyClaimant(Types.DynamicVault storage dynamicVault) {
    if (msg.sender != dynamicVault.parameters.claimant) {
      revert Errors.T_UNAUTHORIZED();
    }
    _;
  }

  modifier onlyBackup(Types.DynamicVault storage dynamicVault) {
    for (uint256 i = 0; i < dynamicVault.parameters.backupAddresses.length; i++) {
      bool authorized;
      if (dynamicVault.parameters.backupAddresses[i] == msg.sender) {
        authorized = true;
      }
      if (!authorized) {
        revert Errors.T_UNAUTHORIZED();
      }
      _;
    }
  }

  /**
   * @notice Creates a dynamic vault
   * @param dynamicVaultId The dynamic vault id
   * @param inactivityMaximum The maximum inactivity time
   * @param tokens Array of tokens to be transferred in case of emergency
   * @param beneficiaries The beneficiaries that will inherit the vault
   * @param backupAddresses The backup addresses
   */
  function createDynamicVault(
    uint256 dynamicVaultId,
    address claimant,
    uint128 inactivityMaximum,
    address[] memory tokens,
    Types.Beneficiary[] memory beneficiaries,
    address[] memory backupAddresses
  ) external returns (uint256) {
    if (dynamicVaults[dynamicVaultId].parameters.owner != address(0)) {
      revert Errors.T_DYNAMIC_VAULT_ALREADY_EXISTS();
    }

    dynamicVaults[dynamicVaultId].parameters = Types.Parameters({
      owner: msg.sender,
      claimant: claimant,
      inactivityMaximum: inactivityMaximum,
      proofOfLife: uint128(block.timestamp),
      backupAddresses: backupAddresses,
      tokens: tokens,
      succeeded: false
    });

    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.beneficiaries.length; i++) {
      dynamicVault.beneficiaries[i] = beneficiaries[i];
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
  function addToken(uint256 dynamicVaultId, address token) external onlyowner(dynamicVaults[dynamicVaultId]) {
    dynamicVaults[dynamicVaultId].parameters.tokens.push(token);

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

    for (uint256 i = 0; i < dynamicVault.beneficiaries.length; i++) {
      percentage += dynamicVault.beneficiaries[i].inheritancePercentage;
    }

    if (percentage > 100) {
      revert Errors.T_INHERITANCE_PERCENTAGE_EXCEEDED();
    }

    dynamicVault.beneficiaries.push(beneficiary);

    emit BeneficiaryAdded(dynamicVaultId, beneficiary.address_);
  }

  /**
   * @notice Removes beneficiary from the vault
   * @param dynamicVaultId The id of thedynamicVault
   * @param address_ The beneficiary to remove
   */
  function removeBeneficiary(uint256 dynamicVaultId, address address_) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.beneficiaries.length; i++) {
      if (dynamicVault.beneficiaries[i].address_ == address_) {
        dynamicVault.beneficiaries[i] = dynamicVault.beneficiaries[dynamicVault.beneficiaries.length - 1];
        dynamicVault.beneficiaries.pop();
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
    onlyowner(dynamicVaults[dynamicVaultId])
  {
    dynamicVaults[dynamicVaultId].parameters.inactivityMaximum = newInactivityMaximum;
  }

  /**
   * @notice Updates the proof of life timestamp
   * @param dynamicVaultId The id of thedynamicVault
   */
  function signalLife(uint256 dynamicVaultId) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    uint128 timestampRef = uint128(block.timestamp);

    dynamicVault.parameters.proofOfLife = timestampRef;

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
    onlyOnTranscendance(dynamicVaults[dynamicVaultId])
    onlyUnsucceeded(dynamicVaults[dynamicVaultId])
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.parameters.tokens.length; i++) {
      IERC20 token = IERC20(dynamicVault.parameters.tokens[i]);
      uint256 allowedBalance = token.allowance(dynamicVault.parameters.owner, address(this));

      dynamicVault.parameters.succeeded = true;

      for (uint256 n = 0; n < dynamicVault.beneficiaries.length; n++) {
        uint256 amount = (allowedBalance * dynamicVault.beneficiaries[n].inheritancePercentage) / 100;
        token.safeTransferFrom(dynamicVault.parameters.owner, dynamicVault.beneficiaries[n].address_, amount);
      }
    }

    emit TestamentSucceeded(dynamicVaultId);
  }

  /**
   * @notice Transfers the protected tokens to the backup address
   * @param dynamicVaultId The id of thedynamicVault
   * @param backupAddress The authorized address to which the protected tokens will be transfered
   */
  function repossessAccount(uint256 dynamicVaultId, address backupAddress)
    external
    onlyBackup(dynamicVaults[dynamicVaultId])
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];
    for (uint256 i = 0; i < dynamicVault.parameters.tokens.length; i++) {
      IERC20 token = IERC20(dynamicVault.parameters.tokens[i]);
      uint256 allowedBalance = token.allowance(dynamicVault.parameters.owner, address(this));
      token.safeTransferFrom(dynamicVault.parameters.owner, backupAddress, allowedBalance);
    }

    emit accountRepossessed(dynamicVaultId, backupAddress);
  }

  /**
   * @notice Adds backup address
   * @param dynamicVaultId The id of thedynamicVault
   * @param backupAddress The address to add
   */
  function addBackup(uint256 dynamicVaultId, address backupAddress) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    if (backupAddress == address(0)) {
      revert Errors.T_ADDRESS_ZERO();
    }
    dynamicVault.parameters.backupAddresses.push(backupAddress);
  }

  /**
   * @notice Removes backup address
   * @param dynamicVaultId The id of thedynamicVault
   * @param backupAddress The address to remove
   */
  function removeBackup(uint256 dynamicVaultId, address backupAddress) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    for (uint256 i = 0; i < dynamicVault.parameters.backupAddresses.length; i++) {
      if (dynamicVault.parameters.backupAddresses[i] == backupAddress) {
        dynamicVault.parameters.backupAddresses[i] = dynamicVault.parameters.backupAddresses[
          dynamicVault.parameters.backupAddresses.length - 1
        ];
        dynamicVault.parameters.backupAddresses.pop();
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

    for (uint256 i = 0; i < dynamicVault.beneficiaries.length; i++) {
      if (dynamicVault.beneficiaries[i].address_ == address_) {
        dynamicVault.beneficiaries[i].inheritancePercentage = newInheritancePercentage;
      }
    }

    emit BeneficiaryPercentageUpdated(dynamicVaultId, address_, newInheritancePercentage);
  }

  // VIEW METHODS

  /**
    * @notice Returns the parameters of a given dynamic vault id 
    * @param dynamicVaultId The id of the dynamic vault
    * @return owner The owner of the dynamic vault
    * @return claimant The claimant of the dynamic vault
    * @return backupAddresses The backup addresses 
    * @return tokens The approved tokens 
    * @return inactivityMaximum The maximum inactivity time
    * @return proofOfLife The last registred proof of life timestamp
    * @return succeeded Whether the dynamic vault has been succeeded 
   */
  function getDynamicVaultParameters(uint256 dynamicVaultId)
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
      dynamicVault.parameters.owner,
      dynamicVault.parameters.claimant,
      dynamicVault.parameters.backupAddresses,
      dynamicVault.parameters.tokens,
      dynamicVault.parameters.inactivityMaximum,
      dynamicVault.parameters.proofOfLife,
      dynamicVault.parameters.succeeded
    );
  }

  /**
    * @notice Returns the beneficiaries of a given dynamic vault id 
    * @param dynamicVaultId The id of the dynamic vault
    * @return names
    * @return addresses_ The beneficiary addresses
   */
  function getDynamicVaultBeneficiaries(uint256 dynamicVaultId)
    external
    view
    returns (string[] memory names, address[] memory addresses_, uint256[] memory inheritancePercentages)
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[dynamicVaultId];

    names = new string[](dynamicVault.beneficiaries.length);
    addresses_ = new address[](dynamicVault.beneficiaries.length);
    inheritancePercentages = new uint256[](dynamicVault.beneficiaries.length);

    for (uint256 i = 0; i < dynamicVault.beneficiaries.length; i++) {
      names[i] = dynamicVault.beneficiaries[i].name;
      addresses_[i] = dynamicVault.beneficiaries[i].address_;
      inheritancePercentages[i] = dynamicVault.beneficiaries[i].inheritancePercentage;
    }
  }
}
