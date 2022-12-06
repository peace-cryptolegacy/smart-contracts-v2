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
  let owner: string;
  let beneficiary1: User;
  const [newClaimant, newInactivityMaximum, newBeneficiaries] =
    TESTAMENT_CREATION_PARAMS;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, testDynamicVaultOwner, testBeneficiary1} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    owner = testDynamicVaultOwner.address;
    beneficiary1 = testBeneficiary1;
  });

  it('Creating a testament where the claimer is the address zero should revert', async () => {
    await expect(
      DynamicVaults.createTestament(
        newClaimant,
        newInactivityMaximum,
        newBeneficiaries
      )
    ).to.be.revertedWith('T_ADDRESS_ZERO');
  });
});
