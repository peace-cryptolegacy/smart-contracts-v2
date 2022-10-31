import {MockContract} from '@ethereum-waffle/mock-contract';
import {BigNumber} from 'ethers';
import {deployments} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - addToken', function () {
  let DynamicVaults: DynamicVaults;
  let dynamicVaultId: BigNumber;
  let exploiter: User;
  let testToken: MockContract;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, usedDynamicVaultId, testExploiter} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    dynamicVaultId = usedDynamicVaultId;
    exploiter = testExploiter;

    testToken = mocks.TestToken;
  });

  it('Calling repossessAccount from an account other than a backup address should revert', async () => {
    await expect(
      exploiter.DynamicVaults.addToken(dynamicVaultId, testToken.address)
    ).to.be.revertedWith('T_UNAUTHORIZED');
  });
});
