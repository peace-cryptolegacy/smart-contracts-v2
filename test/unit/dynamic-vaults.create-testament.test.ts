import {deployments} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {TESTAMENT_CREATION_PARAMS} from '../utils/constants';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - createTestament', function () {
  let DynamicVaults: DynamicVaults;
  let dynamicVaultOwner: User, beneficiary1: User;
  const [newClaimant, newInactivityMaximum, newBeneficiaries] =
    TESTAMENT_CREATION_PARAMS;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, testDynamicVaultOwner, testBeneficiary1} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    dynamicVaultOwner = testDynamicVaultOwner;
    beneficiary1 = testBeneficiary1;
  });

  it('Creating 2 testaments for the same address should revert', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.createTestament(
        newInactivityMaximum,
        newBeneficiaries
      )
    ).to.be.revertedWith('T_TESTAMENT_ALREADY_EXISTS');
  });
});
