import {deployments, ethers} from 'hardhat';
import {DynamicVaults} from '../../typechain';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {INACTIVITY_MAXIMUM} from '../utils/constants';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - cancel', function () {
  let DynamicVaults: DynamicVaults;
  let governance: User, dynamicVaultOwner: User, beneficiary1: User;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {
      deployedDynamicVaults,
      testDynamicVaultOwner,
      testExploiter,
      testGovernance,
      testBeneficiary1,
    } = await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    governance = testGovernance;
    dynamicVaultOwner = testDynamicVaultOwner;
    beneficiary1 = testBeneficiary1;
  });

  it('Canceling a testament should work', async () => {
    await expect(dynamicVaultOwner.DynamicVaults.cancelTestament()).to.emit(
      dynamicVaultOwner.DynamicVaults,
      'TestamentCanceled'
    );
  });

  it('Trying to succeed a testament that was canceled should revert', async () => {
    await expect(dynamicVaultOwner.DynamicVaults.cancelTestament()).to.emit(
      dynamicVaultOwner.DynamicVaults,
      'TestamentCanceled'
    );

    await ethers.provider.send('evm_increaseTime', [
      INACTIVITY_MAXIMUM.toNumber(),
    ]);

    await ethers.provider.send('evm_mine', []);

    await expect(
      beneficiary1.DynamicVaults.succeed(dynamicVaultOwner.address)
    ).to.be.revertedWith('T_CANCELED');
  });
});
