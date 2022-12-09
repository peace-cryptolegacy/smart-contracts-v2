// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./lib/Errors.sol";
import "./lib/Types.sol";
import "./lib/Uint128WadRayMath.sol";
import "./lib/Scaling.sol";

import "./interfaces/IDynamicVaults.sol";

import "hardhat/console.sol";

/**
 * @title DynamicVaults
 * @author Peace Foundation
 * @notice Dyanmic vaults contract that allows for the transfer of tokens in case of emergency
 */

contract DynamicVaults is IDynamicVaults, OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20 for ERC20;
  using Scaling for uint128;
  using Uint128WadRayMath for uint128;

  uint128 internal establishmentFeeRate;

  // An address can only have one dynamic vault
  mapping(address => Types.DynamicVault) public dynamicVaults;

  modifier onlyOnTranscendence(Types.DynamicVault storage dynamicVault) {
    if (block.timestamp < dynamicVault.testament.proofOfLife + dynamicVault.testament.inactivityMaximum) {
      revert Errors.T_NO_TRANSCENDENCE();
    }
    _;
  }

  modifier onlyUnsucceeded(Types.DynamicVault storage dynamicVault) {
    if (dynamicVault.testament.succeeded) {
      revert Errors.T_SUCCEEDED();
    }
    _;
  }

  modifier onlyBeneficiary(Types.DynamicVault storage dynamicVault) {
    bool authorized;
    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      if (dynamicVault.testament.beneficiaries[i].address_ == msg.sender) {
        authorized = true;
        break;
      }
    }

    if (!authorized) {
      revert Errors.T_UNAUTHORIZED();
    }
    _;
  }

  modifier onlyActive(Types.DynamicVault storage dynamicVault) {
    if (dynamicVault.testament.status != Types.TestamentStatus.ACTIVE) {
      revert Errors.T_CANCELED();
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

  function initialize(uint128 establishmentFeeRate_) public initializer {
    establishmentFeeRate = establishmentFeeRate_;
    __Ownable_init();
    // The initializer below does't do anything. It is just called to comply with OpenZeppelin's recommendations
    __Pausable_init_unchained();
  }

  /**
   * @notice Creates a dynamic vault
   * @param inactivityMaximum The maximum inactivity time
   * @param beneficiaries The beneficiaries that will inherit the vault
   * @dev The beneficiaries percentages should be with an 18 decimals precision to allow for percentages with decimals
   * @dev The beneficiaries percentages should add up to 100%
   */
  function createTestament(uint128 inactivityMaximum, Types.Beneficiary[] memory beneficiaries) external {
    if (dynamicVaults[msg.sender].testament.status == Types.TestamentStatus.ACTIVE) {
      revert Errors.T_TESTAMENT_ALREADY_EXISTS();
    }

    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    dynamicVault.testament.status = Types.TestamentStatus.ACTIVE;

    dynamicVault.testament.inactivityMaximum = inactivityMaximum;
    dynamicVault.testament.proofOfLife = uint128(block.timestamp);

    dynamicVault.ESTABLISHMENT_FEE_RATE = establishmentFeeRate;

    for (uint256 i = 0; i < beneficiaries.length; i++) {
      if (beneficiaries[i].address_ == address(0)) {
        revert Errors.T_ADDRESS_ZERO();
      }
      dynamicVault.testament.beneficiaries.push(beneficiaries[i]);
    }
  }

  /**
   * @notice Adds a token to thedynamicVault 
   * @param token The token to be added to the protected tokens list
   * @dev there is no function to remove a token since that can be done by decreasing the allowance of this contract. Doing
   otherwise would be expensive and unnecessary
  */
  function addToken(address token) external {
    dynamicVaults[msg.sender].testament.tokens.push(token);

    emit TokenAdded(msg.sender, token);
  }

  /**
   * @notice Adds beneficiary to thedynamicVault
   * @param beneficiary The beneficiary to add
   * @dev The addeed percentage of the beneficiaries should not exceed 100%
   * @dev The total maximum percentage should be 100%
   */
  function addBeneficiary(Types.Beneficiary memory beneficiary) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    uint256 percentage;
    percentage += beneficiary.inheritancePercentage;

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      percentage += dynamicVault.testament.beneficiaries[i].inheritancePercentage;
    }

    if (percentage > 100) {
      revert Errors.T_INHERITANCE_PERCENTAGE_EXCEEDED();
    }

    dynamicVault.testament.beneficiaries.push(beneficiary);

    emit BeneficiaryAdded(msg.sender, beneficiary.address_);
  }

  /**
   * @notice Removes beneficiary from the vault
   * @param address_ The beneficiary to remove
   */
  function removeBeneficiary(address address_) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    for (uint256 i = 0; i < dynamicVault.testament.beneficiaries.length; i++) {
      if (dynamicVault.testament.beneficiaries[i].address_ == address_) {
        dynamicVault.testament.beneficiaries[i] = dynamicVault.testament.beneficiaries[
          dynamicVault.testament.beneficiaries.length - 1
        ];
        dynamicVault.testament.beneficiaries.pop();
      }
    }

    emit BeneficiaryRemoved(msg.sender, address_);
  }

  /**
    @notice Updates the inactivity time of thedynamicVault 
    @param newInactivityMaximum The new inactivity time
  */
  function updateInactivityMaximum(uint128 newInactivityMaximum) external {
    dynamicVaults[msg.sender].testament.inactivityMaximum = newInactivityMaximum;
  }

  /**
   * @notice Updates the proof of life timestamp
   */
  function signalLife() external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    uint128 timestampRef = uint128(block.timestamp);

    dynamicVault.testament.proofOfLife = timestampRef;

    emit ProofOfLifeUpdated(msg.sender, timestampRef);
  }

  /**
   * @notice Transfers the tokens to the beneficiaries
   * @param owner The owner of the dynamic vault
   * @dev The function can only be called after the inactivity period is over
   */
  function succeed(
    address owner
  )
    external
    onlyBeneficiary(dynamicVaults[owner])
    onlyOnTranscendence(dynamicVaults[owner])
    onlyUnsucceeded(dynamicVaults[owner])
    onlyActive(dynamicVaults[owner])
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[owner];

    dynamicVault.testament.succeeded = true;

    for (uint256 i = 0; i < dynamicVault.testament.tokens.length; i++) {
      ERC20 token = ERC20(dynamicVault.testament.tokens[i]);
      uint128 amount = uint128(token.allowance(owner, address(this)));

      if (token.balanceOf(owner) < amount) {
        amount = uint128(token.balanceOf(owner));
      }

      uint8 tokenDecimals = token.decimals();
      uint128 normalizedAmount = amount.scaleToWad(tokenDecimals);

      for (uint256 n = 0; n < dynamicVault.testament.beneficiaries.length; n++) {
        uint128 transferAmount = (
          normalizedAmount.wadMul(dynamicVault.testament.beneficiaries[n].inheritancePercentage)
        ).wadDiv(uint128(100 * 1e18));
        token.safeTransferFrom(
          owner,
          dynamicVault.testament.beneficiaries[n].address_,
          transferAmount.scaleFromWad(tokenDecimals)
        );
      }
    }

    emit TestamentSucceeded(owner);
  }

  /**
   * @notice Transfers the protected tokens to the backup address
   * @param owner The owner of the dynamic vault
   */
  function repossessAccount(address owner) external onlyBackup(dynamicVaults[owner]) {
    Types.DynamicVault storage dynamicVault = dynamicVaults[owner];
    for (uint256 i = 0; i < dynamicVault.testament.tokens.length; i++) {
      ERC20 token = ERC20(dynamicVault.testament.tokens[i]);
      uint256 allowedBalance = token.allowance(owner, address(this));
      token.safeTransferFrom(owner, msg.sender, allowedBalance);
    }

    emit accountRepossessed(owner, msg.sender);
  }

  /**
   * @notice Adds backup address
   * @param backupAddress The address to add
   */
  function addBackup(address backupAddress) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

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

    emit BackupAdded(msg.sender, backupAddress);
  }

  /**
   * @notice Removes backup address
   * @param backupAddress The address to remove
   */
  function removeBackup(address backupAddress) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    for (uint256 i = 0; i < dynamicVault.backupAddresses.length; i++) {
      if (dynamicVault.backupAddresses[i] == backupAddress) {
        dynamicVault.backupAddresses[i] = dynamicVault.backupAddresses[dynamicVault.backupAddresses.length - 1];
        dynamicVault.backupAddresses.pop();
      }
    }
  }

  /**
   * @notice Updates the inheritance percentage of a beneficiary
   * @param names The names of the beneficiaries
   * @param addresses The addresses of the beneficiary
   * @param newInheritancePercentages The new inheritance percentages
   * @param indexes The indexes to modify
   */
  function updateBeneficiaries(
    string[] memory names,
    address[] calldata addresses,
    uint128[] calldata newInheritancePercentages,
    uint128[] calldata indexes
  ) external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    for (uint256 j = 0; j < addresses.length; j++) {
      if (addresses[j] == address(0)) {
        revert Errors.T_ADDRESS_ZERO();
      }
      if (dynamicVault.testament.beneficiaries.length - 1 < indexes[j]) {
        dynamicVault.testament.beneficiaries.push(
          Types.Beneficiary({
            name: names[j],
            address_: payable(addresses[j]),
            inheritancePercentage: newInheritancePercentages[j]
          })
        );
      } else {
        dynamicVault.testament.beneficiaries[j].name = names[j];
        dynamicVault.testament.beneficiaries[j].address_ = payable(addresses[j]);
        dynamicVault.testament.beneficiaries[j].inheritancePercentage = uint128(newInheritancePercentages[j]);
      }
    }

    emit BeneficiariesUpdated(msg.sender, dynamicVault.testament.beneficiaries);
  }

  /**
   * @notice Cancels the testament
   */
  function cancelTestament() external {
    Types.DynamicVault storage dynamicVault = dynamicVaults[msg.sender];

    dynamicVault.testament.status = Types.TestamentStatus.CANCELED;

    emit TestamentCanceled(msg.sender);
  }

  // Methods callable only by the owner of the contract

  /**
   * @notice Sets the global establishment fee rate
   **/
  function updateEstablishmentFeeRate(uint128 newEstablishmentFeeRate) external onlyOwner {
    establishmentFeeRate = newEstablishmentFeeRate;

    emit EstablishmentFeeRateUpdated(newEstablishmentFeeRate);
  }

  /**
   * @notice Stops all actions on all vaults
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause vaults. Makes actions available again on all vaults
   **/
  function unpause() external onlyOwner {
    _unpause();
  }

  // VIEW METHODS

  /**
   * @notice Returns the testament parameters of a given dynamic vault id
   * @param owner The owner of the dynamic vault
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
      address[] memory tokens,
      uint128 inactivityMaximum,
      uint128 proofOfLife,
      bool succeeded,
      string[] memory beneficiariesNames,
      address[] memory beneficiariesAddresses,
      uint256[] memory beneficiariesInheritancePercentages
    )
  {
    Types.DynamicVault storage dynamicVault = dynamicVaults[owner];

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
      dynamicVault.testament.inactivityMaximum,
      dynamicVault.testament.proofOfLife,
      dynamicVault.testament.succeeded,
      beneficiariesNames,
      beneficiariesAddresses,
      beneficiariesInheritancePercentages
    );
  }

  /**
   * @notice Returns the backup addresses of a given dynamic vault id
   * @param owner The owner of the dynamic vault
   * @return backupAddresses The backup addresses
   */
  function getBackupAddresses(address owner) external view returns (address[] memory) {
    Types.DynamicVault storage dynamicVault = dynamicVaults[owner];
    return dynamicVault.backupAddresses;
  }
}
