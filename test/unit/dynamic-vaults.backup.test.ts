import {BigNumber} from 'ethers';
import {deployments, ethers} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - backup', function () {
  let DynamicVaults: DynamicVaults;
  let dynamicVaultId: BigNumber;
  let dynamicVaultOwner: User, beneficiary1: User, user1: User;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {
      deployedDynamicVaults,
      usedDynamicVaultId,
      testDynamicVaultOwner,
      testBeneficiary1,
      testUser1,
    } = await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    dynamicVaultId = usedDynamicVaultId;
    dynamicVaultOwner = testDynamicVaultOwner;
    beneficiary1 = testBeneficiary1;
    user1 = testUser1;
  });

  it('Adding a backup as someone other than the owner should revert', async () => {
    await expect(
      DynamicVaults.addBackup(dynamicVaultId, user1.address)
    ).to.be.revertedWith('T_UNAUTHORIZED');
  });

  it('Adding the zero address as a backup should revert', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.addBackup(
        dynamicVaultId,
        ethers.constants.AddressZero
      )
    ).to.be.revertedWith('T_ADDRESS_ZERO');
  });

  it('Adding yourself as the backup address should revert', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.addBackup(
        dynamicVaultId,
        dynamicVaultOwner.address
      )
    ).to.be.revertedWith('T_BACKUP_ADDRESS_IS_OWNER');
  });
});
