import {MockContract} from '@ethereum-waffle/mock-contract';
import {deployments} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - repossessAccount', function () {
  let DynamicVaults: DynamicVaults;
  let owner: string;
  let exploiter: User;
  let testToken: MockContract;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, testDynamicVaultOwner, testExploiter} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    owner = testDynamicVaultOwner.address;
    exploiter = testExploiter;

    testToken = mocks.TestToken;
  });

  it('Calling repossessAccount from an account other than a backup address should revert', async () => {
    await expect(
      exploiter.DynamicVaults.repossessAccount(owner)
    ).to.be.revertedWith('T_UNAUTHORIZED');
  });
});
